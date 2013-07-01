package WebService::Zaim;

use utf8;
use strict;
use warnings;

use OAuth::Lite::Consumer;
use OAuth::Lite::Token;
use HTTP::Request::Common;
use Encode;
use JSON;
use URI;

sub new {
	my ($class, %args) = @_;

	# Zaim does not support oob...
	$args{callback_url} ||= 'http://oob/';
	$args{lang} ||= 'ja';

	bless { %args }, $class;
}

sub oauth {
	my ($self) = @_;
	$self->{oauth} ||= OAuth::Lite::Consumer->new(
		realm => 'Test',
		consumer_key          => $self->{consumer_key},
		consumer_secret       => $self->{consumer_secret},
		site                  => q{https://api.zaim.net},
		request_token_path    => q{https://api.zaim.net/v1/auth/request},
		access_token_path     => q{https://api.zaim.net/v1/auth/access},
		authorize_path        => q{https://www.zaim.net/users/auth},
	);
}

sub login {
	my ($self, $callback) = @_;
	if ($self->oauth->access_token) {
		return;
	}

	$callback ||= sub {
		my $uri = shift;
		printf "Access to authorization: %s\n", $uri;
		printf "Input verifier code: ";
		my $code = <>;
		chomp $code;
		$code;
	};

	my $consumer = $self->oauth;
	my $request_token = $consumer->get_request_token(callback_url => $self->{callback_url});

	my $url = $consumer->url_to_authorize(
		token => $request_token,
	);

	my $verifier = $callback->($url);

	my $access_token = $consumer->get_access_token(
		token    => $request_token,
		verifier => $verifier,
	) or die $consumer->errstr;

	$self->{access_token} = $access_token;
}

sub get {
	my ($self, $uri, $params) = @_;

	my $res = $self->oauth->request(
		method => 'GET',
		url    => $uri,
		params => $params,
	);
	if ($res->is_success) {
		decode_json($res->decoded_content);
	} else {
		undef;
	}
}

sub post {
	my ($self, $uri, $params) = @_;

	my $res = $self->oauth->request(
		method => 'POST',
		url    => $uri,
		params => $params,
	);
	if ($res->is_success) {
		decode_json($res->decoded_content);
	} else {
		use Data::Dumper;
		warn Dumper $res ;
		undef;
	}
}

sub put {
	my ($self, @args) = @_;

	my $res = $self->oauth->put(@args);
	if ($res->is_success) {
		decode_json($res->decoded_content);
	} else {
		undef;
	}
}

sub delete {
	my ($self, @args) = @_;

	my $res = $self->oauth->delete(@args);
	if ($res->is_success) {
		decode_json($res->decoded_content);
	} else {
		undef;
	}
}

sub categories {
	my ($self) = @_;
	$self->{categories} //= do {
		$self->get('https://api.zaim.net/v2/home/category')->{categories};
	};
}

sub category_by_name {
	my ($self, $mode, $name) = @_;
	for my $category (@{ $self->categories }) {
		return $category if $category->{name} eq $name && $category->{mode} eq $mode;
	}
}

sub genres {
	my ($self) = @_;
	$self->{genres} //= do {
		$self->get('https://api.zaim.net/v2/home/genre')->{genres};
	};
}

sub genre_by_name {
	my ($self, $mode, $category_name, $genre_name) = @_;
	my $category = $self->category_by_name($mode, $category_name);
	for my $genre (@{ $self->genres }) {
		return $genre if $genre->{category_id} == $category->{id} && $genre->{name} eq $genre_name;
	}
}

sub accounts {
	my ($self) = @_;
	$self->{accounts} //= do {
		$self->get('https://api.zaim.net/v2/home/account', { lang => $self->{lang} })->{accounts};
	};
}

sub account_by_name {
	my ($self, $name) = @_;
	for my $account (@{ $self->accounts }) {
		return $account if $account->{name} eq $name;
	}
}

sub data {
	my ($self, %args) = @_;
	my $uri = URI->new('https://api.zaim.net/v2/home/money');
	$self->get($uri, \%args);
}

sub payment {
	my ($self, %args) = @_;

	if (my $category = delete $args{category}) {
		if (my $genre = delete $args{genre}) {
			my $info = $self->genre_by_name(payment => $category, $genre);
			$args{category_id} = $info->{category_id};
			$args{genre_id}    = $info->{id};
		} else {
			$args{category_id} = $self->category_by_name($category)->{id};
		}
	}

	if (my $account = delete $args{from_account}) {
		$args{from_account_id} = $self->account_by_name($account)->{id};
	}

	$self->post('https://api.zaim.net/v2/home/money/payment', {
		category_id     => $args{category_id},
		genre_id        => $args{genre_id},
		amount          => $args{amount},
		date            => $args{date},
		from_account_id => $args{from_account_id},
		comment         => encode_utf8($args{comment} || ''),
		name            => encode_utf8($args{name} || ''),
		place           => encode_utf8($args{place} || ''),
	});
}

sub dump {
	my ($self) = @_;
	$self->oauth->access_token->as_encoded;
}

sub load {
	my ($self, $dump) = @_;
	$self->oauth->access_token(OAuth::Lite::Token->from_encoded($dump));
}

1;
