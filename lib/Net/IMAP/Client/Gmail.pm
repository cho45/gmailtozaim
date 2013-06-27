package Net::IMAP::Client::Gmail;

use strict;
use warnings;
use utf8;
use HTTP::Request::Common;
use LWP::UserAgent;
use LWP::Protocol::https;
use URI;
use JSON;
use MIME::Base64;
use Encode;
use Encode::IMAPUTF7;

my $encoding;
BEGIN { $encoding = find_encoding('IMAP-UTF-7') };

use parent qw(Net::IMAP::Client);

sub new {
	my ($class, %args) = @_;
	$args{server} //= 'imap.googlemail.com';
	$args{ssl} //= 1;
	$args{port} //= 993;
	my $self = $class->SUPER::new(%args);
	$self->{oauth} = $args{oauth};
	$self->{ua}    = $args{ua} || LWP::UserAgent->new;
	# $self->{oauth} = {
	#   client_id => '',
	#   client_secret => '',
	#   redirect_uri => 'urn:ietf:wg:oauth:2.0:oob',
	#   access_token => '',
	#   refresh_token => '',
	#   expire => '',
	# }
	$self;
}

sub login {
	my ($self, $callback) = @_;
	$self->oauth($callback);

	my $capability = $self->capability;

	my ($ok, $lines) = $self->_tell_imap('AUTHENTICATE', 'XOAUTH2 ' . $self->_sasl_xoauth2);

	if (!$ok) {
		my $base64 = join "\r\n", @{ $lines->[0] };
		$base64 =~ s/^\+ *//;
		die decode_json(decode_base64($base64));
	}

	$ok;
}

sub oauth {
	my ($self, $callback) = @_;
	$callback ||= sub {
		my $uri = shift;
		printf "Access to authorization: %s\n", $uri;
		printf "Input authorization code: ";
		my $code = <>;
		chomp $code;
		$code;
	};

	if ($self->_access_token) {
		return;
	}

	my $authorize_uri = URI->new('https://accounts.google.com/o/oauth2/auth');
	$authorize_uri->query_form(
		response_type => 'code',
		client_id     => $self->{oauth}->{client_id},
		redirect_uri  => $self->{oauth}->{redirect_uri},
		scope         => 'https://mail.google.com/ email',
	);

	my $code = $callback->($authorize_uri);

	my $token_uri = URI->new('https://accounts.google.com/o/oauth2/token');

	my $res = $self->{ua}->post($token_uri, {
		code          => $code,
		client_id     => $self->{oauth}->{client_id},
		client_secret => $self->{oauth}->{client_secret},
		redirect_uri  => $self->{oauth}->{redirect_uri},
		grant_type    => 'authorization_code',
	});

	my $data = decode_json $res->content;
	$data->{error} and die $data->{error};

	$self->{oauth}->{access_token}  = $data->{access_token};
	$self->{oauth}->{refresh_token} = $data->{refresh_token};
	$self->{oauth}->{expire}        = time + $data->{expires_in};

	my $info = $self->_request(GET 'https://www.googleapis.com/oauth2/v1/userinfo');

	$self->{oauth}->{email} = $info->{email};
}

sub _refresh {
	my ($self) = @_;

	my $token_uri = URI->new('https://accounts.google.com/o/oauth2/token');

	my $res = $self->{ua}->post($token_uri, {
		client_id     => $self->{oauth}->{client_id},
		client_secret => $self->{oauth}->{client_secret},
		refresh_token => $self->{oauth}->{refresh_token},
		grant_type    => 'refresh_token',
	});

	if ($res->is_success) {
		my $data = decode_json $res->content;
		$self->{oauth}->{access_token}  = $data->{access_token};
		$self->{oauth}->{expire}        = time + $data->{expires_in};
		1;
	} else {
		undef $self->{oauth}->{access_token};
		undef $self->{oauth}->{expire};
		0;
	}
}

sub _access_token {
	my ($self) = @_;
	if (time > ($self->{oauth}->{expire} || 0)) {
		$self->_refresh;
	}
	$self->{oauth}->{access_token};
}

sub _request {
	my ($self, $req) = @_;
	$req->header('Authorization' => 'Bearer ' . $self->_access_token);
	my $res = $self->{ua}->request($req);
	if ($res->is_success) {
		decode_json($res->content);
	} else {
		die $res->content;
	}
}

sub _sasl_xoauth2 {
	my ($self) = @_;

	my $raw = sprintf("user=%s\001auth=Bearer %s\001\001", $self->{oauth}->{email}, $self->_access_token);
	encode_base64($raw, '');
}

sub _select_or_examine {
	my ($self, $folder, $operation) = @_;
	$self->SUPER::_select_or_examine($encoding->encode($folder), $operation);
}

sub search_gmail {
	my ($self, $raw_search) = @_;

	my ($ok, $lines) =  $self->_tell_imap(SEARCH => [ 'CHARSET UTF-8 X-GM-RAW ', \encode_utf8($raw_search) ], 1) ;
	if ($ok) {
		my ($joined) = ($lines->[0]->[0] =~ m{^\*\s+(?:SEARCH|SORT)\s+(.+)\s*$});
		return $joined ? [ map { $_ + 0 } split(/\s+/, $joined) ] : [];
	} else {
		undef;
	}
}

1;
