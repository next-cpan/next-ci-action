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

  headers
};

use JSON::PP ();

use Test::More;

use constant BASE_API_URL => q[https://api.github.com];    # FIXME settings
use constant DEFAULT_ORG  => q[next-cpan];                 # FIXME settings

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

sub get_pr_state ( $self, $repo_full_name, $id ) {

    my $uri    = sprintf( "/repos/%s/pulls/%s", $repo_full_name, $id );
    my $answer = $self->get($uri);

    if ( !$answer->{status} || $answer->{status} != 200 ) {
        die qq[Cannot find PR $id: $uri\n] . explain($answer);
    }

    say <<"EOS";
::group::[Warning] $uri
=============================================
$answer->{content}
=============================================
::endgroup::
EOS

    my $state = $self->json->decode( $answer->{content} )
      or die "get_pr_state $uri: fail to decode " . $answer->{content};

    return $state;
}

sub is_user_team_member ( $self, $user, $team, $org = +DEFAULT_ORG ) {

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

        # FIXME setup the admin group here
        ### ... could consider posting a comment to a repo which automatically setup the TOKEN for us
        ### view https://github.com/marketplace/actions/slash-command-dispatch
        ### /need-token $REPO $PR JOB_ID
        $self->add_comment("**WARNING:** missing BOT_ACCESS_TOKEN in the repository. Please contact an \@admin-group");
        die "missing BOT_ACCESS_TOKEN";
    }

    # custom headers just for this request
    my $headers = $self->_build_headers( $ENV{BOT_ACCESS_TOKEN} );

    return $self->ua->get(
        BASE_API_URL . $uri,
        {
            headers => $headers,
        }
    );
}

sub get ( $self, $uri ) {

    return $self->ua->get(
        BASE_API_URL . $uri,
        {
            headers => $self->headers,
        }
    );
}

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
