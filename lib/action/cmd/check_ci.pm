package action::cmd::check_ci;

use action::std;
use Test::More;

sub run($action) {

    say "# check_ci:";

    my $conclusion = $action->workflow_conclusion;
    say "workflow_conclusion: ", $conclusion;

    if ( !$action->is_success ) {
        $action->gh->close_pull_request("**Automatically closing** the Pull Request on failure: workflow conclusion was **$conclusion**");
        return;
    }

    # action is a success
    if ( $action->is_maintainer ) {    # FIXME is_repo_maintainer
        return $action->rebase_and_merge ? 0 : 1;
    }
    else {
        # request review from maintainers
        ...;
    }

    return;
}

1;

__END__

###################################
### Perl Repository
###################################

*** Workflow: Incoming PR ****
someone (re)open a PR to a Perl Repo

-> lint check
    - check if we are shipping any unauthorized modules
    - ...

-> try to install module using cnext

    |--> failure: close the Pull Request and ask to resubmit
    |--> success:
                  - create a PR on the PR monitor dashboard

-> done

** Workflow: Approval on a PR ***
[ same as above ? ]
    - add '/approved' in the dashboard PR # check-approval
    - add a comment saying 'Approval sent to ***'


###################################
### Monitor dashboard
###################################

    |--> monitor new PR to the dashboard
         - if maintainer   => merge (close PR)
         - not maintainer  => request some approvals

    |-> monitor comments to the PR using /actions
        /approved:
            check if the PR upstream is approved and if so perform the merge


    |--> handle /actions
        /approved
        /index refresh all
        /index refresh module1
        /setup repo # setup github integration...
        /setup --check
        /setup --refresh
        /close

        /patch ...


###
we cannot create a PR without a PAT
idea use a generic
        /check reponame PR_ID

