#!perl

use FindBin;
use lib $FindBin::Bin . '/../lib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

#use Test2::Plugin::NoWarnings;

use action::std;

use Cwd ();

{
    note "opened PR - success";
    test_action(
        action     => 'opened',
        args       => [],
        exit       => 0,
        conclusion => 'success',
        test       => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            ok 1;

            #note explain $out;
        },
    );
}

{
    note "opened PR - failure";
    test_action(
        action     => 'opened',
        args       => [],
        exit       => 0,
        conclusion => 'failure',
        event      => 'create-pr.json',
        test       => sub($out) {
            my $lines = [ split( /\n/, $out->{output} ) ];
            like $out->{output}, qr{\Qmocked Net::GitHub::V3::Issues::query POST /repos/next-cpan/Next-Test-Workflow/issues/12/comments\E}m, "POST a comment";

            note explain $out;
        },
    );
}

ok 1;

done_testing;
