package action::Git;

use action::std;

use FindBin;

use Git::Repository;

use action::Settings;

use Simple::Accessor qw{git work_tree};

with 'action::Roles::Settings';

use Cwd ();

our $DO_FETCH = 1;

sub _build_git($self) {
    return Git::Repository->new( work_tree => $self->work_tree );
}

sub _build_work_tree($self) {

    my $cwd = $ENV{GIT_WORK_TREE} // Cwd::getcwd();

    if ( -e "$cwd/Dockerfile" ) {    # protection to avoid scrubling with our own repo
        die qq[Cannot init git work_tree from $cwd];
    }

    return $cwd if -d "$cwd/.git";

    die qq[Cannot find git repository from: $cwd (can set GIT_WORK_TREE or chdir)];
}

# delegate to Git::Repository
sub run ( $self, @args ) {
    say "# GIT RUN: ", join( ' ', @args );
    return $self->git->run(@args);
}

# convenient helpers
sub add ( $self, @what ) {
    $self->run( 'add', @what );
}

sub commit ( $self, $message ) {
    $self->run( 'commit', '-m', $message );
}

sub add_and_commit ( $self, @what ) {
    $self->add(@what);
    $self->commit( 'update file: ' . $what[0] );

    return;
}

# helpers
sub get_repository_url ( $self, $repository, $token = undef ) {
    $token //= $ENV{GITHUB_TOKEN} or die "missing GITHUB_TOKEN";

    my $template = q[https://x-access-token:~TOKEN~@github.com/~REPOSITORY~.git];

    my $url = $template;
    $url =~ s{~TOKEN~}{$token};
    $url =~ s{~REPOSITORY~}{$repository};

    return $url;
}

sub setup_repository_for_pull_request ( $self, $pull_request ) {

    # display informations about Pull Request
    $pull_request->info;

    my $settings = $self->settings;

    # git config
    $self->run( qw{config --global user.email}, $settings->get( git => user => 'email' ) );
    $self->run( qw{config --global user.name},  $settings->get( git => user => 'name' ) );

    # set remotes url
    {
        my $url = $self->get_repository_url( $pull_request->github_repository );
        $self->run( qw{remote set-url origin}, $url );
    }

    {
        eval { $self->run(qw{remote rm fork}) };    # fails silently

        my $url = $self->get_repository_url( $pull_request->head_repo );
        $self->run( qw{remote add fork}, $url );
    }

    if ($DO_FETCH) {

        # fetch
        $self->run( qw{fetch origin}, $pull_request->target_branch );
        $self->run( qw{fetch fork},   $pull_request->head_branch );
        eval { $self->run(qw{branch -D check_pr}) };    # silently fail
        $self->run( qw{checkout -b check_pr}, 'fork/' . $pull_request->head_branch );

        # download the entire commit history as the original clone is done with --depth 1
        eval { $self->run(qw{pull --unshallow}) } or warn $@;
    }

    $self->run(qw{clean -dxf});

    return 1;
}

sub rebase ( $self, $rebase_id ) {

    my $ok = eval {
        say "rebasing branch";
        my $out = $self->run( 'rebase', $rebase_id );
        say "rebase: $out";
        $self->in_rebase() ? 0 : 1;    # abort if we are in middle of a rebase conflict
    };

    say "rebase status: ", $ok;

    return $ok;
}

sub in_rebase($self) {

    my $rebase_merge = $self->run(qw{rev-parse --git-path rebase-merge});
    return 1 if $rebase_merge && -d $rebase_merge;

    my $rebase_apply = $self->run(qw{rev-parse --git-path rebase-merge});
    return 1 if $rebase_apply && -d $rebase_apply;

    return 0;
}

1;
