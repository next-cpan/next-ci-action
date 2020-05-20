#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

#use Test2::Plugin::NoWarnings;

use action::std;
use action::Helpers qw{read_json_file write_json_file write_file};

use Cwd qw(getcwd abs_path);

use File::Copy;
use File::Temp;
use File::Path qw(mkpath rmtree);

use File::pushd;

use action::Git;

my $tmp = setup_test();

delete $ENV{GIT_WORK_TREE};

is getcwd(), $tmp, "setup_test leaves us in the correct location";

my $git = action::Git->new();
is $git->work_tree, $tmp, "work_tree using current directory";

{
    local $ENV{GITHUB_TOKEN} = 'beef';
    is $git->get_repository_url('org/repo'), 'https://x-access-token:beef@github.com/org/repo.git', 'get_repository_url using GITHUB_TOKEN';

    is $git->get_repository_url( 'org/repo', 'plane' ), 'https://x-access-token:plane@github.com/org/repo.git', 'get_repository_url using custom token';
}

{
    note "testing rebase";
    my $tmp2 = setup_test();
    isnt $tmp2, $tmp, "got a different directory";

    my $git = action::Git->new();
    is $git->work_tree, $tmp2, "work_tree using current directory";

    write_file( "file1.txt", "content" );

    $git->run(qw{add file1.txt});

    like(
        dies { $git->run(qw{add file2.txt}) },
        qr/fatal: pathspec 'file2.txt' did not match any files/m,
        "fatal: pathspec 'file2.txt' did not match any files"
    );

    $git->run(qw{commit -m mytxtmessage});

    $git->run(qw{checkout -b mybranch});

    ok $git->rebase('master'), "can rebase on master";

    $git->run(qw{reset HEAD^});

    write_file( "file1.txt", "conflict" );

    $git->run(qw{add file1.txt});
    $git->run(qw{commit -m conflict});

    is $git->in_rebase(), 0, "not in a rebase";

    $git->run(qw{rebase master});

    ok !$git->rebase('master'), "fails to rebase on master";
}

done_testing;
