package Farid::Command::DNSUDP;
use Mojo::Base 'Net::Server::PreFork', 'Mojolicious::Command', -signatures;

use English;
use Farid::Model::DNS;
use Sys::Syslog;

has description => 'Run UDP DNS Server';
has usage => "Usage: $0 DNSUDP\n";

sub run ($self) {
    Sys::Syslog::openlog(__PACKAGE__, "nofatal,perror,pid", "daemon");
    return $self->SUPER::run( 
        port => 53,
        proto => 'udp',
        min_servers => 5,
        max_servers => 20,
        max_requests => 100,
        user => $UID,
        group => $GID,
    );
}

sub process_request {
    my $self = shift;

    my $reply = Farid::Model::DNS->reply($self->{server}->{udp_data}, $self->{server}->{peeraddr});
    if ($reply) {
        $reply->truncate(1452);
        $self->{server}->{client}->send($reply->data);
    }
}

1;
