package action::Repository::Maintainers;

use action::std;

use Simple::Accessor qw{
  users
  teams
};

with 'action::Roles::Settings';

sub _build_teams($self) {

    my @default_teams = $self->settings->get( maintainers => default_maintenance_teams => )->@*;

    return [@default_teams];
}

sub _build_users {
    return [];
}

1;
