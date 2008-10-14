# Iperntiy::API::Request
#
# Contact: doomy [at] dokuleser [dot] org
# Copyright 2008 Winfried Neessen
#
# $Id: Request.pm,v 1.3 2008-10-14 21:05:30 doomy Exp $
# Last modified: [ 2008-10-14 23:04:48 ]

### Module definitions {{{
package Ipernity::API::Request;
use strict;
use warnings;
use HTTP::Request;
use URI;

our @ISA = qw(Ipernity::API HTTP::Request);
our $VERSION = '0.05';
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
	$self->header(qq(User-Agent) => qq(Ipernity::API v0.1));

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

Ipernity::API::Request - Request object for Ipernity::API

=head1 SYNOPSIS

use Ipernity::API::Request

=head1 DESCRIPTION

To be done.

=head1 AUTHOR

Winfried Neessen, E<lt>doomy@dokuleser.org<gt>

=head1 REQUIRES

Perl 5, URI, HTTP::Request

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

$Id: Request.pm,v 1.3 2008-10-14 21:05:30 doomy Exp $

=cut
