#!perl

package action::cli;

use action::std;

use action;

use action::cmd::opened;

use Simple::Accessor qw{action};

sub _build_action {
	action->new;
}

sub run($self, @argv) {
	die "Need an action" unless scalar @argv;

	my $action = $argv[0];

	my $run = "action::cmd::$action"->can('run');
	die "unknown action '$action'" unless $run;

	return $run->( $self );
}

sub start( @argv ) {
	return __PACKAGE__->new()->run( @argv );
}

1;