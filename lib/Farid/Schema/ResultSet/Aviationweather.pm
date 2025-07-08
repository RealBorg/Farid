use utf8;
package Farid::Schema::ResultSet::Aviationweather;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';
use feature 'signatures';
use URI;
use LWP::UserAgent;

use constant {
    DEFAULT_STATION => 'LOWW',
    METAR_CACHE_TIME => 6 * 60,
    METAR_URL => 'https://aviationweather.gov/api/data/metar',
    TAF_CACHE_TIME => 60 * 60,
    TAF_URL => 'https://aviationweather.gov/api/data/taf',
};

sub metar ($self, $station = DEFAULT_STATION()) {
    my $metar = $self->search(
        {
            id => $station,
            type => 'METAR',
            date => { '>' => time() - 6 * 60 },
        }
    )->first;
    unless ($metar) {
        my $uri = URI->new(METAR_URL);
        $uri->query_form(ids => $station);
        my $response = LWP::UserAgent->new(timeout => 6)->get($uri);
        if ($response->is_success) {
            $response = $response->decoded_content;
            $metar = $self->update_or_create(
                {
                    date => time(),
                    id => $station,
                    text => $response,
                    type => 'METAR',
                }
            );
        }
    }
    return $metar;
}

sub taf ($self, $station = DEFAULT_STATION) {
    my $taf = $self->search(
        {
            id => $station,
            type => 'TAF',
            date => { '>' => time() - TAF_CACHE_TIME() },
        }
    )->first;
    unless ($taf) {
        my $uri = URI->new(TAF_URL);
        $uri->query_form(ids => $station);
        my $response = LWP::UserAgent->new(timeout => 6)->get($uri);
        if ($response->is_success) {
            $response = $response->decoded_content;
            $taf = $self->update_or_create(
                {
                    date => time(),
                    id => $station,
                    text => $response,
                    type => 'TAF',
                }
            );
        }
    }
    return $taf;
}

1;
