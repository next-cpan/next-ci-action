package action::cmd::opened;

use action::std;
use Test::More;

sub run($action) {

    say "opened action...";

    #note "=== ENV";
    #note explain \%ENV;

    say "workflow_conclusion: ", $action->workflow_conclusion;

    return;
}

1;
