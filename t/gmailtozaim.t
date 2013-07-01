use utf8;
use strict;
use warnings;

use Test::Base -Base;
use Test::More;
use App::gmailtozaim;

my $app = App::gmailtozaim->new;

is_deeply $app->guess_payment_genre('電力'), ['水道・光熱', '電気代'];


done_testing;
