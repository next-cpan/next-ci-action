package action::Repository;

use action::std;

use Test::More;

use File::pushd;
use Cwd;

use action::Repository::Maintainers;
use action::GitHub::Action qw{WARN ERROR FATAL};

use Simple::Accessor qw{
  root_dir

  pull_request
  maintainers

};

with 'action::Roles::Settings';
with 'action::Roles::GitHub';

use action::Helpers qw{read_file_no_comments};

sub build ( $self, %options ) {
    $self->{root_dir} // FATAL("root_dir unset");

    return $self;
}

sub _build_maintainers($self) {

    # make sure we are in the git work tree
    my $cd = pushd( $self->root_dir ) or FATAL( "Cannot chdir to root_dir: ", $self->root_dir );

    my $maintainers_file = $self->settings->get( maintainers => file => )
      or FATAL("Missing settings for maintainers file");

    my $maintainers = action::Repository::Maintainers->new;

    if ( -e $maintainers_file ) {
        say "# maintainers file found ", $maintainers_file;
        my $autorized_rules = read_file_no_comments($maintainers_file);
        foreach my $rule (@$autorized_rules) {
            $rule =~ s{^\s+}{};
            $rule =~ s{\s+$}{};
            next unless length $rule;
            if ( $rule =~ m{^teams/([a-z0-9_]+)} ) {
                push $maintainers->teams->@*, $1;
            }
            else {
                push $maintainers->users->@*, $rule;
            }
        }
    }

    return $maintainers;
}

sub is_maintainer ( $self, $author ) {

    return unless defined $author;

    my $maintainers = $self->maintainers;

    my $users = $maintainers->users;

    foreach my $user ( $users->@* ) {
        return 1 if $user eq $author;
    }

    my $teams = $maintainers->teams;

    foreach my $team ( $teams->@* ) {
        return 1 if $self->gh->is_user_team_member( $author, $team );
    }

    return;
}

sub request_review_from_maintainers($self) {

    # if we got some users only request the users

    # if we got some teams != defaults request to members
    # maybe only add a comment

    # otherwise request admin teams members to review
    # maybe only add a comment

}

1;

