package action::GitHub;

use action::std;

use action::Helpers qw{read_file};

use Net::GitHub::V3;

use Simple::Accessor qw{netgithub github_user github_token github_event_path pr_id pull_request event issues};

use JSON::PP ();

use Test::More;

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

sub _build_github_event_path {
    my $f = $ENV{GITHUB_EVENT_PATH} or die "GITHUB_EVENT_PATH unset";
    die "github_event_path does not exist" unless -e $f;
    return $f;
}

sub _build_event($self) {
    my $json = JSON::PP->new->utf8->relaxed->allow_nonref;
    return $json->decode( read_file( $self->github_event_path ) );
}

# aliases
sub _build_pull_request ($self) {
    return $self->netgithub->pull_request;
}

sub _build_issues ($self) {
    return $self->netgithub->issues;
}

sub _build_pr_id ($self) {

    # $(jq -r ".number" "$GITHUB_EVENT_PATH")
    my $id = $self->event->{number} or die "Cannot find PR id";
    return $id;
}

sub close_pull_request ($self) {
    $self->pull_request->close( $self->pr_id );
}

# add a comment to the current PR
sub add_comment ( $self, $comment ) {
    return unless defined $comment;

    my $id = $self->pr_id;
    say "adding a comment to the Pull Request #$id $comment";

    $self->issues->create_comment( $id, { "body" => $comment } );

    return;
}

1;
