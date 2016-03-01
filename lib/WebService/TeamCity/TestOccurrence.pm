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

# ABSTRACT: A single TeamCity test occurrence

__END__

=pod

=head1 SYNOPSIS

    my $build = ...;
    my $tests = $build->test_occurrences;

    while ( my $test = $tests->next ) {
        print $test->name, "\n" if $test->failed;
    }

=head1 DESCRIPTION

This class represents a single TeamCity test occurrence.

=head1 API

This class has the following methods:

=head2 $test->href

Returns the REST API URI for the test occurrence, without the scheme and host.

=head2 $test->name

Returns the test occurrence's name.

=head2 $test->description

Returns the test occurrence's description.

=head2 $test->id

Returns the test occurrence's id string.

=head2 $test->status

Returns the test occurrence's status string.

=head2 $test->passed

Returns true if the test occurrence passed.

=head2 $test->failed

Returns true if the test occurrence failed.

=head2 $test->build

Returns the L<WebService::TeamCity::Build> for the test occurrence.

=head2 $test->duration

Returns the test's duration in milliseconds.

=head2 $test->details

Returns details about the test, if any exist. The contents of this field
depend on the details of how the build ran.

=cut
