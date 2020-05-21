#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Capture::Tiny ':all';

use action::GitHub::Action qw{WARN ERROR};

my ( $stdout, $stderr, @result );

( $stdout, $stderr, @result ) = capture {
    WARN(qw{this is a test});
};

is $stdout, qq{[Warning] this is a test\n}, "WARN";

( $stdout, $stderr, @result ) = capture {
    ERROR(qw{this is a test});
};

is $stdout, qq{[Error] this is a test\n}, "ERROR";

( $stdout, $stderr, @result ) = capture {
    action::GitHub::Action::set_variable( 'mykey', 'myvalue' );
};

is $stdout, qq[::set-output name=mykey::myvalue\n], 'set_variable';

my $content = <<'EOS';
This is a content
on multiple
lines
EOS

( $stdout, $stderr, @result ) = capture {
    action::GitHub::Action::display_group( 'group name', $content );
};

is $stdout, <<"EOS", "display_group";
::group::group name
==================================================
$content
==================================================
::endgroup::
EOS

done_testing;
