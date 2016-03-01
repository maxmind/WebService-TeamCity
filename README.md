# NAME

WebService::TeamCity - Client for the TeamCity REST API

# VERSION

version 0.01

# SYNOPSIS

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

# DESCRIPTION

This distribution provides a client for the TeamCity REST API.

Currently, this client targets the TeamCity 9.1 release exclusively. It is
also quite incomplete and only supports read operations. Pull requests are
very welcome!

The entry point for the API is this module, `WebService::TeamCity`. Once you
have an object of that class, you can use it to get at various other objects
provided by the API.

# API

This module provides the top-level client for the API.

## WebService::TeamCity->new(...)

This method takes named parameters to construct a new TeamCity client.

- scheme

    The URL scheme to use. This defaults to `http`.

- host

    The host to connect to. Required.

- port

    The port to connect to. By default, this just uses whatever the scheme
    normally uses.

- user

    The username to use for authentication. Required.

- password

    The password to use for authentication. Required.

- ua

    An instance of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent). You can pass one in for testing and
    debugging purposes.

## $client->projects

Returns an array reference of [WebService::TeamCity::Project](https://metacpan.org/pod/WebService::TeamCity::Project) objects. This
contains all the projects defined on the TeamCity server.

## $client->build\_types

Returns an array reference of [WebService::TeamCity::BuildTypes](https://metacpan.org/pod/WebService::TeamCity::BuildTypes) objects. This
contains all the build types defined on the TeamCity server.

## $client->builds

Returns a [WebService::TeamCity::Iterator](https://metacpan.org/pod/WebService::TeamCity::Iterator) which returns
[WebService::TeamCity::Build](https://metacpan.org/pod/WebService::TeamCity::Build) objects.

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Dave Rolsky <drolsky@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
