#!/bin/env perl

use FindBin;

use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/vendor';

use action::std;

use action::cli;

$| = 1;

exit( action::cli::start(@ARGV) // 0 ) unless caller;

1;
