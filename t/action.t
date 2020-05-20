#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use action::std;
use action::Helpers qw{read_json_file write_json_file write_file};

use Cwd ();

use File::Copy;
use File::Temp;
use File::Path qw(mkpath rmtree);

use File::pushd;

use action;

my $tmp = setup_test('pr-setup');

like(
    dies { action->new() },
    qr/Missing client entry when creating action/m,
    "cannot initialize"
);

like(
    dies { action->new( cli => ['FAKE'] ) },
    qr/Cannot get PR id: missing PR_NUMBER/m,
    "missing pr id"
);

my $action = action->new( cli => ['FAKE'], pr_id => 29 );

ok $action, "initialize action for pr_id 29";

# {
#     my $pr = action::PullRequest->new( id => 29, gh => $gh );

#     is $pr->id, 29, "id=29";
#     is $pr->github_repository(), $ENV{GITHUB_REPOSITORY}, "GITHUB_REPOSITORY";

#     ok $pr->state, 'can read state';
#     ok ref $pr->state eq 'HASH', 'state is a HASH';

#     $pr->info;

#     is $pr->target_branch, 'p5', 'target_branch';
#     is $pr->head_sha, '4900ed08cfc4b6a3d19963b7abb386c33ce659f0', 'head_sha';
#     is $pr->head_repo, 'next-cpan/Next-Test-Workflow', 'head_repo';
#     is $pr->head_branch, 'workflow-3', 'head_branch';
# }

done_testing;

##
# ╰─> g rv
# origin  git@github.com:next-cpan/next-ci-action.git (fetch)
#origin  git@github.com:next-cpan/next-ci-action.git (push)

