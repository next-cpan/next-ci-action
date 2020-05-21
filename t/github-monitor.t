#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Capture::Tiny ':all';

use action::GitHub::Monitor;
use action::GitHub;

my $tmp = setup_test();

my $gh = action::GitHub->new;

my $monitor = action::GitHub::Monitor->new( github => $gh );

ok $monitor, "can create a monitor";

is ref $monitor->issue_for_slash_commands, 'action::GitHub::Issue', 'issue_for_slash_commands';

my ( $stdout, $stderr, @result ) = capture {
    $monitor->slash_setup('org/repo-needs-setup');
};

like $stderr, qr{mocked POST /repos/next-cpan/Next-Monitor-Dashboard/issues/2/comments},
  "/POST a comment to the monitor dashboard issue 2";

( $stdout, $stderr, @result ) = capture {
    $monitor->report_missing_token_for_repository('abc/def');
};

like $stderr, qr{mocked POST /repos/next-cpan/Next-Monitor-Dashboard/issues/1/comments},
  "/POST a comment to the monitor dashboard issue 1";

done_testing;
