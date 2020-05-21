package action::GitHub::Monitor;

use action::std;

use action::GitHub::Issue;
use action::GitHub::Action qw{WARN ERROR};

use Simple::Accessor qw{
  github

  issue_for_slash_commands
  issue_for_repo_without_token
};

with 'action::Roles::Settings';

sub build ( $self, %options ) {

    $self->{github} or die q[GitHub object is required];

    return $self;
}

sub slash_command ( $self, $command, @args ) {
    return $self->github()->add_comment_to_issue(    #.
        $self->issue_for_slash_commands,             #
        join( ' ', $command, @args )                 #
    );
}

sub slash_setup ( $self, $full_repo ) {
    if ( !$full_repo ) {
        ERROR('/setup called without a repository name');
        return;
    }

    if ( !index( '/', $full_repo ) ) {
        ERROR( '/setup called without a complete repository name: ', $full_repo );
        return;
    }

    return $self->slash_command( '/setup', $full_repo );
}

sub report_missing_token_for_repository ( $self, $repo ) {

    return unless $repo;

    my $comment = qq[The repository **$repo** has no BOT_ACCESS_TOKEN setup. Need one admin to setup.];

    return $self->github()->add_comment_to_issue(    #.
        $self->issue_for_repo_without_token,         #
        $comment
    );
}

sub _build_issue_for_repo_without_token($self) {
    my $settings = $self->settings->get( github => monitor => );
    my $org      = $self->settings->get( github => org     => );

    my $repo = $settings->{repo}                    or die "missing repo";
    my $id   = $settings->{issues}->{missing_token} or die "missing missing_token issue number";

    return action::GitHub::Issue->new( github_repository => $org . '/' . $repo, id => $id );
}

sub _build_issue_for_slash_commands($self) {

    my $settings = $self->settings->get( github => monitor => );
    my $org      = $self->settings->get( github => org     => );

    my $repo = $settings->{repo}                    or die "missing repo";
    my $id   = $settings->{issues}->{slash_command} or die "missing slash_command issue number";

    return action::GitHub::Issue->new( github_repository => $org . '/' . $repo, id => $id );
}

# when a patch needs approval report it to the dashboard
#   create a new issue
sub report_pending_patch($self) {
    ...;
}

# add a comment to a preset issue?
#
sub report_negligeant_repository($self) {
    ...;
}

1;
