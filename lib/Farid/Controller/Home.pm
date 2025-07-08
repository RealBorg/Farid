package Farid::Controller::Home;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
    $self->redirect_to('/articles');
}

1;
