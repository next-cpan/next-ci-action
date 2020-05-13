#!perl

package action;

use action::std;

use action::GitHub;

use Git::Repository;

use Simple::Accessor qw{
  gh
  git
  workflow_conclusion
};

sub build ( $self, %options ) {

    # setup ...
    $self->git or die;    # init git early

    return $self;
}

sub _build_gh {
    action::GitHub->new;
}

sub _build_git {
    $ENV{GIT_WORK_TREE} or die q[GIT_WORK_TREE is unset];
    return Git::Repository->new( work_tree => $ENV{GIT_WORK_TREE} );
}

sub _build_workflow_conclusion {
    $ENV{WORKFLOW_CONCLUSION} or die "missing WORKFLOW_CONCLUSION";
}

sub is_success($self) {
    return $self->workflow_conclusion eq 'success';
}

# check if the action is coming from a maintainer
sub is_maintainer($self) {
    1;    # FIXME
}

sub rebase_and_merge($self) {

    my $target_branch = $self->gh->target_branch;

    my $out;

    my $ok = eval {
        say "rebasing branch";
        $out = $self->git->run( 'rebase', "origin/$target_branch" );
        say "rebase: $out";
        1;
    } or do {
        $self->gh->close_pull_request("fail to rebase branch to $target_branch");
        return;
    };

    $out = $self->git->run( 'push', "origin", "HEAD:$target_branch" );
    $self->gh->add_comment("**Clean PR** from Maintainer merging to $target_branch branch");

    return;
}

1;
