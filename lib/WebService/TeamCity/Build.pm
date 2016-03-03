package WebService::TeamCity::Build;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( Bool Maybe InstanceOf Str );
use WebService::TeamCity::BuildType;
use WebService::TeamCity::Iterator;
use WebService::TeamCity::TestOccurrence;
use WebService::TeamCity::Types qw( BuildStatus );

use Moo;

has status => (
    is       => 'ro',
    isa      => BuildStatus,
    required => 1,
);

has build_type => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::BuildType'],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_one(
            $_[0]->_full_data->{build_type},
            'BuildType',
        );
    },
);

has test_occurrences => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Iterator'],
    lazy    => 1,
    default => sub {
        $_[0]->_iterator_for(
                  $_[0]->client->base_uri
                . $_[0]->_full_data->{test_occurrences}{href},
            'test_occurrence',
            'TestOccurrence',
        );
    },
);

has branch_name => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_branch_name',
);

has default_branch => (
    is        => 'ro',
    isa       => Bool,
    predicate => 'has_default_branch',
);

has number => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has state => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has queued_date => (
    is      => 'ro',
    isa     => InstanceOf ['DateTime'],
    lazy    => 1,
    default => sub {
        $_[0]->_parse_datetime( $_[0]->_full_data->{queued_date} );
    },
);

has start_date => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['DateTime'] ],
    lazy    => 1,
    default => sub {
        my $full = $_[0]->_full_data;
        return unless $full->{start_date};
        $_[0]->_parse_datetime( $full->{start_date} );
    },
);

has finish_date => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['DateTime'] ],
    lazy    => 1,
    default => sub {
        my $full = $_[0]->_full_data;
        return unless $full->{finish_date};
        $_[0]->_parse_datetime( $full->{finish_date} );
    },
);

# has artifacts_dir => (
#     is      => 'ro',
#     isa     => InstanceOf ['Path::Tiny'],
#     lazy    => 1,
#     builder => '_build_artifacts_dir',
# );

# has statistics

# has properties

# has related_issues

# has agent

# has revisions

# has changes

# has triggered

# has last_changes

# has problem_occurences

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::HasID',
    'WebService::TeamCity::HasStatus',
    'WebService::TeamCity::HasWebURL',
);

# sub _build_artifacts_dir {
#     ...;
# }

1;

# ABSTRACT: A single TeamCity build

__END__

=pod

=head1 SYNOPSIS

    my $build = ...;

    if ( $build->passed ) { ... }

=head1 DESCRIPTION

This class represents a single TeamCity build.

=head1 API

This class has the following methods:

=head2 $build->href

Returns the REST API URI for the build, without the scheme and host.

=head2 $build->id

Returns the build's id string.

=head2 $build->status

Returns the build's status string.

=head2 $build->passed

Returns true if the build passed. Note that both both C<passed> and C<failed>
can return false if the build is not yet finished.

=head2 $build->failed

Returns true if the build failed. Note that both both C<passed> and C<failed>
can return false if the build is not yet finished.

=head2 $build->web_url

Returns a browser-friendly URI for the build.

=head2 $build->build_type

Returns the L<WebService::TeamCity::BuildType> object for this build's type.

=head2 $build->test_occurrences

Returns a L<WebService::TeamCity::Iterator> for each of the build's test
occurrences. The iterator returns L<WebService::TeamCity::TestOccurrence>
objects.

=head2 $build->branch_name

Returns the branch name for this build. Note that this might be C<undef>.

=head2 $build->has_branch_name

Returns true if there is a branch associated with the build.

=head2 $build->default_branch

Returns true or false indicating whether the build used the default branch.

=head2 $build->has_default_branch

Returns true or false indicating whether there is any information about the
default branch. Builds can exist without an associated branch, in which case
this returns false.

=head2 $build->number

Returns the build's build number (which can actually be a string).

=head2 $build->state

Returns a string describing the build's state.

=head2 $build->queued_date

Returns a L<DateTime> object indicating when the build was queued.

=head2 $build->start_date

Returns a L<DateTime> object indicating when the build was started. If the
build has not yet been started then this returns C<undef>.

=head2 $build->finish_date

Returns a L<DateTime> object indicating when the build was finished. If the
build has not yet been finished then this returns C<undef>.

=cut
