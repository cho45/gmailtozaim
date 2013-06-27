package App::gmailtozaim::config;

use utf8;
use strict;
use warnings;
use Config::ENV 'APP_ENV', export => 'config';

common load('payment_guess.conf');

config default => {
	file => ".$0",
};

config run => {
	file => ".$0.run",
};

1;
