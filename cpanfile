##
##

## TODO: consider provide a snapshot of them
#	to avoid installing them from upstream

requires 'Simple::Accessor' => '1.13';
requires 'JSON::PP'         => 0;
requires 'Exporter'         => '5.59';
requires 'HTTP::Tinyish'    => 0;
requires 'File::pushd'      => 0;
requires 'File::Which'      => 0;
requires 'File::Basename'   => 0;
requires 'Umask::Local'     => 0;

requires 'Net::GitHub::V3'  => '1.01';

on test => sub {
	requires 'Test::More';
};