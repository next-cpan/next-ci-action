package action::GitHub;

use action::std;

use action::Helpers qw{read_file};
use HTTP::Tinyish ();

use Simple::Accessor qw{
  github_user
  github_token
  github_event_path

  pull_request_state_path
  pull_request_state

  ua
  json

  target_branch
  pr_id

  event
  default_org
  default_repository

  headers

  repo_full_name
};

use JSON::PP ();

use Test::More;

use constant BASE_API_URL => q[https://api.github.com];

sub build ( $self, %options ) {

    _mock_http_for_tests() if $ENV{MOCK_HTTP_REQUESTS};

    $self->repo_full_name or die;

    return $self;
}

sub _build_default_org {
    die;
}

sub _build_default_repository {
    die;
}

sub _build_ua {
    HTTP::Tinyish->new( agent => "NextCpan/1.0" );
}

sub _build_github_user {
    $ENV{GITHUB_NAME} // $ENV{GITHUB_ACTOR} or die "github user unset";
}

sub _build_github_token {
    $ENV{GITHUB_TOKEN} or die "GITHUB_TOKEN unset";
}

sub _build_json($self) {
    return JSON::PP->new->utf8->relaxed->allow_nonref;
}

# we should avoid using the github event and use pull_request_state instead
# sub _build_github_event_path {
#     my $f = $ENV{GITHUB_EVENT_PATH} or die "GITHUB_EVENT_PATH unset";
#     die "github_event_path does not exist" unless -e $f;
#     return $f;
# }

# sub _build_event($self) {
#     return $self->json->decode( read_file( $self->github_event_path ) );
# }

sub _build_pull_request_state($self) {
    return $self->json->decode( read_file( $self->pull_request_state_path ) );
}

sub _build_pull_request_state_path {
    my $f = $ENV{PR_STATE_PATH} or die "PR_STATE_PATH unset";
    die "pull_request_state_path does not exist" unless -e $f && -s _;
    return $f;
}

sub _build_pr_id ($self) {
    my $id = $self->pull_request_state->{number} or die "Cannot find PR number";
    return $id;
}

sub _build_repo_full_name($self) {
    my $full_name = $self->pull_request_state->{head}->{repo}->{full_name} or die "Cannot find repo full_name";

    my ( $org, $repo ) = split( '/', $full_name );
    $self->default_org($org);
    $self->default_repository($repo);

    return $full_name;
}

sub pull_request_sha($self) {    # _build_ ...
                                 # pull_request.head.sha
    my $target = $self->pull_request_state->{head}->{sha} or die "Cannot find pull_request.head.sha branch";
    return $target;
}

sub _build_target_branch($self) {
    my $target = $self->pull_request_state->{base}->{ref} or die "Cannot find target branch";
    return $target;
}

sub close_pull_request ( $self, $msg = undef ) {

    say "Closing Pull Request #", $self->pr_id;

    $self->add_comment($msg) if $msg;

    my $uri = sprintf( "/repos/%s/pulls/%s", $self->repo_full_name, $self->pr_id );
    $self->patch( $uri, { "state" => "closed" } );

    return;
}

# add a comment to the current PR
sub add_comment ( $self, $comment ) {
    return unless defined $comment;

    my $id = $self->pr_id;
    say "adding a comment to the Pull Request #$id $comment";

    my $uri = sprintf( "/repos/%s/issues/%s/comments", $self->repo_full_name, $self->pr_id );

    $self->post( $uri, { "body" => $comment } );

    return;
}

# ===== basic methods to post to GitHub

sub post ( $self, $uri, $content ) {

    return $self->ua->post(
        BASE_API_URL . $uri,
        {
            headers => $self->headers,
            content => $self->encode_content($content),
        }
    );
}

sub patch ( $self, $uri, $content ) {

    return $self->ua->patch(
        BASE_API_URL . $uri,
        {
            headers => $self->headers,
            content => $self->encode_content($content),
        }
    );
}

sub encode_content ( $self, $content ) {
    return $content unless ref $content;
    return $self->json->encode($content);
}

sub _build_headers($self) {
    return {
        "Authorization" => "token " . $self->github_token,      # AUTH_HEADER
        "Accept"        => "application/vnd.github.v3+json",    # API_HEADER
    };
}

# lives here for integration testing: maybe move it to a different location
sub _mock_http_for_tests {
    no warnings 'redefine';

    print STDERR "# Mocking HTTP::Tinyish functions\n";

    my @methods = qw{get head put post delete patch};

    foreach my $method (@methods) {
        no strict 'refs';
        no warnings;
        HTTP::Tinyish->can($method) or die "HTTP::Tinyish::$method is not available";
        my $sub = "HTTP::Tinyish::$method";

        my $MET = uc $method;

        *$sub = sub ( $self, $url, $data ) {
            my $dump = '';
            ($dump) = explain $data if $data;

            my ( undef, undef, undef, $uri ) = split( '/', $url, 4 );

            print STDERR "# mocked $MET /$uri $dump";
            return 1;
        };
    }

    return;
}

1;
