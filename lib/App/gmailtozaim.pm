package App::gmailtozaim;

use utf8;
use strict;
use warnings;
use WebService::Zaim;
use Net::IMAP::Client::Gmail;

use Encode::BaseN; # cpanm https://github.com/cho45/Encode-BaseN/archive/master.zip
use DateTime;
use Encode;
use JSON;
use Path::Class;
use Log::Minimal;
use Getopt::Long;

use App::gmailtozaim::config;

use constant GOOGLE_CLIENT_ID => '889795001996.apps.googleusercontent.com';
use constant GOOGLE_CLIENT_SECRET => 'h3Bi1DVRY9ggYP1BnP0ywwAF';
use constant ZAIM_CLIENT_ID => 'd2583601a5b32492b86856712a62cec41f50381a';
use constant ZAIM_CLIENT_SECRET => 'e94229a406bd6eae0cf95791750db8d8e9fff57c';

my $encoder;

sub encoder {
	my ($class) = @_;
	$encoder ||= Encode::BaseN->new(
		chars => [ map { chr($_) } (0x2800 .. 0x28ff) ],
	);
}

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		config_file => file(config->param('file'))->absolute,
		argv => [],
		days => 7,
		%args,
	}, $class;
	$self->load;
	$self;
}

sub load {
	my ($self) = @_;
	if (-e $self->{config_file}) {
		infof('Load config from %s', $self->{config_file});
		$self->{config} = decode_json($self->{config_file}->slurp);
	} else {
		$self->{config} = {};
	}
	$self;
}

sub save {
	my ($self) = @_;
	my $fh = $self->{config_file}->openw;
	print $fh JSON->new->pretty->encode($self->{config});
	close $fh;
}

sub run {
	my ($self) = @_;
	if (!ref($self)) {
		return $self->new->parse_options(@ARGV)->run;
	}

	# ensure to login
	$self->zaim;
	$self->gmail;

	my $rakuten = $self->retrieve_rakutencard_data_from_gmail;
	for my $data (@$rakuten) {
		my ($category, $genre) = @{ $self->guess_payment_genre($data->{abstract}) };
		$self->book_in_to_zaim(
			key          => $self->encoder->encode($data->{uid}),
			category     => $category,
			genre        => $genre,
			amount       => $data->{amount},
			date         => $data->{date},
			from_account => 'クレジットカード',
			# なぜか {"error":true,"message":"This consumer key does not have a permission for the action.","extra_message":null}
			# place        => $data->{abstract},
			comment      => $data->{abstract},
		);
	}
}

sub parse_options {
	my ($self) = @_;
	local @ARGV = @{ $self->{argv} };
	push @ARGV, @_;

	Getopt::Long::GetOptions(
		'd|days=i' => \$self->{days},
	);

	$self;
}

sub guess_payment_genre {
	my ($self, $string) = @_;

	my $guess = [ @{ config->param('payment_guess') }];

	while (my($k, $v) = splice @$guess, 0, 2) {
		if ($string =~ $k) {
			return $v;
		}
	}

	['その他', 'その他'];
}

sub gmail {
	my ($self) = @_;
	$self->{gmail} //= do {
		infof('Login to Gmail...');
		my $imap = Net::IMAP::Client::Gmail->new(
			oauth => {
				client_id     => GOOGLE_CLIENT_ID,
				client_secret => GOOGLE_CLIENT_SECRET,
				redirect_uri  => "urn:ietf:wg:oauth:2.0:oob",
				%{ $self->{config}->{gmail} || {} },
			},
		);

		$imap->login; $self->{config}->{gmail} = $imap->{oauth};
		$self->save;
		$imap->select('[Gmail]/All Mail');
		$imap;
	}
}

sub zaim {
	my ($self) = @_;
	$self->{zaim} //= do {
		infof('Login to Zaim...');
		my $zaim = WebService::Zaim->new(
			consumer_key    => ZAIM_CLIENT_ID,
			consumer_secret => ZAIM_CLIENT_SECRET,
		);

		$zaim->load($self->{config}->{zaim}) if $self->{config}->{zaim};
		$zaim->login; $self->{config}->{zaim} = $zaim->dump;
		$self->save;
		$zaim;
	};
}

sub retrieve_rakutencard_data_from_gmail {
	my ($self) = @_;
	my $ret = [];
	my $date = DateTime->now->add(days => -$self->{days})->ymd('/');
	infof('[retrieve_rakutencard_data_from_gmail] Searching Gmail from %s', $date);
	my $ids = $self->gmail->search_gmail(sprintf('subject:【売上情報】カード利用お知らせメール newer:%s', $date));
	if (@$ids) {
		infof('[retrieve_rakutencard_data_from_gmail] get_summaries with %d ids', scalar @$ids);
		my $msgs = $self->gmail->get_summaries($ids);

		for my $msg (@$msgs) {
			infof('[retrieve_rakutencard_data_from_gmail] get_rfc822_body id:%d (%s)', $msg->uid, $msg->date);
			my $body = decode 'iso-2022-jp', ${ $self->gmail->get_rfc822_body($msg->uid) };
			while ($body =~ m{
				.利用日:\s*([^\n]+?)\s*
				.利用先:\s*([^\n]+?)\s*
				.支払方法:\s*.+\s*
				.利用金額:\s*([\d,]+)\s*円\s*
				.支払月:\s*([^\n]+?)\s*
			}xg) {
				my $date = $1;
				my $abstract = $2;
				my $amount = $3;
				$date =~ s{/}{-}g;
				$amount =~ s{\D}{}g;
				push @$ret, {
					uid      => $msg->uid,
					date     => $date,
					abstract => $abstract,
					amount   => $amount,
				};
			}
		}
	}
	$ret;
}

sub book_in_to_zaim {
	my ($self, %args) = @_;

	# 指定した日付に、key で指定した文字列がある場合、処理を行わない
	if (my $key = delete $args{key}) {
		my $res = $self->zaim->data(start_date => $args{date}, end_date => $args{date}, limit => 100);
		for my $money (@{ $res->{money} }) {
			if ($money->{comment} =~ $key) {
				infof('[book_in_to_zaim] %s %d with key [%s] is skipped', $money->{date}, $money->{amount}, $key);
				return;
			}
		}
		my $append = " [$key]";
		$args{comment} = substr($args{comment}, 0, 100 - length($append)) . $append;
		infof('[book_in_to_zaim] %s, %d %s / %s / %s', $args{date}, $args{amount}, $args{comment} || '', $args{place} || '', $args{name} || '');
	}

	$self->zaim->payment(%args);
}

sub DESTROY {
	my ($self) = @_;
	$self->save;
}

1;
