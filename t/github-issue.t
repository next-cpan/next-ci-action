#!perl

use FindBin;
use lib $FindBin::Bin . '/lib';
use lib $FindBin::Bin . '/../fatlib';

use TestHelpers;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use action::GitHub::Issue;

my $issue = action::GitHub::Issue->new( github_repository => 'a/b', id => 42 );

is $issue->github_repository, 'a/b', 'github_repository';
is $issue->id,                42,    'id';

done_testing;
