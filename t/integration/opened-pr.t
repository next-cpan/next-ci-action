#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';
use lib $FindBin::Bin . '/../../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

#use Test2::Plugin::NoWarnings;

use action::std;

use Cwd ();

{
    note "opened PR - success";
    test_action(
        args               => [qw{--help}],
        exit               => 0,
        conclusion         => 'success',
        pull_request_state => 'open.json',
        test               => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            like $out->{output}, qr{Sample usage}
              or note explain $out;
        },
    );
}

{
    note "opened PR - success";
    test_action(
        args               => [qw{--stage check_ci}],
        exit               => 256,
        conclusion         => 'success',
        pull_request_state => 'open.json',
        test               => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            like $out->{output}, qr{fail to rebase branch}
              or note explain $out;
        },
    );
}

{
    note "opened PR - failure";
    test_action(
        args               => [qw{--stage check_ci}],
        exit               => 0,
        conclusion         => 'failure',
        pull_request_state => 'open.json',
        test               => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];

            like $out->{output}, qr{\Qmocked POST /repos/next-cpan/Next-Test-Workflow/issues/19/comments\E}m, "POST a comment";
            like $out->{output}, qr{\Qmocked PATCH /repos/next-cpan/Next-Test-Workflow/pulls/19\E}m,          "close the PR";

            note explain $out;
        },
    );
}

done_testing;
