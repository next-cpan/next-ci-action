#1perl

use 5.010000;

use strict;
use warnings;
use Test::More;

plan tests => 2;

use_ok('action')      || print "Bail out!\n";
use_ok('action::cli') || print "Bail out!\n";

diag("Testing action Perl $], $^X");

done_testing;
