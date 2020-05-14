#!perl

package action::cli;

use action::std;

use action;

use Simple::Accessor qw{action};

sub _build_action($self) {
    main::action->new;
}

sub run ( $self, @argv ) {
    die "Need an action" unless scalar @argv;

    my $action = $argv[0];

    $action =~ m{^[a-z]+$} or die "invalid action";

    my $pkg = "action::cmd::$action";

    eval qq[require $pkg];    # lazy load the action
    my $run = "action::cmd::$action"->can('run');
    die "unknown action '$action'" unless $run;

    return $run->( $self->action );
}

sub start( @argv ) {
    return __PACKAGE__->new()->run(@argv);
}

1;
