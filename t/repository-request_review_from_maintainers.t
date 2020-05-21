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

use action::Repository;
use action::PullRequest;

use Capture::Tiny ':all';

my $tmp = setup_test('test-maintainers');

my @default_teams = qw{ p5-bulk p5-admins };    # FIXME from config ?

my $in_tmp = pushd("$tmp");

{
    mkpath(".next");
    write_file( ".next/maintainers", <<'EOS' );
# teams from next-cpan
teams/blueteam
teams/redteam

# github user listed there
user1
user2

EOS

    my $pr = action::PullRequest->new( id => 29 );

    my $repo = action::Repository->new( root_dir => $tmp, pull_request => $pr );
    ok $repo, "action::Repository->new;";

    my $maintainers = $repo->maintainers;

    is $maintainers->users, [qw{user1 user2}], 'users set from .next/maintainers';
    is $maintainers->teams, [ @default_teams, qw{blueteam redteam} ], 'teams set from .next/maintainers';

    my ( $stdout, $stderr, @result ) = capture {
        $repo->request_review_from_maintainers;
    };

    #note $stdout;
    #note "STDERR: ", $stderr;

    like $stderr, qr{mocked POST /repos/next-cpan/Next-Test-Workflow/pulls/29/requested_reviewers}, "request review";
    like $stderr, qr{mocked POST /repos/next-cpan/Next-Test-Workflow/issues/29/comments},           "add a comment to issue";
}

done_testing;
