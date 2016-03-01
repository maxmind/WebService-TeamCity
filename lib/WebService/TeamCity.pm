package WebService::TeamCity;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Cpanel::JSON::XS;
use Data::Visitor::Callback;
use HTTP::Request;
use LWP::UserAgent;
use String::CamelSnakeKebab qw( lower_snake_case );
use Try::Tiny;
use Types::Standard qw( ArrayRef InstanceOf Int Str );
use URI::FromHash qw( uri );
use URI;
use WebService::TeamCity::Build;
use WebService::TeamCity::BuildType;
use WebService::TeamCity::Iterator;
use WebService::TeamCity::Project;

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

has projects => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::Project'] ],
    lazy    => 1,
    builder => '_build_projects',
);

has build_types => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::BuildType'] ],
    lazy    => 1,
    builder => '_build_build_types',
);

has builds => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Iterator'],
    lazy    => 1,
    builder => '_build_builds',
);

with 'WebService::TeamCity::Inflator';

sub _build_projects {
    my $self = shift;

    my $projects = $self->response_for( path => 'projects' );

    return $self->_inflate_array( $projects->{project}, 'Project' );
}

sub _build_build_types {
    my $self = shift;

    my $types = $self->response_for( path => 'buildTypes' );

    return $self->_inflate_array( $types->{build_type}, 'BuildType' );
}

sub _build_builds {
    my $self = shift;

    my $builds = $self->response_for( path => 'builds' );

    return $self->_iterator_for(
        'builds',
        'build',
        'Build',
    );
}

sub client { $_[0] }

sub response_for {
    my $self = shift;
    my %args = @_;

    my $method = $args{method} // 'GET';
    my $uri = $self->_uri_for( $args{path} );

    my $request = HTTP::Request->new(
        $method => $uri,
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
    my $query = shift // {};

    $path = '/httpAuth/app/rest/' . $path
        unless $path =~ m{^/};

    my $base = uri(
        scheme => $self->scheme,
        host   => $self->host,
        ( $self->port ? ( port => $self->port ) : () ),
    );
    $base .= $path;

    return URI->new($base)->canonical;
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

=head2 $client->projects

Returns an array reference of L<WebService::TeamCity::Project> objects. This
contains all the projects defined on the TeamCity server.

=head2 $client->build_types

Returns an array reference of L<WebService::TeamCity::BuildTypes> objects. This
contains all the build types defined on the TeamCity server.

=head2 $client->builds

Returns a L<WebService::TeamCity::Iterator> which returns
L<WebService::TeamCity::Build> objects.

=cut
