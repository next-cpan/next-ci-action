package action::cmd::reopened;

use action::std;

use action::cmd::opened;

sub run($action) {

    say "# reopened action redirects to opened";

    return action::cmd::opened::run($action);
}

1;
