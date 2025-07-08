package Farid::Controller::Accesslog;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub format_duration ($duration) {
    $duration = sprintf("%.6f", $duration / 1_000_000_000);
    return $duration;
}

sub index ($self) {
    my $resultset = $self->resultset('AccessLog');
    # ip
    if (my $ip = $self->param('ip')) {
        $resultset = $resultset->search({ ip => $ip });
    }
    # min_id
    if (my $min_id = $self->param('min_id')) {
        $resultset = $resultset->search({ id => { '>' => $min_id }});
    }
    # path
    if (my $path = $self->param('path')) {
        $resultset = $resultset->search({ path => $path, });
    }
    # referer
    if (my $referer = $self->param('referer')) {
        $resultset = $resultset->search({ referer => $referer });
    }
    # status
    if (my $status = $self->param('status')) {
        $resultset = $resultset->search({ status => $status });
    }
    # count
    $self->stash->{'count'} = $resultset->count;
    # sort
    if (($self->param('sort') || '') eq 'asc') {
        $resultset = $resultset->search(undef, { order_by => 'id' });
    } else {
        $resultset = $resultset->search(undef, { order_by => { -desc => 'id' } });
    }
    # page
    my $page = abs(int($self->param('page') || 1));
    $resultset = $resultset->search(undef, { page => $page });
    $self->stash->{'page'}->{'current'} = $page;
    $self->stash->{'page'}->{'next'} = $page + 1;
    $self->stash->{'page'}->{'previous'} = $page - 1 if $page > 1;
    # rows
    my $rows = abs(int($self->param('rows') || '100'));
    $rows = 100 if $rows > 100_000;
    $resultset = $resultset->search(undef, { rows => $rows });
    # fetch
    my $accesslog;
    for my $row ($resultset->all) {
        push @{$accesslog}, { $row->get_columns };
    }
    $self->respond_to(
        html => { accesslog => $accesslog, format_duration => \&format_duration },
        json => { json => $accesslog },
    );
}

sub sync ($self) {
    my $rows = abs(int($self->req->param('rows') || 1_000));

    my $resultset = $self->resultset('AccessLog');
    my $ua = Mojo::UserAgent->new;
    my $accesslog = [];
    my $cache;
    for my $peer ($self->resultset('Peers')->all) {
        eval {
            my $url = Mojo::URL->new($peer->url);
            $url->path('/accesslog.json');
            $url->query(
                min_id => $peer->access_log_id,
                rows => $rows,
                sort => 'asc',
            );
            my $res = $ua->get($url)->result;
            die Mojo::Util::dumper($res->error) unless $res->is_success;
            $res = $res->json;
            for my $access (@{$res}) {
                $peer->update({ access_log_id => $access->{id} });
                next if $cache->{$access->{id}};
                $cache->{$access->{id}} = $resultset->search({ id => $access->{id} })->count;
                next if $cache->{$access->{id}};
                $resultset->create($access);
                $cache->{$access->{id}} = 1;
                push @{$accesslog}, $access;
            }
        };
        $self->log->warn($@) if $@;
    }
    $self->respond_to(
        html => { accesslog => $accesslog, count => scalar(@{$accesslog}), format_duration => \&format_duration },
        json => { json => $accesslog },
    );
}

1;
