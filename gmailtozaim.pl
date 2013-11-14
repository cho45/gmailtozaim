#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Path::Class;
BEGIN { chdir file(__FILE__)->parent; }
use lib 'lib';
use Data::Dumper;
use DateTime;

use App::gmailtozaim;


binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $app = App::gmailtozaim->new;
$app->parse_options(@ARGV)->run;

