package WebService::TeamCity::BuildType;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( InstanceOf Maybe Str );
use WebService::TeamCity::Build;
use WebService::TeamCity::Iterator;

use Moo;

has project => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Project'],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_one(
            'Project',
            $_[0]->_full_data->{project},
        );
    },
);

has template => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf [__PACKAGE__] ],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_one(
            'Project',
            $_[0]->_full_data->{template},
        );
    },
);

has builds => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Iterator'],
    lazy    => 1,
    default => sub {
        $_[0]->_iterator_for(
            $_[0]->_full_data->{builds}{href},
            'build',
            'Build',
        );
    },
);

# has vcs_root_entries

# has settings

# has parameters

# has steps

# has features

# has triggers

# has snapshot_dependencies

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::HasDescription',
    'WebService::TeamCity::HasID',
    'WebService::TeamCity::HasName',
    'WebService::TeamCity::HasWebURL',
);

1;
