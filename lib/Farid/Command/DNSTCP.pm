package Farid::Command::DNSTCP;
use Mojo::Base 'Net::Server::PreFork', 'Mojolicious::Command', -signatures;

use English;
use Farid::Model::DNS;
use Sys::Syslog;
use Time::HiRes;

has description => 'Run TCP DNS Server';
has usage => "Usage: $0 DNSTCP\n";

sub run ($self) {
    Sys::Syslog::openlog(__PACKAGE__, "nofatal,perror,pid", "daemon");
    return $self->SUPER::run(
        port => 53,
        proto => 'tcp',
        min_servers => 5,
        max_servers => 20,
        max_requests => 100,
        user => $UID,
        group => $GID,
    );
}

sub process_request {
    my $self = shift;
    my $socket = $self->{server}->{client};

    my $timeout = Time::HiRes::time() + 1;
    my $query = '';
    $socket->blocking(0);
    while (Time::HiRes::time() < $timeout) {
        my $buf = '';
        $socket->sysread($buf, 1500);
        if (length($buf) > 0) {
            $query .= $buf;
            if (length($query) >= 2) {
                my $length = unpack('n', substr($query, 0, 2));
                if (length($query) == $length + 2) {
                    $query = substr($query, 2);
                    last;
                }
            }
        }
        Time::HiRes::sleep(0.1);
    }
    my $reply = Farid::Model::DNS->reply($query, $self->{server}->{peeraddr});
    if ($reply) {
        $reply = $reply->data;
        $socket->print(pack('n', length($reply)), $reply);
    }
    $socket->close;
}

1;
