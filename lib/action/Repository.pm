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

sub _shuffle( $list ) {
    die unless ref $list;
    my %h = map { $_ => 1 } $list->@*;
    return [ keys %h ];
}

sub request_review_from_maintainers($self) {

    my $asked_counter = 0;
    my $max           = $self->settings->get( reviewers => maximum => )
      or FATAL("reviewers.maximum is unset");

    # if we got some users ask code review to a few of them
    #	use a random list to not always ask the same users...
    #my $random_users = _shuffle( $self->maintainers->users );

    $self->pull_request->request_review_from( $self->maintainers->users, $self->maintainers->teams );

    # always add a message listing users and teams to notify them there is a pending PR
    my $list_gh_users = '';
    $list_gh_users = join "\n", map { "- \@$_" } sort $self->maintainers->users->@*;

    my $org = $self->settings->get( github => org => ) or die "no org";

    my $list_gh_teams = '';
    $list_gh_teams = join "\n", map { "- \@$org/$_" } sort $self->maintainers->teams->@*;

    my $maintainers_file = $self->settings->get( maintainers => file => )
      or FATAL("Missing settings for maintainers file");

    # if we got some teams != defaults request to members
    # maybe only add a comment
    $self->pull_request->add_comment( <<"EOS" );
This Pull Request is waiting for a code review from a maintainer.
Members from teams or users listed in $maintainers_file can validate or invalidate this patch:

Teams:
$list_gh_teams

Users:
$list_gh_users
EOS

    return;
}

1;

