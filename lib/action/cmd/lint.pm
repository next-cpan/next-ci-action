package action::cmd::lint;

use action::std;
use Test::More;

sub run($action) {

    say "# lint:";
    say << "EOS";
FIXME ...
- rebase...
- Confirm no generated files are altered
- Update the NEXT.json using .next/hints.yaml
- Assure VERSION not bumped in NEXT.json
- Check no new modules owned by other distros
EOS

    return;

    $action->rebase();
    $action->check_generated_files();
    $action->update_NEXT_json();
    $action->check_VERSION_not_bumped();
    $action->check_modules_ownership();

    return;
}

1;
