package Farid::Command::DumpConfig;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => "Dump app's config";
has usage => "Usage: $0 DumpConfig [NAME]\n";

sub run ($self) {
    say $self->app->dumper($self->app->config);
    say $self->app->home;
}

1;
