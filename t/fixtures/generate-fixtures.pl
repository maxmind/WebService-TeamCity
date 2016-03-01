use v5.20;
use strict;
use warnings;
use autodie;

use Cpanel::JSON::XS qw( decode_json );
use Data::Visitor::Callback;
use HTTP::Cookies;
use HTTP::Headers;
use LWP::UserAgent;
use Path::Class qw( dir );
use URI;

my $dir      = dir('t/fixtures');
my $uri_base = 'https://teamcity.jetbrains.com';
my @uris     = map { URI->new( $uri_base . $_ ) } (
      @ARGV
    ? @ARGV
    : qw(
        /httpAuth/app/rest/projects
        /httpAuth/app/rest/buildTypes
        )
);

my $h = HTTP::Headers->new;
$h->header( 'Accept' => 'application/json' );
my $ua = LWP::UserAgent->new(
    cookie_jar      => HTTP::Cookies->new,
    default_headers => $h,
);

$ua->get( $uri_base . '?guest=1' );

my %seen;
for my $uri (@uris) {
    say $uri or die;
    my $res = $ua->get($uri);
    unless ( $res->is_success ) {
        say $res->content or die;
        next;
    }

    $seen{$uri} = 1;

    my $path = $uri =~ s{^\Q$uri_base\E(?:/httpAuth)?/app/rest/}{}r;
    $path =~ s{/$}{};

    my $file = $dir->file( $path . '.json' );

    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    $file->parent->mkpath( 0, 0755 );
    ## use critic

    my $raw = $res->decoded_content;
    $file->spew($raw);

    next if $uri =~ /\.zip$/;

    my $json = decode_json($raw);
    Data::Visitor::Callback->new(
        hash => sub {
            shift;
            my $node = shift;

            return $node unless $node->{href};

            my $uri = URI->new( $uri_base . $node->{href} );
            return $node if $seen{$uri};
            return
                if $uri =~ m{/rest/projects/id:}
                && $uri !~ /id:(?:_Root|TeamCityPluginsByJetBrains_Git)/;

            return
                if $uri =~ m{/rest/buildTypes/id:}
                && $uri
                !~ /id:(?:TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x)/;

            return
                if $uri =~ m{/rest/builds/id:}
                && $uri !~ m{/rest/builds/id:(?:667885|666188|661984)};

            push @uris, $uri;
            return $node;
        },
    )->visit($json);
}
