package action::Helpers;

use action::std;    # import strict, warnings & features

use Config;
use File::Which ();

use Exporter 'import';
our @EXPORT_OK = qw(read_file zip write_file is_fatpacked update_shebang is_valid_distribution_name);

sub read_file ( $file, $mode = ':utf8' ) {
    local $/;

    open( my $fh, '<' . $mode, $file )
      or die "Fail to open file: $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    return readline($fh);
}

sub write_file ( $file, $content, $mode = ':utf8' ) {
    open( my $fh, '>' . $mode, $file )
      or die "Fail to open file: '$file' $! " . join( ' ', ( caller(1) )[ 0, 1, 2, 3 ] ) . "\n";

    print {$fh} $content;

    return;
}

1;
