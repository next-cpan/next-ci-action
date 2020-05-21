package action::Roles::Settings;

use action::std;

use Carp qw{confess};
use FindBin;

use action::Settings;
use Simple::Accessor qw{settings};

our $SETTINGS;    # singleton

sub _build_settings {

    $action::Roles::Settings::SETTING //= action::Settings->new;

    return $action::Roles::Settings::SETTING;
}

1;
