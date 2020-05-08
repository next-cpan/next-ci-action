#!perl

use FindBin;
use lib $FindBin::Bin . '/lib'; 

use action::std;

use action::cmd::opened ();

sub run(@argv) {
	die "Need an action" unless scalar @argv;

	my $action = $argv[0];

	my $run = "action::cmd::$action"->can('run');
	die "unknown action '$action'" unless $run;

	return $run->();
}

exit(run(@ARGV) // 0) unless caller;