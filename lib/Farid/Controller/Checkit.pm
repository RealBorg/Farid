package Farid::Controller::Checkit;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Farid::Schema;

sub index ($self) {

    my @checks = $self->rs('Checkit')->search(
        undef,
        { 
            order_by => [qw/server test/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    )->all;
    $self->render(checks => \@checks);
}

1;
