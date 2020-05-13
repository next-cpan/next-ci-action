package TestHelpers;

use action::std;

use Test::Builder;    # ... avoid warning

use Test2::API qw/context run_subtest/;
use Test2::Tools::Compare qw/is/;

use FindBin;

use Carp qw/croak/;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use File::Basename qw(basename);
use POSIX;
use Fcntl qw/SEEK_CUR/;

use Cwd 'abs_path';

use Test2::Harness::Util::IPC qw/run_cmd/;

use Exporter 'import';
our @EXPORT = qw/test_action/;

sub build_cli_cmd {
    state $cache;
    unless ( defined $cache ) {
        require action::cli;
        my $path = abs_path( $INC{'action/cli.pm'} );

        my $base = $path;
        $base =~ s{\Qlib/action/cli.pm\E$}{};
        $path = $base . 'run.pl';
        my $lib = $base . 'lib';

        die "script $path is missing"        unless -f $path;
        die "lib directory is missing: $lib" unless -d $lib;

        $cache = [ $path, "-I$lib" ];
    }

    return $cache;
}

sub test_action(%params) {

    my $action     = delete $params{action} or die;
    my $args       = delete $params{args} // [];
    my $conclusion = delete $params{conclusion} // 'success';

    my $subtest  = delete $params{test} // delete $params{tests} // delete $params{subtest};
    my $exittest = delete $params{exit};

    my $debug   = delete $params{debug}   // 0;
    my $capture = delete $params{capture} // 1;

    my $env = delete $params{env} // {};

    my $event = delete $params{event};
    if ($event) {
        my $path = $FindBin::Bin;
        $path =~ s{/t/.+$}{} or die;    # root
        $path .= "/t/fixtures/events/$event";
        die "Cannot find event $event" unless -e $path;

        $env->{GITHUB_EVENT_PATH} = $path;
    }

    unshift @$args, $action;

    if ( keys %params ) {
        croak "Unexpected parameters: " . join( ', ', sort keys %params );
    }

    my $ctx = context();

    $env->{GITHUB_NAME}  //= 'YourUsername';
    $env->{GITHUB_TOKEN} //= 'beefbeefbeefbeefbeefbeefbeefbeefbeefbeef';

    $env->{MOCK_NETGITHUB} = 1;

    #$env->{NG_DEBUG} = 1; # NetGitHub

    local %ENV = ( WORKFLOW_CONCLUSION => $conclusion, %$env );

    my ( $wh, $cfile );
    if ($capture) {
        ( $wh, $cfile ) = tempfile( "action-$$-XXXXXXXX", TMPDIR => 1, CLEANUP => 1, SUFFIX => '.out' );
        $wh->autoflush(1);
    }

    my $cli_lib = build_cli_cmd;
    my ( $client, @lib ) = @$cli_lib;

    my @cmd = ( $^X, @lib, $client, @$args );

    print "DEBUG: Command = " . join( ' ' => @cmd ) . "\n" if $debug;

    local %ENV = %ENV;
    $ENV{$_} = $env->{$_} for keys %$env;
    my $pid = run_cmd(
        no_set_pgrp => 1,
        $capture ? ( stderr => $wh, stdout => $wh ) : (),
        command       => \@cmd,
        run_in_parent => [ sub { close($wh) } ],
    );

    my ( @lines, $exit );
    if ($capture) {
        open( my $rh, '<', $cfile ) or die "Could not open output file: $!";
        $rh->blocking(0);
        while (1) {
            seek( $rh, 0, SEEK_CUR );    # CLEAR EOF
            my @new = <$rh>;
            push @lines => @new;
            print map { chomp($_); "DEBUG: > $_\n" } @new if $debug > 1;

            waitpid( $pid, WNOHANG ) or next;
            $exit = $?;
            last;
        }

        while ( my @new = <$rh> ) {
            push @lines => @new;
            print map { chomp($_); "DEBUG: > $_\n" } @new if $debug > 1;
        }
    }
    else {
        print "DEBUG: Waiting for $pid\n" if $debug;
        waitpid( $pid, 0 );
        $exit = $?;
    }

    print "DEBUG: Exit: $exit\n" if $debug;

    my $out = {
        exit => $exit,
        $capture ? ( output => join( '', @lines ) ) : (),
    };

    my $name = join( ' ', map { length($_) < 30 ? $_ : substr( $_, 0, 10 ) . "[...]" . substr( $_, -10 ) } grep { defined($_) } "run.pl", @$args );
    run_subtest(
        $name,
        sub {
            if ( defined $exittest ) {
                my $ictx = context( level => 3 );
                is( $exit, $exittest, "Exit Value Check" );
                $ictx->release;
            }

            if ($subtest) {
                local $_ = $out->{output};
                local $? = $out->{exit};
                $subtest->($out);
            }

            my $ictx = context( level => 3 );

            $ictx->diag( "Command = " . join( ' ' => grep { defined $_ } @cmd ) . "\nExit = $exit\n==== Output ====\n$out->{output}\n========" )
              unless $ictx->hub->is_passing;

            $ictx->release;
        },
        { buffered => 1 },
        $out,
    ) if $subtest || defined $exittest;

    $ctx->release;

    return $out;

    #return action::cli::start( $action, @$args );
}

1;