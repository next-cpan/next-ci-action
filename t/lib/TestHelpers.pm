package TestHelpers;

use action::std;

use Test::Builder;    # ... avoid warning

use Test2::API qw/context run_subtest/;
use Test2::Tools::Compare qw/is/;

use FindBin;

use Carp qw/croak/;

use File::Copy qw/copy/;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use File::Basename qw(basename);
use POSIX;
use Fcntl qw/SEEK_CUR/;

use Cwd 'abs_path';
use File::pushd;
use File::Path qw(mkpath rmtree);

use Git::Repository;

use action::Helpers qw{write_file};
use action::Git;
use action::GitHub;

use Test2::Harness::Util::IPC qw/run_cmd/;

use Exporter 'import';
our @EXPORT = qw/test_action setup_test/;

my $TMP = File::Temp->newdir();

my $start = Cwd::getcwd;

END {
    chdir($start) if $start;    # make sure File::Temp cleanup can occurs
}

sub root_dir {
    state $root = Cwd::getcwd;

    return $root;
}

sub setup_test($name='unknown') {

    my $root = root_dir();

    $action::Git::DO_FETCH   = 0;
    $action::GitHub::VERBOSE = 0;

    delete $ENV{GIT_WORK_TREE};
    $ENV{GITHUB_REPOSITORY}  = 'next-cpan/Next-Test-Workflow';
    $ENV{GITHUB_TOKEN}       = 'fake-github-token';
    $ENV{MOCK_HTTP_REQUESTS} = $FindBin::Bin . q[/fixtures/] . $name;
    $ENV{BOT_ACCESS_TOKEN}   = 'fake-bot-access-token';

    my $tmp_dir = init_git_directory();
    chdir $tmp_dir or die;

    no warnings 'redefine';
    *action::Settings::_build_file = sub { "$root/settings.yml" };    # FIXME should mock it

    die q[git Repository incorrectly initialized] unless -d q[.git];

    return $tmp_dir;
}

sub _get_uniq_dir_for_test {
    my $pattern = $TMP . '/test_dir_%d';

    state $id = 0;

    while ( ++$id ) {
        my $tmp_dir = sprintf( $pattern, $id );
        next if -e $tmp_dir;
        return abs_path($tmp_dir);    # available

        die "more than 1000 tests!" if $id > 1000;
    }

    return;
}

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

sub init_git_directory {

    my $fake_git_dir = _get_uniq_dir_for_test();

    rmtree($fake_git_dir) if -d $fake_git_dir;
    mkpath($fake_git_dir) or die;

    Git::Repository->run( init => $fake_git_dir );

    my $git = Git::Repository->new( work_tree => $fake_git_dir );

    write_file( "$fake_git_dir/README", "content" );

    $git->run(qw{config advice.ignoredHook false});
    $git->run( 'add', 'README' );
    $git->run( 'commit', '-m', "My First Commit" );

    $git->run( 'remote', 'add', 'origin', 'http://127.0.0.1/void.git' );

    return $fake_git_dir;
}

sub _setup_once {
    state $run_once = 0;

    return if $run_once;

    if ( $ENV{AUTOMATED_TESTING} ) {
        qx{git config --global user.email "you\@example.com"};
        qx{git config --global user.name "Your Name"};
    }

    $run_once = 1;

    return 1;
}

sub test_action(%params) {

    _setup_once();

    my $args       = delete $params{args}       // [];
    my $conclusion = delete $params{conclusion} // 'success';

    my $subtest  = delete $params{test} // delete $params{tests} // delete $params{subtest};
    my $exittest = delete $params{exit};

    my $debug   = delete $params{debug}   // 0;
    my $capture = delete $params{capture} // 1;

    my $env = delete $params{env} // {};

    # PR_STATE_PATH
    my $pull_request_state = delete $params{pull_request_state};
    if ($pull_request_state) {
        my $path = $FindBin::Bin;
        $path =~ s{/t(/.+)?$}{} or die $path;    # root
        $path .= "/t/fixtures/pr/$pull_request_state";
        die "Cannot find event $pull_request_state" unless -e $path;

        $env->{PR_STATE_PATH} = $path;
    }

    if ( keys %params ) {
        croak "Unexpected parameters: " . join( ', ', sort keys %params );
    }

    my $ctx = context();

    $env->{GITHUB_NAME}      //= 'YourUsername';
    $env->{GITHUB_TOKEN}     //= 'beefbeefbeefbeefbeefbeefbeefbeefbeefbeef';
    $env->{BOT_ACCESS_TOKEN} //= 'beefbeefbeefbeefbeefbeefbeefbeefbeefbeef';

    $env->{MOCK_HTTP_REQUESTS} //= 1;

    $env->{GIT_WORK_TREE} = init_git_directory();

    #$env->{NG_DEBUG} = 1; # NetGitHub

    local %ENV = ( PATH => $ENV{PATH}, WORKFLOW_CONCLUSION => $conclusion, %$env );

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
}

1;
