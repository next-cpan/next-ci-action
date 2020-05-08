##
##

requires 'Simple::Accessor' => '1.13';
requires 'JSON::PP'         => 0;
requires 'Exporter'         => '5.59';
requires 'HTTP::Tinyish'    => 0;
requires 'File::pushd'      => 0;
requires 'File::Which'      => 0;
requires 'File::Basename'   => 0;
requires 'Umask::Local'     => 0;

on test => sub {
	requires 'Test::More';
};