package action;

use action::std;

use action::Git;
use action::GitHub;
use action::Settings;
use action::PullRequest;
use action::Repository;

use Test::More;

use File::pushd;
use Cwd;

use action::GitHub::Action qw{WARN ERROR};

use Simple::Accessor qw{

  git
  cli

  pr_id

  pull_request

  workflow_conclusion

  repository
};

with 'action::Roles::Settings';
with 'action::Roles::GitHub';    # provides gh accessor

use action::Helpers qw{read_file read_file_no_comments};

sub build ( $self, %options ) {

    # setup ...
    $self->git or die "Missing git entry when creating action";      # init git early
    $self->cli or die "Missing client entry when creating action";

    $self->git->setup_repository_for_pull_request( $self->pull_request )
      or die "Fail to setup Git Repo for PullRequest";

    return $self;
}

sub _build_git($self) {
    return action::Git->new( settings => $self->settings );
}

sub _build_workflow_conclusion {
    $ENV{WORKFLOW_CONCLUSION} or die "missing WORKFLOW_CONCLUSION";
}

sub _build_pr_id( $self ) {
    my $id = $ENV{PR_NUMBER} or die "Cannot get PR id: missing PR_NUMBER";
    $id eq 'null' and die "PR_NUMBER id is null";

    return $id;
}

sub _build_repository( $self ) {
    return action::Repository->new( root_dir => $self->git->work_tree );
}

sub _build_pull_request($self) {    # if unset build a PR object using the current PR_NUMBER

    return action::PullRequest->new( id => $self->pr_id, gh => $self->gh );
}

sub is_success($self) {
    return $self->workflow_conclusion eq 'success';
}

sub is_known_maintainer_for_organization($self) {

}

sub request_review_from_repository_maintainers($self) {

    # enforce a limit to X
    ...;

}

# check if the action is coming from a maintainer
sub is_repository_maintainer($self) {    # FIXME is_repo_maintainer
    my $author = $self->pull_request->author or die;

    my $maintenance_team = $self->settings->get( maintainers => team => ) or die "maintance team unset";

    # FIXME make sure the user is known in the maintainers group
    if ( !$self->gh->is_user_team_member( $author, $maintenance_team ) ) {

        my $org      = $self->settings->get( github => org => );
        my $teamname = $org . '/' . $maintenance_team;

        my $url = $self->settings->url_for_monitor_issue('request_maintainers_membership');

        # could not perform the final merge
        $self->pull_request->add_comment( ~<<"MSG" );
            user \@$author is not listed in maintenance team \@$teamname
            Please read $url
MSG

        # we should abort ..,
        #return;
    }

    # maybe store the repo
    return $self->repository->is_maintainer($author);
}

sub rebase_and_merge($self) {
    my $target_branch = $self->pull_request->target_branch;

    my $timeout   = $self->settings->get( rebase => timeout   => ) or die "timeout unset";
    my $retry_max = $self->settings->get( rebase => retry_max => ) or die "retry_max unset";

    my $attempt = 0;

    # retry several times to solve concurrency issues
    while ( ++$attempt <= $retry_max ) {

        if ( !$self->git->rebase("origin/$target_branch") ) {
            $self->pull_request->close("Fail to rebase branch to ${target_branch}. Please fix and resubmit.");
            return;
        }

        my $out = $self->git->run( 'push', '--force-with-lease', "origin", "HEAD:$target_branch" );
        my $ok  = $? == 0;
        if ($ok) {
            $self->pull_request->close("**Clean PR** from Maintainer merged to $target_branch branch");
            return 1;
        }

        WARN("Rebase + Push failure, sleep and retry");

        sleep($timeout);
        $self->git->run( 'fetch', 'origin' );
    }

    ERROR("fail to push to upstream repo after $retry_max attempts.");

    $self->pull_request->add_comment("**Clean PR** fail to push to upstream repo after $retry_max attempts.");

    return;
}

1;
