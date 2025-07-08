package Farid::Controller::NotFound;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
    my $dir = $self->app->home->child('public')->to_abs;
    my $file = $dir->child(
        $self->req->url->to_abs->host,
        $self->req->url->path,
    )->to_abs;
    $self->log->debug($file);
    if (index($file, $dir) == 0 && -f $file) {
        $self->reply->file($file);
    } else {
        $self->render(status => 404);
    }
}

1;
