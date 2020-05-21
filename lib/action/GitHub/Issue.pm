package action::GitHub::Issue;

use action::std;

use Simple::Accessor qw{
  github_repository
  id
};

sub build ( $self, %options ) {

    $self->{github_repository} or die q[github_repository is required];
    $self->{id}                or die q[id is required];
    $self->{id} =~ m{^[0-9]+$} or die q[id is not numeric];

    return $self;
}

1;
