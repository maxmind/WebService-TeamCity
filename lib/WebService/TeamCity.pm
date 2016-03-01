package WebService::TeamCity;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.01';

use Cpanel::JSON::XS;
use Data::Visitor::Callback;
use LWP::UserAgent;
use String::CamelSnakeKebab qw( lower_snake_case );
use Try::Tiny;
use Types::Standard qw( ArrayRef InstanceOf Int Str );
use URI::FromHash qw( uri );
use URI;
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
    builder => '_build_built_types',
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
