package Farid::Controller::Articles;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Encode;
use Farid::Controller::Impressions;
use File::Slurp;

sub list ($self) {
    my $dir = $self->app->home->child('private', 'articles');
    for (glob("$dir/*/*")) {
        if (/$dir\/(.*)\/(.*)\.(html|md|mp3|txt)/) {
            my $title = $1;
            my $lang = $2;
            my $type = $3;
            $self->stash->{'articles'}->{$title}->{'lang'}->{$lang}->{$type} = 1;
            if ($lang eq 'en' && $type eq 'md') {
                my $date = [ stat($_) ];
                $date = $date->[9];
                $date = [ gmtime($date) ];
                $date = sprintf('%04d-%02d-%02d', $date->[5] + 1900, $date->[4] + 1, $date->[3]);
                $self->stash->{'articles'}->{$title}->{'date'} = $date;
                $self->stash->{'articles'}->{$title}->{'title'} = $self->title($title);
            }
        }
    }
    $self->stash->{'articles_by_date'} = [ sort({ $self->stash->{'articles'}->{$b}->{'date'} cmp $self->stash->{'articles'}->{$a}->{'date'} } keys(%{$self->stash->{'articles'}})) ];
    $self->stash->{'articles_by_title'} = [ sort({ $self->stash->{'articles'}->{$a}->{'title'} cmp $self->stash->{'articles'}->{$b}->{'title'} } keys(%{$self->stash->{'articles'}})) ];
}

sub index ($self) {
    $self->list;
    $self->render;
}

sub by_title ($self) {
    my $title = $self->param('title');

    $self->list;
    my $langs;
    for my $lang (split(/,/, ($self->req->headers->header('Accept-Language') || ''))) {
        $lang =~ s/^([a-z]{2})/$1/;
        next unless $lang;
        push @{$langs}, $lang;
    }
    push @{$langs}, 'en';

    foreach my $lang (@{$langs}) {
        warn $lang;
        if ($self->stash->{articles}->{$title}->{'lang'}->{$lang}) {
            $self->redirect_to("/articles/$title/$lang.html");
            warn $lang;
        }
    }
}

sub by_title_lang ($self) {
    my $title = $self->param('title');
    my $lang = $self->param('lang');
    my $format = $self->stash('format');

    unless ($self->req->url->path eq "/articles/$title/$lang.$format") {
        $self->redirect_to("/articles/$title/$lang.$format");
        return;
    }

    Farid::Controller::Impressions::count($self);
    $self->list();
    if ($self->stash->{articles}->{$title}->{'lang'}->{$lang}) {
        my $dir = $self->app->home->child('private', 'articles', $title);
        if ($format eq 'md') {
            my $md = $dir->child("$lang.md");
            $self->reply->file($md);
        } elsif ($format eq 'mp3') {
            my $mp3 = $dir->child("$lang.mp3");
            $self->reply->file($mp3);
        } elsif ($format eq 'txt') {
            my $txt = $dir->child("$lang.txt");
            $self->reply->file($txt);
        } else {
            my $html = $dir->child("$lang.html");
            $html = $html->slurp;
            $html = Encode::decode('UTF-8', $html);
            $self->stash->{'article'}->{'body'} = $html;
            $self->stash->{'article'}->{'language'} = $lang;
            $self->stash->{'article'}->{'languages'} = $self->stash->{'articles'}->{$title}->{'lang'};
            $self->stash->{'article'}->{'id'} = $title;
            $self->stash->{'title'} = $self->title($title);
            if ($html =~ /<h1.*>(.*)<\/h1>/s) {
                my $title = $1;
                $title =~ s/\n//;
                $self->stash->{'title'} = $title;
            }
            $self->stash->{'article'}->{'title'} = $self->stash->{'title'};
            $self->render;
        }
    }
}

sub sitemap ($self) {
    $self->list();
    for my $title (sort(keys(%{$self->stash->{articles}}))) {
        for my $lang (sort(keys(%{$self->stash->{articles}->{$title}->{lang}}))) {
            push @{$self->stash->{urls}}, $self->url_for("/articles/$title/$lang.html")->to_abs;
        }
    }
}

sub title ($self, $title) {
    $title =~ s/_/ /g;
    $title = join(' ', map(ucfirst($_), split(' ', $title)));

    return $title;
}

1;
