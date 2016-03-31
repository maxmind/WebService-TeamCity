package WebService::TeamCity;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.03';

use Cpanel::JSON::XS;
use Data::Visitor::Callback;
use HTTP::Request;
use LWP::UserAgent;
use String::CamelSnakeKebab qw( lower_snake_case );
use Try::Tiny;
use Type::Utils qw( class_type );
use Types::Standard qw( ArrayRef Bool Dict InstanceOf Int Optional Str );
use URI::FromHash qw( uri_object );
use URI::QueryParam;
use URI;
use WebService::TeamCity::Entity::Build;
use WebService::TeamCity::Entity::BuildType;
use WebService::TeamCity::Iterator;
use WebService::TeamCity::LocatorSpec;
use WebService::TeamCity::Entity::Project;
use WebService::TeamCity::Types qw( BuildStatus DateTimeObject );

use Moo;

has scheme => (
    is      => 'ro',
    isa     => Str,
    default => 'http',
);

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has port => (
    is  => 'ro',
    isa => Int,
);

has user => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has password => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf ['LWP::UserAgent'],
    lazy    => 1,
    default => sub { LWP::UserAgent->new },
);

has _json => (
    is      => 'ro',
    isa     => InstanceOf ['Cpanel::JSON::XS'],
    lazy    => 1,
    default => sub { Cpanel::JSON::XS->new },
);

with 'WebService::TeamCity::Inflator';

sub projects {
    my $self = shift;

    my $uri = $self->_uri_for('projects');
    my $projects = $self->response_for( uri => $uri );

    return $self->_inflate_array( $projects->{project}, 'Project' );
}

sub build_types {
    my $self = shift;

    my $uri = $self->_uri_for('buildTypes');
    my $types = $self->response_for( uri => $uri );

    return $self->_inflate_array( $types->{build_type}, 'BuildType' );
}

{
    my $check;

    sub builds {
        my $self = shift;

        $check ||= $self->_build_locator_spec->validator(
            include_paging_args => 1 );
        my ($args) = $check->(@_);

        my $path = 'builds';
        my %query;
        if (
            my $locator
            = $self->_build_locator_spec->locator_string_for_args(
                search_args         => $args,
                include_paging_args => 1,
            )
            ) {

            $query{locator} = $locator;
        }

        my $uri = $self->_uri_for( 'builds', \%query );
        return $self->_iterator_for(
            $uri,
            'build',
            'Build',
        );
    }
}

{
    my $build_locator_spec;

    sub _build_locator_spec {
        return $build_locator_spec ||= do {
            my $self = shift;

            my $project_spec = $self->_project_locator_spec;

            my %base = (
                affected_project => $project_spec,
                agent_name       => Str,
                branch           => Str,
                build_type       => $self->_build_type_locator_spec,
                canceled         => Bool,
                failed_to_start  => Bool,
                id               => Str,
                lookup_limit     => Int,
                number           => Int,
                personal         => Bool,
                pinned           => Bool,
                project          => $project_spec,
                running          => Bool,
                since_date       => DateTimeObject,
                status           => BuildStatus,
                tags             => ArrayRef [Str],
            );

            # We're not going to allow arbitrarily nested since_build build
            # specs.
            my $base_spec = WebService::TeamCity::LocatorSpec->new(
                name      => 'build base',
                type_spec => \%base,
            );

            return WebService::TeamCity::LocatorSpec->new(
                name      => 'build',
                type_spec => {
                    %base,
                    since_build => $base_spec,
                },
            );
        };
    }
}

{
    my $build_type_locator_spec;

    sub _build_type_locator_spec {
        return $build_type_locator_spec ||= do {
            my $self = shift;

            my $project_spec = $self->_project_locator_spec;

            my %base = (
                affected_project => $project_spec,
                id               => Str,
                name             => Str,
                paused           => Bool,
                project          => $project_spec,
                template_flag    => Bool,
            );

            # We're not going to allow arbitrarily nested template build
            # specs.
            my $base_spec = WebService::TeamCity::LocatorSpec->new(
                name      => 'build type base',
                type_spec => \%base,
            );

            return WebService::TeamCity::LocatorSpec->new(
                name      => 'build type',
                type_spec => {
                    %base,
                    template => $base_spec,
                },
            );
        };
    }
}

{
    my $project_locator_spec;

    sub _project_locator_spec {
        return $project_locator_spec
            ||= WebService::TeamCity::LocatorSpec->new(
            name      => 'project',
            type_spec => {
                id   => Str,
                name => Str,
            },
            );
    }
}

sub client { $_[0] }

sub response_for {
    my $self = shift;
    my %args = @_;

    my $method = $args{method} // 'GET';

    my $request = HTTP::Request->new(
        $method => $args{uri},
        [ Accept => 'application/json' ],
    );
    $request->authorization_basic( $self->user, $self->password );

    my $response = $self->ua->request($request);
    unless ( $response->is_success ) {
        die '['
            . scalar(localtime)
            . '] Error response:' . "\n\n"
            . $response->as_string
            . "\nFor the request:\n\n"
            . $request->as_string;
    }

    unless ( $response->content_type =~ /json/ ) {
        die 'Expected a JSON response but got '
            . $response->content_type
            . ' instead'
            . "\nFor the request:\n\n"
            . $request->as_string;
    }

    my $json = try {

        # HTTP::Message will handle Content-Encoding (gzip, etc) for us. It
        # will not actually decode to UTF-8 for application/json responses.
        $self->_json->decode( $response->decoded_content );
    }
    catch {
        die 'Invalid JSON in response: '
            . $response->decoded_content
            . "\nFor the request:\n\n"
            . $request->as_string;
    };

    return $self->_decamelize_keys($json);
}

sub _uri_for {
    my $self  = shift;
    my $path  = shift // die 'No path given';
    my $query = shift;

    $path = '/httpAuth/app/rest/' . $path
        unless $path =~ m{^/};

    my $uri = $self->base_uri;
    $uri->path($path);
    $uri->query_form_hash($query) if $query && %{$query};

    return $uri->canonical;
}

sub base_uri {
    my $self = shift;

    return uri_object(
        scheme => $self->scheme,
        host   => $self->host,
        ( $self->port ? ( port => $self->port ) : () ),
    );
}

sub _decamelize_keys {
    my $self = shift;
    my $json = shift;

    return Data::Visitor::Callback->new(
        hash => sub {
            shift;
            my $node = shift;
            for my $k ( keys %{$node} ) {
                $node->{ lower_snake_case($k) } = delete $node->{$k};
            }
            return $node;
        },
    )->visit($json);
}

1;

# ABSTRACT: Client for the TeamCity REST API

__END__

=pod

=for Pod::Coverage response_for

=head1 SYNOPSIS

    use WebService::TeamCity;

    my $client = WebService::TeamCity->new(
        scheme   => 'https',
        host     => 'tc.example.com',
        port     => 8123,
        user     => 'tc-user',
        password => 'tc-password',
    );

    my $projects = $client->projects;
    for my $project ( @{$projects} ) {
        say $project->id;
        for my $build_type ( @{ $project->build_types } ) {
            say $build_type->id;
        }
    }

    my $projects = $client->projects;
    for my $project ( @{$projects} ) {
        ...;
    }

=head1 DESCRIPTION

This distribution provides a client for the TeamCity REST API.

Currently, this client targets the TeamCity 9.1 release exclusively. It is
also quite incomplete and only supports read operations. Pull requests are
very welcome!

The entry point for the API is this module, C<WebService::TeamCity>. Once you
have an object of that class, you can use it to get at various other objects
provided by the API.

=head1 INSTABILITY WARNING

This distribution is still in its early days and its API may change without
warning in future releases.

=head1 API

This module provides the top-level client for the API.

=head2 WebService::TeamCity->new(...)

This method takes named parameters to construct a new TeamCity client.

=over 4

=item * scheme

The URL scheme to use. This defaults to C<http>.

=item * host

The host to connect to. Required.

=item * port

The port to connect to. By default, this just uses whatever the scheme
normally uses.

=item * user

The username to use for authentication. Required.

=item * password

The password to use for authentication. Required.

=item * ua

An instance of L<LWP::UserAgent>. You can pass one in for testing and
debugging purposes.

=back

=head2 $client->projects(...)

Returns an array reference of L<WebService::TeamCity::Entity::Project>
objects. This contains all the projects defined on the TeamCity server.

You can pass arguments as key/value pairs to limit the projects returned:

=over 4

=item * id => Str

Only return projects matching this id.

=item * name => Str

Only return projects matching this name.

=back

=head2 $client->build_types

Returns an array reference of L<WebService::TeamCity::Entity::BuildType>
objects. This contains all the build types defined on the TeamCity server.

You can pass arguments as key/value pairs to limit the build types returned:

=over 4

=item * affected_project => { ... }

Only return build types which affect the specified project. Projects can be
specified as defined for the C<projects> method. This includes sub-projects of
the specified project.

=item * id => Str

Only return build types matching this id.

=item * name => Str

Only return build types matching this name.

=item * paused => Bool

Only return build types which are or are not paused.

=item * project => { ... }

Only return build types which affect the specified project. Projects can be
specified as defined for the C<projects> method. This only includes the
project itself, not its sub-projects.

=item * template => { ... }

Only return build types which use the specified template. The template is
defined the same way as a build type, but you cannot include a C<template> key
for the template spec too.

=item * template_flag => Bool

Only return build types which are or are not templates.

=back

=head2 $client->builds

Returns a L<WebService::TeamCity::Iterator> which returns
L<WebService::TeamCity::Entity::Build> objects.

You can pass arguments as key/value pairs to limit the projects returned:

=over 4

=item * affected_project => { ... }

Only return builds which affect the specified project. Projects can be
specified as defined for the C<projects> method. This includes sub-projects of
the specified project.

=item * agent_name => Str

Only return builds which used the specified agent.

=item * branch => Str

Only return builds which were built against the specified branch.

=item * build_type => { ... }

Only return builds which were built using the specific build type. Build types
can be specified as defined for the C<build_types> method.

=item * canceled => Bool

Only returns builds which were or were not canceled.

=item * failed_to_start => Bool

Only returns builds which did or did not fail to start.

=item * id => Str

Only return builds matching this id.

=item * lookup_limit => Int

Only search the most recent N builds for a matching build.

=item * name => Str

Only return builds matching this name.

=item * number => Str

Only return builds matching this number.

=item * personal => Bool

Only returns builds which are or are not marked as personal builds.

=item * pinned => Bool

Only returns builds which are or are not pinned.

=item * project => { ... }

Only return builds which affect the specified project. Projects can be
specified as defined for the C<projects> method. This only includes the
project itself, not its sub-projects.

=item * running => Bool

Only returns builds which are or are not running.

=item * since_date => DateTime

Only returns builds started on or after the specified datetime.

=item * status => Str

Only returns builds with the specified status. This can be one of C<SUCCESS>,
C<FAILURE>, or C<ERROR>.

=item * tags => [ ... ]

Only returns builds which match I<all> of the specified tags. Tags are given
as strings.

=back

=cut
