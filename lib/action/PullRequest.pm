package action::PullRequest;

use action::std;

use FindBin;

use Simple::Accessor qw{
  gh

  id
  github_repository
  state

};

sub build ( $self, %options ) {

    $self->id                         or die "id is required for creating PullRequest object";
    ref $self->gh eq 'action::GitHub' or die "Need one action::GitHub object";

    return $self;
}

sub _build_state($self) {    # only cache the state then provide accessors

    return $self->gh->get_pr_state( $self->github_repository, $self->id );
}

sub _build_github_repository {
    $ENV{GITHUB_REPOSITORY} or die "Undefined GITHUB_REPOSITORY env";
}

# no need to cache these accessors
sub target_branch($self) {
    $self->state->{base}->{ref} or die;
}

sub head_sha($self) {
    $self->state->{head}->{sha} or die;
}

sub head_repo($self) {
    $self->state->{head}->{repo}->{full_name} or die;
}

sub head_branch($self) {
    $self->state->{head}->{ref} or die;
}

sub info($self) {

    say "#" x 50;
    say "# GITHUB_REPOSITORY: ", $self->github_repository;
    say "# TARGET_BRANCH:     ", $self->target_branch;
    say "# HEAD_SHA:          ", $self->head_sha;
    say "# HEAD_REPO:         ", $self->head_repo;
    say "# HEAD_BRANCH:       ", $self->head_branch;

    #say "# GIT_WORK_TREE:     $GIT_WORK_TREE
    #echo "# Conclusion:        $WORKFLOW_CONCLUSION # neutral, success, cancelled, timed_out, failure
    say "#" x 50;

    return;
}

# interactions with gh

sub add_comment ( $self, $comment ) {

    return $self->gh->add_comment_to_issue( $self, $comment );
}

1;
