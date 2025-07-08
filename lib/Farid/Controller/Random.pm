package Farid::Controller::Random;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Farid::Model::Random;

sub index ($self) {
    my $length = abs(int($self->param('length') || 8));

    $self->stash->{'random'}->{'alnum'} = Farid::Model::Random->alnum($length);
    $self->stash->{'random'}->{'hex'} = Farid::Model::Random->hex($length);
    $self->stash->{'random'}->{'num'} = Farid::Model::Random->num($length);
}

1;
