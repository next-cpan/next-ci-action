package action::cmd::opened;

use action::std;
use Test::More;

sub run() {

	say "opened action...";

	note "=== ENV";
	note explain \%ENV;

	return;
}

1;