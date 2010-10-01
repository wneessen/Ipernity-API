# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ipernity-API.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use lib ( 'blib/lib' );

BEGIN { use_ok('Ipernity::API') };

#########################

my $api = Ipernity::API->new({
	'api_key'       => '76704c8b0000271B6df755a656250e26',
	'outputformat'  => 'xml',
});
my $result = $api->execute_hash(
	'method'        => 'test.hello',
);
ok($result->{hello}->{content} =~ m/hello world/, 'test.hello');
