#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

#use Test2::Plugin::NoWarnings;

use Test::MockModule;

use action::std;
use action::Helpers qw{read_json_file write_json_file write_file};

use Cwd ();

use action::Git;

use File::Copy;
use File::Temp;
use File::Path qw(mkpath rmtree);
use File::pushd;

use action;

my $tmp = setup_test('test-maintainers');

my $git = action::Git->new( work_tree => $tmp );

{
    my $action = action->new( cli => ['FAKE'], pr_id => 29 );
    ok $action, "got an action";
    ok $action->gh, "github";
    is $action->pull_request->author, 'atoomic', 'PR author';
    ok $action->is_maintainer(), 'atoomic is a maintainer';
}

{
    my $action = action->new( cli => ['FAKE'], pr_id => 42 );
    is $action->pull_request->author, 'unknown', 'PR author = unknown';

    ok !$action->is_maintainer(), 'unknown is not a maintainer';
}

my $in_tmp = pushd("$tmp");

mkpath(".next");
write_file( ".next/maintainers", <<'EOS' );
##
## This file contains a list of GitHub user or team
##      which can submit PR which can be merged without a review
##

## these two teams are always enabled by default
# teams/p5-admins
# teams/p5-bulk

# teams from next-cpan
teams/myteam

# github user listed there
infile

EOS

$git->add_and_commit(".next/maintainers");

{
    note "list a user in the .next/maintainers file";

    my $action = action->new( cli => ['FAKE'], pr_id => 1 );
    is $action->pull_request->author, 'infile', 'PR author = infile';

    ok $action->is_maintainer(), 'infile is a maintainer : listed from file';
}

{
    note "list a group in the .next/maintainers file";

    my $action = action->new( cli => ['FAKE'], pr_id => 2 );
    is $action->pull_request->author, 'ingroup', 'PR author = ingroup';

    ok $action->is_maintainer(), 'ingroup is a maintainer : group listed in file';
}

# avoid to setup a custom file for it
my $mock = Test::MockModule->new('action::PullRequest')    # .
  ->redefine( author => 'notlisted' );

{
    note "user not listed in .next/maintainers";

    my $action = action->new( cli => ['FAKE'], pr_id => 1 );
    is $action->pull_request->author, 'notlisted', 'PR author = notlisted';

    ok !$action->is_maintainer(), 'notlisted is not a maintainer';
}

{
    note "posting a comment when BOT_ACCESS_TOKEN is missing";
    local %ENV = %ENV;
    delete $ENV{BOT_ACCESS_TOKEN};

    my $action = action->new( cli => ['FAKE'], pr_id => 1 );
    is $action->pull_request->author, 'notlisted', 'PR author = notlisted';

    like(
        dies { $action->is_maintainer() },
        qr/missing BOT_ACCESS_TOKEN/m,
        "comment and die when BOT_ACCESS_TOKEN is missing"
    );
}

done_testing;
