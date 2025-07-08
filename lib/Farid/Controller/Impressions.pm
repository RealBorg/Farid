package Farid::Controller::Impressions;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util;
use Sys::Hostname;

sub count ($self) {
    eval {
        $self->resultset('Impressions')->create(
            {
                id => sprintf("%u", $self->stash->{'received'}),
                ip => $self->tx->remote_address,
                path => $self->req->url->path,
                referer => $self->req->headers->referer // '',
                server => Sys::Hostname::hostname(),
            }
        );
    };
    $self->log->error($@) if $@;
    eval {
        $self->stash->{'impressions'} = $self->resultset('Impressions')->search({ path => $self->req->url->path})->count;
    };
    $self->log->error($@) if $@;
}

sub index ($self) {
    my $resultset = $self->resultset('Impressions');
    # ip
    if (my $ip = $self->param('ip')) {
        $resultset = $resultset->search({ ip => $ip });
    }
    # min_id
    if (my $min_id = $self->req->param('min_id')) {
        $resultset = $resultset->search({ 'id' => { '>' => $min_id } });
    }
    # path
    if (my $path = $self->req->param('path')) {
        $resultset = $resultset->search({ path => $path });
    }
    # referer
    if (my $referer = $self->req->param('referer')) {
        $resultset = $resultset->search({ referer => $referer });
    }
    # count
    $self->stash->{'count'} = $resultset->count;
    # sort
    if (($self->req->param('sort') || '') eq 'asc') {
        $resultset = $resultset->search(undef, { order_by => 'id' });
    } else {
        $resultset = $resultset->search(undef, { order_by => { -desc => 'id' } });
    }
    # page
    my $page = abs(int($self->req->param('page') || 1));
    $resultset = $resultset->search(undef, { page => $page });
    $self->stash->{'page'}->{'current'} = $page;
    $self->stash->{'page'}->{'next'} = $page + 1;
    $self->stash->{'page'}->{'previous'} = $page - 1 if $page > 1;
    # rows
    my $rows = abs(int($self->req->param('rows') || 100));
    $rows = 100 if $rows > 100_000;
    $resultset = $resultset->search(undef, { rows => $rows });
    # fetch
    my $impressions;
    for my $row ($resultset->all) {
        push @{$impressions}, { $row->get_columns };
    }
    $self->respond_to(
        html => { impressions => $impressions },
        json => { json => $impressions },
    );
}


sub top ($self) {
    my $resultset = $self->resultset('Impressions')->search(
        {},
        {
            select   => ['path', { count => '*' }],
            as       => ['path', 'count'],
            group_by => ['path'],
            order_by => { -desc => 'count' },
            rows     => 100,
            page     => 1,
        }
    );
    my $impressions;
    for my $row ($resultset->all) {
        push @{$impressions}, { $row->get_columns };
    }
    $self->stash->{'lang'} = 'en';
    $self->stash->{'title'} = 'Most Popular Topics';
    $self->respond_to(
        html => { impressions => $impressions },
        json => { json => $impressions },
    );
}

sub trending ($self) {
    my $resultset = $self->resultset('Impressions')->search(
        {
            id => { '>' => int((Time::HiRes::time() - 7 * 24 * 60 * 60) * 1_000_000_000) },
        },
        {
            select   => ['path', { count => '*' }],
            as       => ['path', 'count'],
            group_by => ['path'],
            order_by => { -desc => 'count' },
            rows     => 100,
            page     => 1,
        }
    );
    my $impressions;
    for my $row ($resultset->all) {
        push @{$impressions}, { $row->get_columns };
    }
    $self->stash->{'lang'} = 'en';
    $self->stash->{'title'} = 'This Week\'s Trending Topics';
    $self->respond_to(
        html => { impressions => $impressions },
        json => { json => $impressions },
    );
}

1;
