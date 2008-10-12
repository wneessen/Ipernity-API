# Iperntiy::API::Request
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id: API.pm,v 1.1 2008-10-12 14:07:56 doomy Exp $
# Last modified: [ 2008-10-12 15:53:14 ]

### Module definitions {{{
package Ipernity::API;
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Ipernity::API::Request;
use LWP::UserAgent;
use XML::Twig;

our @ISA = qw(LWP::UserAgent);
our $VERSION = '0.01';
# }}}

### Module constructor / new() {{{
sub new
{
	### Define class and object
	my $class = shift;
	my $self = new LWP::UserAgent;

	### Read arguments and assign them to my object
	my %args = @_;
	foreach my $key (keys %args) {
		$self->{$key} = $args{$key};
	}
	
	### For Ipernity we need an output format
	unless(defined($self->{args}->{outputformat})) {
		$self->{args}->{outputformat} = 'xml';
	}

	### We need an API key at least!
	warn qq(Please provide at least an API key) unless ($self->{args}->{api_key});

	### Reference object to class
	bless $self, $class;
	return $self;
}
# }}}

### Perform an API request / execute() {{{
sub execute
{
	### Get object
	my $self = shift;
	
	### Read arguments and assign them to my object
	my %args = @_;
	foreach my $key (keys %args) {
		$self->{request}->{$key} = $args{$key};
	};

	## Create a request object
	my $request = Ipernity::API::Request->new(%{$self->{request}});

	## Query the API object with the request
	$self->execute_request($request);
}
# }}}

### Execute the API request / execute_request() {{{
sub execute_request
{
	### Get object and request
	my $self = shift;
	my $request = shift;
	$request->{_uri}->path($request->{_uri}->path() .  $request->{args}->{method} . '/' . $self->{args}->{outputformat} );

	### Add API key and secret to the request
	$request->{args}->{api_key} = $self->{args}->{api_key};
	if($self->{args}->{secret}) {
		$request->{args}->{api_sig} = $self->signargs($request->{args});
	}

	### Encode the arguments and build a POST request
	$request->encode();

	### Call the API
	my $response = $self->request($request);

	### Return the response
	return $response;
}
# }}}

### Sign arguments for authenticated call // signargs() {{{
sub signargs
{
	### Get object
	my $self = shift;
	my $args = shift;
	my $signed_args;

	### Sort arguments
	foreach my $key (sort {$a cmp $b} keys %{$args}) {
		my $val = $args->{$key} ? $args->{$key} : '';
		next if ($key eq 'method');
		$signed_args .= $key . $val;
	}
	if(defined($args->{method})) {
		$signed_args .= $args->{method};
	}
	$signed_args .= $self->{args}->{secret};

	### Return as MD5 Hex hash
	return md5_hex($signed_args);
}
# }}}

### Fetch a Frob for the AuthToken request / fetchfrob() {{{
sub fetchfrob
{
	### Get object
	my $self = shift;
	my $frob = {};

	### Create an API request
	my $response = $self->execute(
		'method' => 'auth.getFrob',
	);

	my $xml = XML::Twig->new(
		TwigHandlers => {
			"/api/auth/frob" => sub { $frob = $_->text; },
			"/rsp/err" => \&Pixlr::ApiError,
		}
	);
	$xml->parse($response->{_content});

	### Return the frob
	return $frob;
}
# }}}

### Build an AuthToken request URL / authurl {{{
sub authurl
{
	### Get object
	my $self = shift;

	### Fetch arguments
	my (%args, $signed_args);
	$args{frob}	= shift;
	$args{perm_doc}	= shift;
	$args{api_key}	= $self->{args}->{api_key};

	### Sort arguments and add them to $api_sig
	foreach my $key (sort {$a cmp $b} keys %args) {
		my $val = $args{$key} ? $args{$key} : '';
		next if($key eq 'method');
		$signed_args .= $key . $val;
	}
	if(defined($args{method})) {
		$signed_args .= $args{method};
	}
	$signed_args .= $self->{args}->{secret};

	### Create MD5 hash out of the signed args
	my $api_sig = md5_hex($signed_args);

	### Decide wether Auth URL to use
	my $url = qq(http://www.ipernity.com/apps/authorize);

	### Build AuthURL
	my $authurl = $url . qq(?api_key=) . $self->{args}->{api_key} . qq(&frob=) . $args{frob} . qq(&perm_doc=) . $args{perm_doc} . qq(&api_sig=) . $api_sig;

	### Return the URL
	return $authurl;
}
# }}}

### Fetch the AuthToken / authtoken {{{
sub authtoken
{
	### Get object
	my ($token);
	my $self = shift;

	### Get arguments
	$self->{frob} = shift;

	### Request the AuthToken
	my $response = $self->execute(
		'method' => 'auth.getToken',
		'frob'	 => $self->{frob},
	);

	### Process the respose
	my $xml = XML::Twig->new(
		TwigHandlers => {
			"/api/auth/token" => sub { $token = $_->text; },
			"/rsp/err" => \&Pixlr::ApiError,
		}
	);
	$xml->parse($response->{_content});

	### Return the AuthToken
	return $token;
}
# }}}

1;
__END__
=head1 NAME

Ipernity::API - Perl interface to the Ipernity API

=head1 SYNOPSIS

use Ipernity::API

=head1 USAGE

use Ipernity::API;

my $api = Ipernity::API->new(
   'args'   => {
      'api_key'      => '12345678901234567890123456789012',
      'secret'       => '0123456789012345',
      'outputformat' => 'xml',
   }
);

my $result = $api->execute(
   'method'	=> 'test.hello',
);

my $frob = $api->fetchfrob();

my $authurl = $api->authurl($frob, 'read');

my $token = $api->authtoken($frob);

=back

=head1 DESCRIPTION

To be done.

=head1 AUTHOR

Winfried Neessen, E<lt>doomy@dokuleser.org<gt>

=head1 REQUIRES

Perl 5, URI, HTTP::Request, XML::Twig, LWP::UserAgent, Digest::MD5

=head1 COPYRIGHT and LICENCE

Copyright (c) 2008, Winfried Neessen <doomy@dokuleser.org>

Redistribution and use in source and binary forms, with or without
modification, is not permitted.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

$Id: API.pm,v 1.1 2008-10-12 14:07:56 doomy Exp $

=cut
