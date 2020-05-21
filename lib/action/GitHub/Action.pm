package action::GitHub::Action;

use action::std;

use Exporter 'import';
our @EXPORT    = qw/WARN ERROR/;
our @EXPORT_OK = (@EXPORT);

sub WARN(@msg) {    # display an error message
    say '[Warning] ', join( ' ', @msg );

    return;
}

sub ERROR(@msg) {    # display a read message
    say '[Error] ', join( ' ', @msg );

    return;
}

sub set_variable ( $name, $value ) {
    $value //= '';

    say '::set-output name=', $name, '::', $value;

    return;
}

sub display_group ( $name, $content ) {

    say '::group::', $name;
    say "=" x 50;
    say $content;
    say "=" x 50;
    say "::endgroup::";

    return;
}

## artifact...

1;
