package Farid::Command::ImportDNS;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => 'import dns data from private/dns.txt';
has usage => "Usage: $0 ImportDNS\n";

sub run ($self) {
    my $schema = $self->app->schema;
    $schema->txn_do(
        sub {
            my $dns = $self->app->home->child('private', 'dns.txt');
            $dns = $dns->slurp;
            $dns = [ split(/\n/, $dns) ];
            my $rs = $schema->resultset('Dns');
            $rs->delete;
            for my $line (@{$dns}) {
                next if $line =~ /^$/;
                next if $line =~ /^#/;
                my ($name, $class, $type, $data) = split(/\s+/, $line, 4);
                $data //= '';
                $rs->create(
                    {
                        name => $name,
                        class => $class,
                        type => $type,
                        data => $data,
                    }
                );
            }
        }
    );
}

1;
