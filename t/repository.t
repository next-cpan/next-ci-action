#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

#use Test2::Plugin::NoWarnings;

use Test::MockModule;

use action::std;
use action::Helpers qw{read_json_file write_json_file write_file};

use Cwd ();

use action::Git;

use File::Copy;
use File::Temp;
use File::Path qw(mkpath rmtree);
use File::pushd;

use action::Repository;

my $tmp = setup_test('test-maintainers');

my $in_tmp = pushd("$tmp");

my @default_teams = qw{ p5-bulk p5-admins };    # FIXME from config ?

{
    my $repo = action::Repository->new;
    ok $repo, "action::Repository->new;";

    my $maintainers = $repo->maintainers;

    is $maintainers->users, [], 'users empty when no .next/maintainers';
    is $maintainers->teams, [@default_teams], 'default teams when no .next/maintainers';
}

{
    mkpath(".next");
    write_file( ".next/maintainers", <<'EOS' );
## some comments
##

# teams from next-cpan
teams/blueteam
teams/redteam

# github user listed there
user1
user2
# a comment
user3

EOS

    my $repo = action::Repository->new;
    ok $repo, "action::Repository->new;";

    my $maintainers = $repo->maintainers;

    is $maintainers->users, [qw{user1 user2 user3}], 'users set from .next/maintainers';
    is $maintainers->teams, [ @default_teams, qw{blueteam redteam} ], 'teams set from .next/maintainers';

}

done_testing;
