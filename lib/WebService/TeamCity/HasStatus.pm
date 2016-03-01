package WebService::TeamCity::HasStatus;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( Bool Str );

use Moo::Role;

has status => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has passed => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { $_[0]->status eq 'SUCCESS' },
);

has failed => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub { $_[0]->status eq 'FAILURE' },
);

1;

# ABSTRACT: Role for any REST API object with a status
