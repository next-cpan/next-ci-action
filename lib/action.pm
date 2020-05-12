#!perl

package action;

use action::std;

use action::GitHub;

use Simple::Accessor qw{gh workflow_conclusion};

sub build ( $self, %options ) {

    # setup ...

    return $self;
}

sub _build_gh {
    action::GitHub->new;
}

sub _build_workflow_conclusion {
    $ENV{WORKFLOW_CONCLUSION} or die "missing WORKFLOW_CONCLUSION";
}

sub is_success($self) {
    return $self->workflow_conclusion eq 'success';
}

1;
