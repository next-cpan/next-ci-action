#!perl

use FindBin;
use lib $FindBin::Bin . '/lib'; 

use action::std;

use action::cli;

=pod

simple shell script to automerge

https://github.com/lots0logs/gh-action-auto-merge/blob/master/entrypoint.sh

=cut

exit(action::cli::start( @ARGV ) // 0) unless caller;