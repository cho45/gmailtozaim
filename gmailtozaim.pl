#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib lib => glob 'modules/*/lib';
use Data::Dumper;
use DateTime;

use App::gmailtozaim;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $app = App::gmailtozaim->new;
$app->parse_options(@ARGV);
$app->run;

#for my $t (@{ $app->zaim->data->{money} }) {
#	$app->zaim->delete('https://api.zaim.net/v2/home/money/payment/' . $t->{id});
#}

