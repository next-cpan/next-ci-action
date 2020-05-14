#1perl

use 5.010000;

use strict;
use warnings;
use Test::More;

my @modules;

BEGIN {
    my @pms = qx{find lib -iname '*.pm'};

    foreach my $pm (@pms) {
        chomp $pm;
        $pm =~ s{^lib/}{};
        $pm =~ s{/}{::}g;
        $pm =~ s{\.pm$}{};

        push @modules, $pm;
    }
}

plan tests => scalar @modules + 1;

ok scalar @modules, "testing some modules";

foreach my $m (@modules) {
    use_ok($m) or diag "Cannot load $m";
}

diag("Testing action Perl $], $^X");

done_testing;
