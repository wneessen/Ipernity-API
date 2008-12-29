# Iperntiy::API
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id: API.pm,v 1.7 2008-12-29 19:49:19 doomy Exp $
# Last modified: [ 2008-12-29 20:42:54 ]

### Module definitions {{{
package Ipernity::API;
use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5_hex);
use Ipernity::API::Request;
use LWP::UserAgent;
use XML::Simple;

our @ISA = qw(LWP::UserAgent);
our $VERSION = '0.06';
# }}}

### Module constructor / new() {{{
sub new
{
	### Define class and object
	my $class = shift;
	my $self = new LWP::UserAgent;

	### Read arguments and assign them to my object
	my $args = shift;
	foreach my $key (keys %{$args}) {
		$self->{args}->{$key} = $args->{$key};
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

### Execute the API request and return a XML object / execute_hash() {{{
sub execute_hash()
{
	### Get object and request
	my $self = shift;
	my %args = @_;
	my $oldformat;

	### For XML output we need to force XML outputformat
	if(lc($self->{args}->{outputformat}) ne 'xml') {
		$oldformat = $self->{args}->{outputformat};
		$self->{args}->{outputformat} = 'xml';
	}

	### Execute the request
	my $response = $self->execute(%args)->{_content};

	### Generate a hashref out of the XML tree
	my $xml = new XML::Simple;
	my $xmlresult = $xml->XMLin(
		$response, 
		ForceContent => 1
	);

	### Check the status of the request
	CheckResponse($xmlresult);

	## Restore old outputformat
	if(defined($oldformat)) {
		$self->{args}->{outputformat} = $oldformat;
	}

	### Return the hash
	return $xmlresult;
}
# }}}

### Information placeholder for execute_xml / execute_xml() {{{
sub execute_xml()
{
	return "execute_xml() has been renamed to execute_hash()";
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
	my $response = $self->execute_hash(
		'method' => 'auth.getFrob',
	);

	### Return the frob
	return $response->{auth}->{frob}->{content};
}
# }}}

### Build an AuthToken request URL / authurl {{{
sub authurl
{
	### Get object
	my $self = shift;

	### Fetch arguments
	my $signed_args;
	my %args = @_;
	$args{api_key}	= $self->{args}->{api_key};

	### Lets put the permissions into the main hash
	foreach my $permkey (%{$args{perms}}) {
		$args{$permkey} = $args{perms}->{$permkey};
	}
	delete($args{perms});

	### Sort arguments and add them to $api_sig
	foreach my $key (sort {$a cmp $b} keys %args) {
		next unless(defined($args{$key}));
		next if($key eq 'method');
		my $val = $args{$key} ? $args{$key} : '';
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
	my $authurl = $url . qq(?api_key=) . $args{api_key};
	if(defined($args{frob})) {
		$authurl .= qq(&frob=) . $args{frob};
	}
	foreach my $permission (keys %args) {
		$authurl .= qq(&) . $permission . qq(=) . $args{$permission} if($permission =~ /^perm_/);
	}
	$authurl .= qq(&api_sig=) . $api_sig;

	### Return the URL
	return $authurl;
}
# }}}

### Fetch the AuthToken / authtoken {{{
sub authtoken
{
	### Get object
	my $self = shift;

	### Get arguments
	my $frob = shift;

	### Create an API request
	my $response = $self->execute_hash(
		'method' => 'auth.getToken',
		'frob'	 => $frob,
	);

	### Let's safe the auth token and user information
	$self->{auth}->{authtoken} = $response->{auth}->{token}->{content};
	$self->{auth}->{realname}  = $response->{auth}->{user}->{realname};
	$self->{auth}->{userid}    = $response->{auth}->{user}->{user_id};
	$self->{auth}->{username}  = $response->{auth}->{user}->{username};

	### Return the AuthToken
	return $response->{auth}->{token}->{content};
}
# }}}

### Check the API status code and return an error if unsuccessfull // CheckResponse() {{{
sub CheckResponse
{
	### Get the XML hashref
	my $xmlhash = shift;

	### Get the status;
	my ($code, $msg);
	my $status = $xmlhash->{'status'};

	### We caught an error - let's die!
	if(lc($status) ne 'ok') {
		$code = $xmlhash->{code};
		$msg  = $xmlhash->{message};
		croak("An API call caught an unexpected error: " . $msg . " (Error Code: " . $code . ")");
	}

	### Everything is fine
	return;
}
# }}}

1;
__END__

=head1 NAME

Ipernity::API - Perl interface to the Ipernity API

=head1 SYNOPSIS

	use Ipernity::API;
	
	my $api = Ipernity::API->new({
		'api_key'	=> '12345678901234567890123456789012',
		'secret'	=> '0123456789012345',
		'outputformat'	=> 'xml',
	});

	my $raw_response = $api->execute(
		'method'	=> 'test.hello',
	);

	my $hash = $api->execute_hash(
		'method'	=> 'test.hello',
		'auth_token'	=> '12345-123-1234567890',
	);
	
	my $frob = $api->fetchfrob();

	my $authurl = $api->authurl(
		'frob'		=> $frob,
		'perms'		=> {
			'perm_doc'	=> 'read',
			'perm_network'	=> 'write',
			'perm_blog'	=> 'delete',
		},
	};

	my $token = $api->authtoken( $frob );

	### After fetching the authtoken, all useful user information are
	### stored in the $api->{auth} section for later usage

	my $username  = $api->{auth}->{username};
	my $user_id   = $api->{auth}->{userid};
	my $realname  = $api->{auth}->{realname};
	my $authtoken = $api->{auth}->{authtoken};

=head1 DESCRIPTION

To be done.

=head1 AUTHOR

Winfried Neessen, E<lt>doomy@dokuleser.org<gt>

=head1 REQUIRES

Perl 5, URI, HTTP::Request, XML::Simple, LWP::UserAgent, Digest::MD5

=head1 BUGS

Please report bugs in the CPAN bug tracker.

=head1 COPYRIGHT

Copyright (C) 2008 by Winfried Neessen. Published under the terms of the Artistic
License 2.0.

=cut
