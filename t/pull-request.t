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

use Cwd ();

use File::Copy;
use File::Temp;
use File::Path qw(mkpath rmtree);

use File::pushd;

use action::PullRequest;
use action::GitHub;

my $tmp = File::Temp->newdir();

#ok copy( 'settings.yml', "$tmp/settings.yml" );

$ENV{MOCK_HTTP_REQUESTS} = $FindBin::Bin . q[/fixtures/pr-setup];
$ENV{BOT_ACCESS_TOKEN}   = 'fake-bot-access-token';
$ENV{GITHUB_TOKEN}       = 'fake-github-token';

$ENV{GITHUB_REPOSITORY} = 'next-cpan/Next-Test-Workflow';

## FIXME to remove
my $open_pr = $FindBin::Bin . q[/fixtures/pr/open.json];
$ENV{PR_STATE_PATH} = $open_pr;

my $gh = action::GitHub->new();

isa_ok $gh, 'action::GitHub';

{
    my $pr = action::PullRequest->new( id => 29, gh => $gh );

    is $pr->id, 29, "id=29";
    is $pr->github_repository(), $ENV{GITHUB_REPOSITORY}, "GITHUB_REPOSITORY";

    ok $pr->state, 'can read state';
    ok ref $pr->state eq 'HASH', 'state is a HASH';

    $pr->info;

    is $pr->target_branch, 'p5',                                       'target_branch';
    is $pr->head_sha,      '4900ed08cfc4b6a3d19963b7abb386c33ce659f0', 'head_sha';
    is $pr->head_repo,     'next-cpan/Next-Test-Workflow',             'head_repo';
    is $pr->head_branch,   'workflow-3',                               'head_branch';
}

done_testing;
