package Farid::Controller::Postings;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Farid::Controller::Impressions;

sub index ($self) {
    my $rs = $self->rs('Postings');

    my $page = abs(int($self->req->param('page') || 1));
    $self->stash->{'page'}->{'current'} = $page;
    $self->stash->{'page'}->{'next'} = $page + 1;
    if ($page > 1) {
        $self->stash->{'page'}->{'previous'} = $page - 1 if $page > 1;
        $rs = $rs->search(undef, { page => $page });
    }

    my $rows = abs(int($self->req->param('rows') || 100));
    $rows = 100 if $rows > 10_000;
    $rs = $rs->search(undef, { rows => $rows });

    if (($self->req->param('sort') || 'desc') eq 'asc') {
        $rs = $rs->search(undef, { order_by => 'id' });
    } else {
        $rs = $rs->search(undef, { order_by => { -desc => 'id' } });
    }

    my $min_id = abs(int($self->req->param('min_id') || 0));
    if ($min_id > 0) {
        $rs = $rs->search({ id => { '>' => $min_id } });
    }

    unless ($self->req->param('include_rt')) {
        $rs = $rs->search(
            {
                text => { -not_like => 'RT%' },
            }
        );
    }
    $self->stash->{'markdown'} = sub {
        my $text = shift;
        $text =~ s/(https?:\/\/[^\s]+)/[$1]($1)/g;
        #$text = Ninkilim::Util::Markdown->markdown($text);
        return $text;
    };

    unless ($self->req->param('include_replies')) {
        $rs = $rs->search(
            {
                -and => [
                    text => { -not_like => '@%' },
                    parent => undef,
                ],
            }
        );
    }

    for my $q (split(/\s+/, $self->param('q') || '')) {
        $q =~ s/%/%%/;
        $q = "%$q%";
        $rs = $rs->search(
            {
                text => { -ilike => $q },
            }
        );
    }

    my $postings = [ $rs->all ];
    $postings = $self->rows2hash($postings);
    $self->stash->{'title'} = sprintf("Postings - Page %s", $self->stash->{'page'}->{'current'});
    $self->respond_to(
        html => { postings => $postings },
        json => { json => $postings },
    );
}

sub markdown ($self, $text) {
    return $text;
}

sub posting ($self) {
    my $id = $self->param('id');

    Farid::Controller::Impressions::count($self);
    my $rs = $self->resultset('Postings');
    my $postings = [];
    my $posting = $rs->find({
        id => $id,
    });
    unless ($posting) {
        $posting = $rs->find({ xid => $id });
        if ($posting) {
            $self->redirect_to('/postings/'.$posting->id);
            return;
        }
    }
    #$self->detach('/notfound') unless $posting;
    push @{$postings}, $posting;
    $self->stash->{'title'} = $posting->text;
    for (my $i = 0; $i < scalar(@{$postings}); $i++) {
        push @{$postings}, $rs->search({
            parent => $postings->[$i]->id,
        })->all;
    }
    $postings = $self->rows2hash($postings);
    #$self->stash->{'data'}->{'postings'} = $postings;
    $self->respond_to(
        html => { postings => $postings },
        json => { json => $postings },
    );
}

sub sitemap ($self) {
    my $resultset = $self->rs('Postings')->search(
        {},
        {
            columns => [ qw/id/ ],
            order_by => 'id',
            rows => 25_000,
        }
    );
    my $urls;
    for my $row ($resultset->all()) {
        push @{$urls}, $self->uri_for('/postings/'.$row->id)->as_string;
    }
    $self->stash->{'format'} = 'none';
    $self->res->body(join("\n", @{$urls}, ''));
}


sub rows2hash ($self, $rows) {
    my @result;
    for my $row (@{$rows}) {
        my $medias = [ $row->medias->all ];
        my $hash = { $row->get_columns };
        $hash->{id} = ''.$row->id; # scalar not number
        for my $media ($row->medias->all) {
            my $media_hash = { $media->get_columns };
            $media_hash->{url} = ''.$self->url_for('/media/'.$media->filename);
            delete $media_hash->{posting};
            push @{$hash->{medias}}, $media_hash;
        }
        $hash->{parent} ||= 0;
        $hash->{user} = { $row->user->get_columns };
        push @result, $hash;
    }
    return \@result;
}

1;
