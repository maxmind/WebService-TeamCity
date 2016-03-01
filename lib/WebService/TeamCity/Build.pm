package WebService::TeamCity::Build;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( Bool InstanceOf Maybe Str );
use WebService::TeamCity::BuildType;
use WebService::TeamCity::Iterator;
use WebService::TeamCity::TestOccurrence;

use Moo;

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
            $_[0]->_full_data->{test_occurrences}{href},
            'test_occurrence',
            'TestOccurrence',
        );
    },
);

has default_branch => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has branch_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
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
