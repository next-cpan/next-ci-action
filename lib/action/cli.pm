#!perl

package action::cli;

use action::std;

use Getopt::Long qw(:config no_auto_abbrev no_ignore_case bundling);

use action;

use Simple::Accessor qw{action stage event_action};

sub _build_action($self) {
    main::action->new( cli => $self );
}

sub run ( $self, @args ) {
    return usage() unless scalar @args;

    my $help;
    my $opts = Getopt::Long::GetOptionsFromArray(
        \@args,
        'help'           => \$help,
        'stage=s'        => \( $self->{stage} ),
        'event-action=s' => \( $self->{event_action} ),
    ) or return usage(1);

    return usage() if $help;

    my $stage = $self->stage;

    if ( !defined $stage ) {
        say "Undefined stage: use --stage";
        return usage(1);
    }

    $stage =~ m{^[a-z_]+$} or die "invalid stage";

    my $pkg = "action::cmd::$stage";

    eval qq[require $pkg; 1] or warn $@;    # lazy load the action
    my $run = "action::cmd::$stage"->can('run');
    die "unknown stage '$stage'" unless $run;

    return $run->( $self->action );
}

sub start( @argv ) {
    return __PACKAGE__->new()->run(@argv);
}

sub usage( $exit_code=0 ) {
    my $fh = $exit_code ? \*STDERR : \*STDOUT;

    print {$fh} <<'EOS';
./run.pl --stage STAGE --action ACTION

Sample usages:
    ./run.pl --stage check_ci --event-action opened
    ./run.pl --stage lint     --event-action opened
    ./run.pl --stage cron_stale
EOS

    return $exit_code;
}

1;
