package WebService::TeamCity::Entity;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.02';

use DateTime;
use DateTime::Format::Strptime;
use Types::Standard qw( HashRef InstanceOf Str );

use Moo::Role;

has client => (
    is       => 'ro',
    isa      => InstanceOf ['WebService::TeamCity'],
    required => 1,
);

has href => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _full_data => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_full_data',
);

with 'WebService::TeamCity::Inflator';

sub _build_full_data {
    my $self = shift;

    my $uri = $self->client->base_uri;
    return $self->client->response_for( uri => $uri . $self->href );
}

my $parser = DateTime::Format::Strptime->new( pattern => '%Y%m%dT%H%M%S%z' );

sub _parse_datetime {
    return $parser->parse_datetime( $_[1] );
}

1;

# ABSTRACT: Role for anything addressable via the TeamCity REST API
