package action::GitHub;

use action::std;

use action::Helpers qw{read_file};

use Net::GitHub::V3;

use Simple::Accessor qw{
  netgithub

  github_user
  github_token
  github_event_path

  pr_id

  pull_request
  issues

  event
  default_org
  default_repository

  repo_full_name
};

use JSON::PP ();

use Test::More;

sub build ( $self, %options ) {

    _mock_netgithub_for_tests() if $ENV{MOCK_NETGITHUB};

    $self->repo_full_name or die;

    return $self;
}

sub _build_default_org {
    die;
}

sub _build_default_repository {
    die;
}

sub _build_github_user {
    $ENV{GITHUB_NAME} // $ENV{GITHUB_ACTOR} or die "github user unset";
}

sub _build_github_token {
    $ENV{GITHUB_TOKEN} or die "GITHUB_TOKEN unset";
}

sub _build_netgithub($self) {
    my $gh = Net::GitHub::V3->new(
        version      => 3,
        login        => $self->github_user,
        access_token => $self->github_token
    );

    $gh->set_default_user_repo( $self->default_org, $self->default_repository );    # take effects for all $gh->

    return $gh;
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
    return $self->netgithub->issue;
}

sub _build_pr_id ($self) {

    # $(jq -r ".number" "$GITHUB_EVENT_PATH")
    my $id = $self->event->{number} or die "Cannot find PR id";
    return $id;
}

sub _build_repo_full_name($self) {
    my $full_name = $self->event->{pull_request}->{head}->{repo}->{full_name} or die "Cannot find repo full_name";

    my ( $org, $repo ) = split( '/', $full_name );
    $self->default_org($org);
    $self->default_repository($repo);

    return $full_name;
}

sub close_pull_request ($self) {

    $self->pull_request->update_pull( $self->pr_id, { "state" => "closed" } );

    return;
}

# add a comment to the current PR
sub add_comment ( $self, $comment ) {
    return unless defined $comment;

    my $id = $self->pr_id;
    say "adding a comment to the Pull Request #$id $comment";

    # "/repos/%s/%s/issues/comments/%s"
    $self->issues->create_comment( $id, { "body" => $comment } );

    return;
}

# lives here for integration testing: maybe move it to a different location
sub _mock_netgithub_for_tests {
    no warnings 'redefine';

    print STDERR "# Mocking Net::GitHub query function\n";

    my @packages = qw{
      Net::GitHub::V3::Actions
      Net::GitHub::V3::Events
      Net::GitHub::V3::Gists
      Net::GitHub::V3::GitData
      Net::GitHub::V3::Gitignore
      Net::GitHub::V3::Issues
      Net::GitHub::V3::OAuth
      Net::GitHub::V3::Orgs
      Net::GitHub::V3::PullRequests
      Net::GitHub::V3::Repos
      Net::GitHub::V3::ResultSet
      Net::GitHub::V3::Search
      Net::GitHub::V3::Users
    };

    foreach my $pkg (@packages) {
        eval qq{require $pkg; 1} or die $@;
        no strict 'refs';
        no warnings;
        my $sub = "${pkg}::query";

        #print STDERR "mocking $sub\n";
        *$sub = sub ( $self, $method, $url, $data = undef, @cruft ) {
            my $dump = '';
            ($dump) = explain $data if $data;
            print STDERR "# mocked ${pkg}::query $method $url $dump";
            return;
        };
    }

    return;
}

1;
