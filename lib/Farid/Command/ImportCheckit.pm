package Farid::Command::ImportCheckit;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => 'import checks from private/checkit.txt';
has usage => "Usage: $0 ImportCheckit\n";

sub run ($self) {
    my $rs = $self->app->resultset('Checkit');
    my $checks = $self->app->home->child('private', 'checkit.txt');
    $checks = $checks->slurp;
    $checks = [ split(/\n/, $checks) ];
    for my $check (@{$checks}) {
        my ($server, $test, $args) = split(/\s+/, $check);
        $args //= '';
        $rs->find_or_create(
            { 
                server => $server,
                test => $test,
                args => $args,
            }
        );
    }
}

1;
