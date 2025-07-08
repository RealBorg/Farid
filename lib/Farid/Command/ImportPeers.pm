package Farid::Command::ImportPeers;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util;

has description => 'import peers from private/peers.txt';
has usage => "Usage: $0 ImportPeers\n";

sub run ($self) {
    my $rs = $self->app->resultset('Peers');
    my $peers = $self->app->home->child('private', 'peers.txt');
    $peers = $peers->slurp;
    $peers = [ split(/\n/, $peers) ];
    for my $peer (@{$peers}) {
        $rs->find_or_create({ url => $peer });
    }
}

1;
