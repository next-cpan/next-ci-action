package action::GitHub::Action;

use action::std;

use Carp qw{confess};

use Exporter 'import';
our @EXPORT    = qw/WARN ERROR FATAL/;
our @EXPORT_OK = (@EXPORT);

sub WARN(@msg) {    # display an error message
    say '[Warning] ', join( ' ', @msg );

    return;
}

sub ERROR(@msg) {    # display a read message
    say '[Error] ', join( ' ', @msg );

    return;
}

sub FATAL(@msg) {    # display a read message

    ERROR( 'FATAL', @msg );
    confess( join( ' ', 'FATAL', @msg ) );

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
