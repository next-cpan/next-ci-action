package action::GitHub;

use action::std;

use action::Helpers qw{read_file};
use HTTP::Tinyish ();

use Simple::Accessor qw{
  github_user
  github_token

  ua
  json

  default_org
  default_repository

  monitor

  headers
};

use action::GitHub::Action qw{WARN ERROR FATAL INFO};

use JSON::PP ();
use action::GitHub::Monitor;

use Test::More;

with 'action::Roles::Settings';

our $VERBOSE = 1;

sub build ( $self, %options ) {

    _mock_http_for_tests() if $ENV{MOCK_HTTP_REQUESTS};

    return $self;
}

sub _build_default_org {
    die;
}

sub _build_default_repository {
    die;
}

sub _build_ua {
    HTTP::Tinyish->new( agent => "nextCPAN/1.0" );
}

sub _build_github_user {
    $ENV{GITHUB_NAME} // $ENV{GITHUB_ACTOR} or die "github user unset";
}

sub _build_github_token {
    $ENV{GITHUB_TOKEN} or die "GITHUB_TOKEN unset";
}

sub _build_json {
    return JSON::PP->new->utf8->relaxed->allow_nonref;
}

sub _build_monitor($self) {
    return action::GitHub::Monitor->new( github => $self );
}

sub BASE_API_URL ($self) {
    return $self->settings->get( github => base_api_url => );
}

sub DEFAULT_ORG ($self) {
    return $self->settings->get( github => org => );
}

sub close_pull_request ( $self, $issue ) {
    die q[Need a Pull Request object] unless ref $issue;

    my ( $repo, $id ) = ( $issue->github_repository, $issue->id );
    say "Closing Pull Request #id in repo $repo";

    my $uri = sprintf( "/repos/%s/pulls/%s", $repo, $id );

    return $self->patch( $uri, { "state" => "closed" } );
}

sub add_comment_to_issue ( $self, $issue, $comment ) {
    return unless defined $comment;

    my ( $repo, $id ) = ( $issue->github_repository, $issue->id );
    say "adding a comment to the Pull Request #$id for $repo $comment";

    my $uri = sprintf( "/repos/%s/issues/%s/comments", $repo, $id );

    return $self->post( $uri, { "body" => $comment } );
}

sub create_request_review ( $self, $issue, $users, $teams = undef ) {
    $users //= [];
    $teams //= [];

    return unless scalar @$users || scalar @$teams;

    my ( $repo, $id ) = ( $issue->github_repository, $issue->id );
    say "# create_request_review to PR #$id for $repo";

    # https://developer.github.com/v3/pulls/review_requests/#create-a-review-request
    # POST /repos/:owner/:repo/pulls/:pull_number/requested_reviewers
    my $uri = sprintf( "/repos/%s/pulls/%s/requested_reviewers", $repo, $id );

    my $content = {};
    $content->{reviewers}      = $users if scalar @$users;
    $content->{team_reviewers} = $teams if scalar @$teams;

    return $self->post( $uri, $content );
}

sub get_pr_state ( $self, $repo_full_name, $id ) {

    my $uri    = sprintf( "/repos/%s/pulls/%s", $repo_full_name, $id );
    my $answer = $self->get($uri);

    if ( !$answer->{status} || $answer->{status} != 200 ) {
        die qq[Cannot find PR $id: $uri\n] . explain($answer);
    }

    if ($VERBOSE) {

        say <<"EOS";
::group::[Warning] $uri
=============================================
$answer->{content}
=============================================
::endgroup::
EOS

    }

    my $state = $self->json->decode( $answer->{content} )
      or die "get_pr_state $uri: fail to decode " . $answer->{content};

    return $state;
}

sub is_user_team_member ( $self, $user, $team, $org = undef ) {

    $org //= $self->DEFAULT_ORG();

    # https://developer.github.com/v3/teams/members/#get-team-membership
    # GET /orgs/next-cpan/teams/maintainers/memberships/atoomic
    my $uri = sprintf(
        '/orgs/%s/teams/%s/memberships/%s',
        $org,
        $team,    # need to be visible
        $user
    );

    # we need a special permission to check team memberships PAT
    #       "message":"Resource not accessible by integration"
    my $answer = $self->get_as_bot($uri) // {};

    note "is_user_team_member: $uri => ", explain $answer;

    if ( $answer->{status} && $answer->{status} == 200 ) {
        say "User $user is a member of team $org/$team";
        return 1;
    }

    return;
}

# ===== basic methods to post to GitHub

sub get_as_bot ( $self, $uri ) {

    if ( !$ENV{BOT_ACCESS_TOKEN} ) {

        $self->monitor->slash_setup( $ENV{GITHUB_REPOSITORY} );
        $self->monitor->report_missing_token_for_repository( $ENV{GITHUB_REPOSITORY} );

        # action::exception::MissingBotToken->new(); # FIXME raise an exception
        die "missing BOT_ACCESS_TOKEN";
    }

    # custom headers just for this request
    my $headers = $self->_build_headers( $ENV{BOT_ACCESS_TOKEN} );

    my $answer = $self->ua->get(
        $self->BASE_API_URL() . $uri,
        {
            headers => $headers,
        }
    );

    _debug_http_answer( $uri, $answer );

    return $answer;
}

sub get ( $self, $uri ) {

    my $answer = $self->ua->get(
        $self->BASE_API_URL() . $uri,
        {
            headers => $self->headers,
        }
    );

    _debug_http_answer( $uri, $answer );

    return $answer;
}

sub post ( $self, $uri, $content ) {

    my $answer = $self->ua->post(
        $self->BASE_API_URL() . $uri,
        {
            headers => $self->headers,
            content => $self->encode_content($content),
        }
    );

    _debug_http_answer( $uri, $answer );

    return $answer;
}

sub patch ( $self, $uri, $content ) {

    my $answer = $self->ua->patch(
        $self->BASE_API_URL() . $uri,
        {
            headers => $self->headers,
            content => $self->encode_content($content),
        }
    );

    _debug_http_answer( $uri, $answer );

    return $answer;
}

sub _debug_http_answer ( $uri, $answer ) {

    return unless ref $answer;

    my $status = int( $answer->{status}                                    // 0 );
    my $msg    = sprintf( "Status: %d %s - %s", $status, $answer->{reason} // '???', $uri );

    my $mod = $status % 100;

    if ( $mod == 2 ) {    # 2xx status
        INFO($msg);
    }
    elsif ( $mod == 4 ) {    # 4xx status
        WARN($msg);
    }
    else {
        ERROR($msg);
    }

    if ( $answer->{content} ) {
        action::GitHub::Action::display_group( "URI $uri", $answer->{content} );
    }

    return;
}

sub encode_content ( $self, $content ) {
    return $content unless ref $content;
    return $self->json->encode($content);
}

sub _build_headers ( $self, $token = undef ) {

    # by default use the github token unless we request a different one
    $token //= $self->github_token;
    return {
        "Authorization" => "token $token",                      # AUTH_HEADER
        "Accept"        => "application/vnd.github.v3+json",    # API_HEADER
    };
}

# FIXME move it to a different location for testing only
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

        *$sub = sub ( $self, $url, $data = undef ) {
            my $dump = '';
            ($dump) = explain $data if $data;

            my ( undef, undef, undef, $uri ) = split( '/', $url, 4 );

            print STDERR "# mocked $MET /$uri $dump\n";

            # by default all requests succeeds
            my $answer = {
                protocol => 'HTTP/1.1',
                reason   => 'OK',
                status   => 200,
                success  => 1,
                url      => $url,
                content  => '',
            };

            if ( -d $ENV{MOCK_HTTP_REQUESTS} ) {
                my $f = $ENV{MOCK_HTTP_REQUESTS} . "/gh-api/$MET/$uri";
                if ( -e $f ) {
                    my $content = read_file($f);
                    my ( $header, $content ) = split( /\n/, $content, 2 );
                    if ( $header =~ m{^Status:\s+(\d+)\s+(.+)}i ) {
                        $answer->{status} = $1;
                        $answer->{reason} = $2;
                    }

                    state $json = _build_json();
                    $answer->{content} = eval { $self->json->decode($content) } // $content;
                }
                else {
                    note "File is not available: $f";

                    # when requesting an unknown path from a known directory trigger an error
                    $answer->{status} = 404;
                    $answer->{reason} = 'No Content to Serve';
                }
            }

            return $answer;
        };
    }

    return;
}

1;
