package WebService::TeamCity::Entity::HasDescription;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.05';

use Types::Standard qw( Str );

use Moo::Role;

has description => (
    is  => 'ro',
    isa => Str,
);

1;

# ABSTRACT: Role for any REST API object with a description
