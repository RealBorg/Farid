package Farid::Controller::Users;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
    my $rs = $self->resultset('Users')->search(
        {
        },
        {
            order_by => { '-desc' => 'username' },
        }
    );
    my $users;
    for my $user ($rs->all) {
        push @{$users}, $user;
    }
    $self->respond_to(
        html => { users => $users, count => scalar(@{$users}) },
        json => { json => $users },
    );
}

sub username ($self) {
    my $username = $self->param('username');

    my $user = $self->resultset('Users')->find({ username => $username });
    $user = { $user->get_columns };
    $self->stash->{'title'} = sprintf("%s on %s", $user->{displayname}, $self->url_for()->host);
    $self->respond_to(
        html => { user => $user },
        json => { json => $user },
    );
}

1;
