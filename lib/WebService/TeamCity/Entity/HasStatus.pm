package WebService::TeamCity::Entity::HasStatus;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.05';

use Types::Standard qw( Bool );
use WebService::TeamCity::Types qw( JSONBool );

use Moo::Role;

requires 'status';

has passed => (
    is      => 'ro',
    isa     => Bool | JSONBool,
    lazy    => 1,
    default => sub { $_[0]->status eq 'SUCCESS' },
);

has failed => (
    is      => 'ro',
    isa     => Bool | JSONBool,
    lazy    => 1,
    default => sub { $_[0]->status eq 'FAILURE' },
);

1;

# ABSTRACT: Role for any REST API object with a status
