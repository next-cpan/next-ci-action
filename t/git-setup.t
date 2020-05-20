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
use action::GitHub;
use action::PullRequest;

my $tmp = setup_test('pr-setup');

is getcwd(), $tmp, "setup_test leaves us in the correct location";

my $git = action::Git->new();
is $git->work_tree, $tmp, "work_tree using current directory";

my $gh = action::GitHub->new();
my $pr = action::PullRequest->new( id => 29, gh => $gh );
ok $pr, "action::PullRequest->new";
is $pr->target_branch, 'p5', 'target_branch';

ok $git->setup_repository_for_pull_request($pr), 'setup_repository_for_pull_request';

done_testing;
