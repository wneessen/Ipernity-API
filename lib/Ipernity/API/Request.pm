# Iperntiy::API::Request
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id: Request.pm,v 1.4 2008-12-29 19:49:19 doomy Exp $
# Last modified: [ 2008-12-29 20:44:57 ]

### Module definitions {{{
package Ipernity::API::Request;
use strict;
use warnings;
use HTTP::Request;
use URI;

our @ISA = qw(Ipernity::API HTTP::Request);
our $VERSION = '0.06';
# }}}

### Module constructor {{{
sub new
{
	### Define class and object
	my $class = shift;
	my $self = new HTTP::Request;
	$self->{api_sig} = {};

	### Some static definitions
	$self->method(qq(POST));
	$self->uri(qq(http://api.ipernity.com/api/));
	$self->header(qq(User-Agent) => qq(Ipernity::API v0.2));

	### Read arguments and assign them to my object
	my %args = @_;
	foreach my $key (keys %args) {
		$self->{args}->{$key} = $args{$key};
	}
	
	### We need a method to call at least!
	warn qq(Please provide at least a calling method) unless ($self->{args}->{method});

	### Reference object to class
	bless $self, $class;
	return $self;
}
# }}}

### Encode arguements and build a HTTP request // encode() {{{
sub encode
{
	### Get objects
	my $self = shift;

	### Build an URI object
	my $uri = URI->new(qq(http:));

	### Build an HTTP valid request URI
	delete($self->{args}->{method});
	$uri->query_form($self->{args});
	my $content = $uri->query;
	my $length = length($content);

	### Add POST fields to HTTP header
	$self->header(qq(Content-Type) => qq(application/x-www-form-urlencoded));
	if($content) {
		$self->header(qq(Content-Length) => $length);
		$self->content($content);
	}
}
# }}}


1;
__END__
=head1 NAME

Ipernity::API::Request

=head1 SYNOPSIS

To be invoked via Ipernity::API

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
