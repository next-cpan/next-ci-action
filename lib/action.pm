#!perl

package action;

use action::std;

use action::GitHub;

use Git::Repository;

use Test::More;

use File::pushd;

use Simple::Accessor qw{

  gh
  git

  git_work_tree

  workflow_conclusion
};

use action::Helpers qw{read_file read_file_no_comments};

use constant MAINTAINERS_FILE          => q[.next/maintainers];
use constant DEFAULT_MAINTENANCE_TEAMS => qw{p5-bulk p5-admins};

use constant DEFAULT_ORG => q[next-cpan];

sub build ( $self, %options ) {

    # setup ...
    $self->git or die;    # init git early

    return $self;
}

sub _build_gh {
    action::GitHub->new;
}

sub _build_git($self) {
    return Git::Repository->new( work_tree => $self->git_work_tree );
}

sub _build_git_work_tree {
    return ( $ENV{GIT_WORK_TREE} or die q[GIT_WORK_TREE is unset] );
}

sub _build_workflow_conclusion {
    $ENV{WORKFLOW_CONCLUSION} or die "missing WORKFLOW_CONCLUSION";
}

sub is_success($self) {
    return $self->workflow_conclusion eq 'success';
}

# check if the action is coming from a maintainer
sub is_maintainer($self) {
    my $author = $self->gh->pull_request_author or die;

    # make sure we are in the git work tree
    my $cd = pushd( $self->git_work_tree ) or die;

    # default teams which can submit patches
    my @check_team_memberships = ( +DEFAULT_MAINTENANCE_TEAMS );

    # FIXME make sure the user is known in the maintainers group

    if ( -e MAINTAINERS_FILE ) {
        say "# maintainers file found ", MAINTAINERS_FILE;
        my $autorized_rules = read_file_no_comments(MAINTAINERS_FILE);
        foreach my $rule (@$autorized_rules) {
            return 1 if $author eq $rule;
            if ( $rule =~ m{^teams/([a-z0-9_]+)} ) {
                push @check_team_memberships, $1;
            }
        }
    }

    # checking next-cpan teams
    foreach my $team (@check_team_memberships) {

        # https://developer.github.com/v3/teams/members/#get-team-membership
        # GET /orgs/next-cpan/teams/maintainers/memberships/atoomic
        my $uri = sprintf(
            '/orgs/%s/teams/%s/memberships/%s',
            +DEFAULT_ORG,
            $team,
            $author
        );

        my $answer = $self->gh->get($uri) // {};

        note "memberships: $uri => ", explain $answer;

        if ( $answer->{status} && $answer->{status} == 200 ) {
            say "Author $author is a member of team $team";
            return 1;
        }
    }

    return;
}

sub rebase_and_merge($self) {
    my $target_branch = $self->gh->target_branch;

    my $out;

    # ... need a hard reset first
    # pull_request.head.sha

    say "pull_request.head.sha ", $self->gh->pull_request_sha;

    ### FIXME: we can improve this part with a for loop to retry
    ###		   when dealing with multiple requests

    my $ok = eval {
        say "rebasing branch";
        $out = $self->git->run( 'rebase', "origin/$target_branch" );
        say "rebase: $out";
        $self->in_rebase() ? 0 : 1;    # abort if we are in middle of a rebase conflict
    } or do {
        $self->gh->close_pull_request("fail to rebase branch to $target_branch");
        return;
    };

    $out = $self->git->run( 'push', '--force-with-lease', "origin", "HEAD:$target_branch" );
    $ok &= $? == 0;
    $self->gh->add_comment("**Clean PR** from Maintainer merging to $target_branch branch");

    say "rebase_and_merge OK ?? ", $ok;

    return $ok;
}

sub in_rebase($self) {

    my $rebase_merge = $self->git->run(qw{rev-parse --git-path rebase-merge});
    return 1 if $rebase_merge && -d $rebase_merge;

    my $rebase_apply = $self->git->run(qw{rev-parse --git-path rebase-merge});
    return 1 if $rebase_apply && -d $rebase_apply;

    return 0;
}

1;
