package WebService::TeamCity::Entity::HasName;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( Str );

use Moo::Role;

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;

# ABSTRACT: Role for any REST API object with a name

