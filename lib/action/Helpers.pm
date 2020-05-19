package action::Helpers;

use action::std;    # import strict, warnings & features

use Exporter 'import';
use Cwd ();

our @EXPORT    = qw(read_file write_file);
our @EXPORT_OK = ( @EXPORT, qw{read_json_file write_json_file read_file_no_comments} );

sub read_file ( $file, $mode = ':utf8' ) {
    local $/;

    open( my $fh, '<' . $mode, $file )
      or die "Fail to open file '$file': $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    return readline($fh);
}

sub write_file ( $file, $content, $mode = ':utf8' ) {
    open( my $fh, '>' . $mode, $file )
      or die "Fail to open file '$file': '$file' $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    print {$fh} $content;

    return;
}

sub json {
    state $json = JSON::PP->new->utf8->relaxed->allow_nonref;
    return $json;
}

sub read_json_file ( $file ) {
    my $content = read_file($file);

    return unless length $content;

    return json()->decode($content);
}

sub write_json_file ( $file, $content ) {
    return write_file( $file, json()->encode($content) );
}

sub read_file_no_comments ( $file, $mode = ':utf8' ) {
    my $content = read_file( $file, $mode );
    my @lines   = split( "\n", $content );

    my @keep;

    foreach my $l (@lines) {
        next if $l =~ m{^\s*#};
        $l         =~ s{^\s+}{};
        $l         =~ s{#.*$}{};    # poor man strip
        $l         =~ s{\s+$}{};
        push @keep, $l if length $l;
    }

    return \@keep;
}

1;
