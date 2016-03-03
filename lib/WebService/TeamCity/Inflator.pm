package WebService::TeamCity::Inflator;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use WebService::TeamCity::Iterator;

use Moo::Role;

requires 'client';

sub _inflate_array {
    my $self = shift;
    my $raw  = shift;

    return [] unless $raw;
    return [ map { $self->_inflate_one( $_, @_ ) } @{$raw} ];
}

sub _inflate_one {
    my $self     = shift;
    my $raw      = shift;
    my $class    = shift;
    my $self_key = shift;

    return unless $raw;

    return ( 'WebService::TeamCity::' . $class )->new(
        %{$raw},
        client => $self->client,
        ( $self_key ? ( $self_key => $self ) : () ),
    );
}

sub _iterator_for {
    my $self      = shift;
    my $uri       = shift;
    my $items_key = shift;
    my $class     = shift;

    my $raw = $self->client->response_for( uri => $uri );

    return WebService::TeamCity::Iterator->new(
        client    => $self->client,
        class     => 'WebService::TeamCity::' . $class,
        items_key => $items_key,
        ( $raw->{next_href} ? ( next_href => $raw->{next_href} ) : () ),
        items => $raw->{$items_key},
    );
}

1;

# ABSTRACT: Role for any class that inflates REST API objects from JSON
