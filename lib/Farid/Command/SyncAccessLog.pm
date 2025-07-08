package Farid::Command::SyncAccessLog;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::JSON;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util;

has description => 'fetch accesslog from peers';
has usage => "Usage: $0 SyncAccessLog [rows=1000]\n";

sub run ($self, $rows = 1_000) {
    my $resultset = $self->app->resultset('AccessLog');
    my $ua = Mojo::UserAgent->new;
    my $cache;
    for my $peer ($self->app->resultset('Peers')->all) {
        eval {
            my $url = Mojo::URL->new($peer->url);
            $url->path('/accesslog.json');
            $url->query(
                min_id => $peer->impressions_id,
                rows => $rows,
                sort => 'asc',
            );
            my $res = $ua->get($url)->result;
            die Mojo::JSON::encode_json($res->error) unless $res->is_success;
            $res = $res->json;
            for my $access (@{$res}) {
                $peer->update({ access_log_id => $access->{id} });
                next if $cache->{$access->{id}};
                $cache->{$access->{id}} = $resultset->search({ id => $access->{id} })->count;
                next if $cache->{$access->{id}};
                $resultset->create($access);
                $cache->{$access->{id}} = 1;
                $self->app->log->debug(Mojo::JSON::encode_json($access));
            }
        };
        $self->app->log->warn($@) if $@;
    }
}

1;
