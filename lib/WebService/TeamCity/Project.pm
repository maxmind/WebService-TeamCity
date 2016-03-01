package WebService::TeamCity::Project;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Types::Standard qw( ArrayRef Bool InstanceOf Maybe Str );
use WebService::TeamCity::BuildType;
use WebService::TeamCity::Project;

use Moo;

has archived => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has parent_project => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf [__PACKAGE__] ],
    lazy    => 1,
    builder => '_build_parent_project',
);

has child_projects => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf [__PACKAGE__] ],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_array(
            $_[0]->_full_data->{projects}{project},
            'Project',
            'parent_project',
        );
    },
);

has build_types => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::BuildType'] ],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_array(
            $_[0]->_full_data->{build_types}{build_type},
            'BuildType',
            'project',
        );
    },
);

has templates => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::BuildType'] ],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_array(
            $_[0]->_full_data->{templates}{build_type},
            'BuildType',
            'project',
        );
    },
);

# has parameters => (
#     is      => 'ro',
#     isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::Parameter'] ],
#     lazy    => 1,
#     default => sub {
#         $_[0]->_inflate_array(
#             'Parameter',
#             $_[0]->_full_data->{projects}{parameters},
#         );
#     },
# );

# has vcs_roots => (
#     is      => 'ro',
#     isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::VCSRoot'] ],
#     lazy    => 1,
#     default => sub {
#         $_[0]->_inflate_array(
#             'VCSRoot',
#             $_[0]->_full_data->{projects}{vcs_roots},
#         );
#     },
# );

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::HasDescription',
    'WebService::TeamCity::HasID',
    'WebService::TeamCity::HasName',
    'WebService::TeamCity::HasWebURL',
);

sub _build_parent_project {
    my $self = shift;

    my $full_data = $self->_full_data;
    return unless $full_data->{parent_project};

    return $self->_inflate_one(
        $full_data->{parent_project},
        'Project',
    );
}

1;
