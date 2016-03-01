package WebService::TeamCity::HasDescription;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use DateTime;
use DateTime::Format::RFC3339;
use Types::Standard qw( Str );

use Moo::Role;

has description => (
    is  => 'ro',
    isa => Str,
);

1;
