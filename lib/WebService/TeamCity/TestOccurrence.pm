package WebService::TeamCity::TestOccurrence;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( InstanceOf Int Str );

use Moo;

has duration => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has build => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Build'],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_one(
            $_[0]->_full_data->{build},
            'Build',
        );
    },
);

has details => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { $_[0]->_full_data->{details} },
);

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::HasID',
    'WebService::TeamCity::HasName',
    'WebService::TeamCity::HasStatus',
);

1;
