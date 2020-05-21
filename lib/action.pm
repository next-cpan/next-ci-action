package action;

use action::std;

use action::Git;
use action::GitHub;
use action::Settings;
use action::PullRequest;

use Test::More;

use File::pushd;
use Cwd;

use Simple::Accessor qw{

  gh
  git
  cli

  pr_id

  pull_request

  workflow_conclusion
};

with 'action::Roles::Settings';

use action::Helpers qw{read_file read_file_no_comments};

sub build ( $self, %options ) {

    # setup ...
    $self->git or die "Missing git entry when creating action";      # init git early
    $self->cli or die "Missing client entry when creating action";

    $self->git->setup_repository_for_pull_request( $self->pull_request )
      or die "Fail to setup Git Repo for PullRequest";

    return $self;
}

sub _build_gh {
    action::GitHub->new;
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

sub _build_pull_request($self) {    # if unset build a PR object using the current PR_NUMBER

    return action::PullRequest->new( id => $self->pr_id, gh => $self->gh );
}

sub is_success($self) {
    return $self->workflow_conclusion eq 'success';
}

sub is_known_maintainer_for_organization($self) {

}

# check if the action is coming from a maintainer
sub is_repository_maintainer($self) {    # FIXME is_repo_maintainer
    my $author = $self->pull_request->author or die;

    # make sure we are in the git work tree
    my $cd = pushd( $self->git->work_tree ) or die;

    # default teams which can submit patches
    my @check_team_memberships = $self->settings->get( maintainers => default_maintenance_teams => )->@*;

    my $maintenance_team = $self->settings->get( maintainers => team => ) or die "maintance team unset";

    # FIXME make sure the user is known in the maintainers group
    if ( !$self->gh->is_user_team_member( $author, $maintenance_team ) ) {

        #$self->close_pull_request( );
        # FIXME idea... maybe perform a request to add the user to maintenance...
        # could not perform the final merge
        $self->pull_request->add_comment("user \@$author is not listed in maintenance team please request...");

        # we should abort ..,
        #return;
    }

    my $maintainers_file = $self->settings->get( maintainers => file => );
    if ( -e $maintainers_file ) {
        say "# maintainers file found ", $maintainers_file;
        my $autorized_rules = read_file_no_comments($maintainers_file);
        foreach my $rule (@$autorized_rules) {
            return 1 if $author eq $rule;
            if ( $rule =~ m{^teams/([a-z0-9_]+)} ) {
                push @check_team_memberships, $1;
            }
        }
    }

    ### need a token to use this request
    # checking next-cpan teams
    foreach my $team (@check_team_memberships) {
        return 1 if $self->gh->is_user_team_member( $author, $team );
    }

    return;
}

sub rebase_and_merge($self) {
    my $target_branch = $self->gh->target_branch;

    ### FIXME: we can improve this part with a for loop to retry
    ###        when dealing with multiple requests

    if ( !$self->git->rebase("origin/$target_branch") ) {
        $self->gh->close_pull_request("Fail to rebase branch to ${target_branch}. Please fix and resubmit.");
        return;
    }

    my $out = $self->git->run( 'push', '--force-with-lease', "origin", "HEAD:$target_branch" );
    my $ok  = $? == 0;

    $self->gh->add_comment("**Clean PR** from Maintainer merged to $target_branch branch");

    return $ok;
}

1;
