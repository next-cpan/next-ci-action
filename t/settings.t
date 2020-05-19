#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use action::std;
use action::Helpers qw{read_json_file write_json_file write_file};

use Cwd ();

use File::Temp;
use File::Path qw(mkpath rmtree);
use File::pushd;

use action::Settings;

my $tmp = File::Temp->newdir();

{
    my $cfg = <<'END';
name: "A test"

git:
  user:
    email: 'actions@github.com'
    name: 'GitHub Play Action'

github:
  org: 'next-cpan'
  monitor_repo: 'next-monitor'

maintainers:
  file: ./next/maintainers
  team: maintainers
  default_maintenance_teams:
    - "p5-bulk"
    - "p5-admins"

pull_requests:
  # how many days before an issue is automatically merged in
  stale_after_x_days: 7
END

    my $indir = pushd("$tmp");
    write_file( 'test.yml', $cfg );

    my $settings = action::Settings->new( file => 'test.yml' );
    isa_ok $settings, 'action::Settings';

    is $settings->get('name'), 'A test', 'get name';

    is $settings->get( git => user => 'email' ), 'actions@github.com', '.github.user.email';
    is $settings->get( git => user => email => ), 'actions@github.com', '.github.user.email =>';

    is $settings->get( github => ), { org => 'next-cpan', monitor_repo => 'next-monitor' }, '.github =>';

    is $settings->get( github => 'not_there' ), undef, '.github.not_there is undef';

    like(
        dies { $settings->get( github => 'not_there' => 'boom' ) },
        qr/Cannot access to Settings github -> not_there -> boom/m,
        "dies when accessing multi level missing key"
    );

    like(
        dies { action::Settings->new( file => 'missing.yml' ); },
        qr/Could not open 'missing.yml' for reading/m,
        "dies when creating object with missing file"
    );

}

done_testing;
