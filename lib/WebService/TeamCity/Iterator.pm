package WebService::TeamCity::Iterator;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( ArrayRef HashRef InstanceOf Int Str );

use Moo;

has client => (
    is       => 'ro',
    isa      => InstanceOf ['WebService::TeamCity'],
    required => 1,
);

has class => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has items_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _next_href => (
    is        => 'rw',
    isa       => Str,
    init_arg  => 'next_href',
    predicate => '_has_next_href',
    clearer   => '_clear_next_href',
);

has _items => (
    is       => 'ro',
    isa      => ArrayRef [HashRef],
    init_arg => 'items',
    required => 1,
);

has _i => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub next {
    my $self = shift;

    my $items = $self->_items;
    my $i     = $self->_i;

    if ( $i >= @{$items} ) {
        $self->_fetch_more
            or return;
    }
    my $obj = $self->class->new(
        client => $self->client,
        %{ $items->[$i] },
    );
    $self->_i( $i + 1 );

    return $obj;
}
## use critic

sub _fetch_more {
    my $self = shift;

    return 0 unless $self->_has_next_href;

    my $raw = $self->client->response_for( path => $self->_next_href );

    push @{ $self->_items }, @{ $raw->{ $self->items_key } };

    if ( $raw->{next_href} ) {
        $self->_next_href( $raw->{next_href} );
    }
    else {
        $self->_clear_next_href;
    }

    return 1;
}

1;
