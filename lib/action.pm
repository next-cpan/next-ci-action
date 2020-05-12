#!perl

package action;

use action::std;

use action::GitHub;

use Simple::Accessor qw{gh workflow_conclusion};

#use Simple::Accessor qw{foo};

sub _build_gh {
    action::GitHub->new;
}

sub _build_workflow_conclusion {
    $ENV{WORKFLOW_CONCLUSION} or die "missing WORKFLOW_CONCLUSION";
}

1;
