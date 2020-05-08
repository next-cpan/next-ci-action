#!perl

use v5.30;

use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib $FindBin::Bin . '/lib'; 

sub run(@argv) {
	die "Need an action" unless scalar @argv;

	my $action = $argv[0]

	my $run = "action::$action"->can('run');

	die "unknown action $action";

	return $run->();
}

exit(run(@ARGV) // 0) unless caller;