package Farid::Controller::Dns;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use File::Slurp;
use List::Util;
use MIME::Base64;
use Net::DNS;
use Farid::Model::DNS;

sub index ($self) {
    my $records;
    for my $row ($self->resultset('Dns')->all) {
        push @{$records}, { $row->get_columns };
    }
    $self->respond_to(
        html => { records => $records },
        json => { json => $records },
    );
}

sub query ($self) {

    $self->log->debug(
        join(
            ' ',
            __PACKAGE__,
            POSIX::strftime('%Y-%m-%dT%H:%M:%S', gmtime(time)),
            $self->req->address,
        )
    );
    my $query;
    if ($self->req->method eq 'GET') {
        $query = decode_base64($self->req->param('dns'));
    } elsif ($self->req->method eq 'POST') {
        $query = File::Slurp::read_file($self->req->body);
    }

    my $reply = Ninkilim::Model::DNS->reply($self->path_to(qw/root dns.txt/), $query);
    if ($reply) {
        $reply = $reply->data;
        $self->res->header('Content-Type' => 'application/dns-message');
        $self->res->header('Content-Length' => length($reply));
        $self->res->body($reply);
    }
}

1;
