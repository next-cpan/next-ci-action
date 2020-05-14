##
## list dependencies used for running Tests on CI

# cannot be used on Alpine
#requires 'Net::GitHub::V3'  => '1.01';

on test => sub {
	requires 'Test::More';
	requires 'Test2::Harness::Util::IPC';
};
