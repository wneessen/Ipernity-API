#!/usr/bin/perl -w
# Iperntiy::API test suite
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id$
# Last modified: [ 2010-12-05 14:32:21 ]

use Test::More tests => 5;
use lib ( 'blib/lib', 'lib/', 'lib/Ipernity' );
use Ipernity::API;

## Define Ipernity::API object {{{
my $api = Ipernity::API->new(
	{
		'api_key'	=> '76704c8b0000271B6df755a656250e26',
		'outputformat'	=> 'xml',
	}
);
# }}}

## Check if object has been defined {{{
ok( defined( $api ), 'Ipernity::API object successfully created' );
ok( $api->isa( 'Ipernity::API' ), 'Object is an Ipernity::API object' );
# }}}

## Execute API call (skip if user doesn't have internet connectivity) {{{
print "\nIpernity::API would like to execute an API call. This requires internet connectivity.\n";
print "Would you like to run this test now? (Y/N) [n]: ";
my $runit = <STDIN>;
chomp( $runit );
print "\n";

SKIP: {

	## Define skip condition
	skip( '// User requested to skil API call', 3 ) if( defined( $runit ) and lc( $runit ) ne 'y' );

	## Send test.hello API call {{{
	my $hello = $api->execute_hash(
		'method'	=> 'test.hello',
	);
	# }}}

	## Check if API response is ok {{{
	ok( defined( $hello ), 'test.hello API call produced an answer' );
	is( $hello->{ 'status' }, 'ok', 'Ipernity API status is \'ok\'' );
	is( $hello->{ 'hello' }->[0]->{ 'content' }, 'hello world!', 'Ipernity API anwered with "hello world!"' );
	# }}}
	
}
# }}}
