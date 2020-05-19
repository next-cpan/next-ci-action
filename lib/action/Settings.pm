package action::Settings;

use action::std;

use Simple::Accessor qw{yaml content file};
use YAML::PP;

sub build ( $self, %options ) {

    $self->content or die;

    return $self;
}

sub _build_yaml {
    return YAML::PP->new;
}

sub _build_file {
    my $f = q[settings.yaml];
    die q[Cannot find $f] unless -f $f;

    return $f;
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

1;
