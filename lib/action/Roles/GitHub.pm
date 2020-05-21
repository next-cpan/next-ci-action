package action::Roles::GitHub;

use action::std;

use action::GitHub;

use Simple::Accessor qw{gh};

our $GITHUB;    # singleton shared amon all classes

sub _build_gh {

    $action::Roles::GitHub::GITHUB //= action::GitHub->new;

    return $action::Roles::GitHub::GITHUB;
}

1;
