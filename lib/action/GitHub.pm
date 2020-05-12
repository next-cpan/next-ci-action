package action::GitHub;

use action::std;

use Net::GitHub::V3;

use Simple::Accessor qw{netgithub github_user github_token};

sub _build_github_user {
    $ENV{GITHUB_NAME} // $ENV{GITHUB_ACTOR} or die "github user unset";
}

sub _build_github_token {
    $ENV{GITHUB_TOKEN} or die "GITHUB_TOKEN unset";
}

sub _build_netgithub($self) {
    return Net::GitHub::V3->new(
        version      => 3,
        login        => $self->github_user,
        access_token => $self->github_token
    );
}

# aliases

1;
