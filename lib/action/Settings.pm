package action::Settings;

use action::std;

use FindBin;

use Simple::Accessor qw{yaml content file};
use YAML::PP;
use Cwd ();

sub build ( $self, %options ) {

    $self->content or die;

    return $self;
}

sub _build_yaml {
    return YAML::PP->new;
}

sub _build_file {
    my $f = q[settings.yml];

    my $path;
    foreach my $dir ( '/action', './', $FindBin::Bin . '/' ) {
        $path = $dir . $f;
        return $path if -f $path;
    }

    die qq[Cannot find file '$f' from ] . Cwd::getcwd unless -f $path;
}

sub _build_content($self) {

    return scalar $self->yaml->load_file( $self->file );
}

sub get ( $self, @list ) {

    my $content = $self->content;

    my $txt = join( ' -> ', @list );

    foreach my $id (@list) {

        die qq[Cannot access to Settings $txt] unless defined $content;

        if ( ref $content eq 'HASH' ) {
            $content = $content->{$id};
        }
        elsif ( ref $content eq 'ARRAY' ) {
            $content = $content->[$id];
        }
        else {
            die qq[Do not know how to access to settings $txt: $content];
        }
    }

    return $content;
}

sub url_for_monitor_issue ( $self, $label ) {

    my $base_url = $self->get( github => base_url => ) or die "no base_url";
    my $org      = $self->get( github => org      => ) or die;

    my $repo = $self->get( github => monitor => repo => ) or die;

    my $id = $self->get( github => monitor => issues => $label )
      or die "no issue set for label $label";

    return sprintf(
        "%s/%s/%s/issues/%d",
        $base_url,
        $org,
        $repo,
        $id
    );
}

1;
