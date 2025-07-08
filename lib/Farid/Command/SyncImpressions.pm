package Farid::Command::SyncImpressions;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::JSON;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util;

has description => 'fetch impressions from peers';
has usage => "Usage: $0 SyncImpressions [rows=1000]\n";

sub run ($self, $rows = 1_000) {
    $rows //= 1_000;

    my $resultset = $self->app->resultset('Impressions');
    my $ua = Mojo::UserAgent->new;
    my $cache;
    for my $peer ($self->app->resultset('Peers')->all) {
        eval {
            my $url = Mojo::URL->new($peer->url);
            $url->path('/impressions.json');
            $url->query(
                min_id => $peer->impressions_id,
                rows => $rows,
                sort => 'asc',
            );
            $self->app->log->debug($url);
            my $res = $ua->get($url)->result;
            die Mojo::JSON::encode_json($res->error) unless $res->is_success;
            $res = $res->json;
            for my $impression (@{$res}) {
                $peer->update({ impressions_id => $impression->{id} });
                next if $cache->{$impression->{id}};
                $cache->{$impression->{id}} = $resultset->search({ id => $impression->{id} })->count;
                next if $cache->{$impression->{id}};
                $resultset->create($impression);
                $cache->{$impression->{id}} = 1;
                $self->app->log->debug(Mojo::JSON::encode_json($impression));
            }
        };
        $self->app->log->warn($@) if $@;
    }
}

1;
