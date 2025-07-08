package Farid::Command::DeploySchema;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => 'deploy database schema';
has usage => "Usage: $0 DeploySchema\n";

sub run ($self) {
    $self->app->schema->deploy();
}

1;
