package action::cmd::opened;

use action::std;
use Test::More;

sub run($action) {

    say "# opened action...";

    my $conclusion = $action->workflow_conclusion;
    say "workflow_conclusion: ", $conclusion;

    if ( !$action->is_success ) {
        $action->gh->close_pull_request("**Automatically closing** the Pull Request on failure: workflow conclusion was **$conclusion**");
        return;
    }

    # action is a success
    if ( $action->is_maintainer ) {
        return $action->rebase_and_merge ? 0 : 1;
    }
    else {
        # request review from maintainers
        ...;
    }

    return;
}

1;
