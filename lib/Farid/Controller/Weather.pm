package Farid::Controller::Weather;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub airport ($self) {
    $self->countries;
    return $self->stash->{'airport'} if $self->stash->{'airport'};
    my $country = $self->param('country');
    return undef unless $country;
    my $rs = $self->rs('Airports')->search(
        {
            country => $country,
        },
        {
            order_by => 'name',
        }
    );
    my $airport_id = $self->param('airport_id') // '';
    my $airport;
    my $airports;
    for my $row ($rs->all) {
        my $row = { $row->get_columns };
        push @{$airports}, $row;
        $airport = $row if $row->{id} eq $airport_id;
    }
    $self->stash->{'airports'} = $airports;
    $self->stash->{'airport'} = $airport;
    return $airport;
}

sub countries ($self) {
    return if $self->stash->{'countries'};
    my $rs = $self->rs('Airports')->search(
        undef, 
        {
            select => 'country',
            group_by => 'country',
            order_by => 'country',
        }
    );
    my $countries;
    for my $row ($rs->all) {
        push @{$countries}, $row->country;
    }
    $self->stash->{'countries'} = $countries;
}

sub index ($self) {
    $self->metar;
    $self->taf;
    #$self->render(airport => $self->stash->{airport}, airports => $self->stash->{airports}, countries => $self->stash->{countries}, country => $self->stash->{country}, metar => $self->stash->{metar}, taf => $self->stash->{taf});
}

sub metar ($self) {
    my $airport = $self->airport;
    if ($airport) {
        my $metar = $self->rs('Aviationweather')->metar($airport->{id});
        if ($metar) {
            $self->stash->{'metar'} = { $metar->get_columns };
            $self->stash->{'metar'}->{'raw'} = $metar->text;
            $self->stash->{'metar'}->{'decoded'} = $metar->decode($airport);
            $self->stash->{'tts'}->{'text'} = $self->stash->{'metar'}->{'decoded'};
        }
    }
}

sub taf ($self) {
    my $airport = $self->airport;
    if ($airport) {
        my $taf = $self->rs('Aviationweather')->taf($airport->{id});
        if ($taf) {
            warn $taf;
            $self->stash->{'taf'} = { $taf->get_columns };
            $self->stash->{'taf'}->{'raw'} = $taf->text;
            $self->stash->{'taf'}->{'decoded'} = $taf->decode($airport);
            $self->stash->{'tts'}->{'text'} = $self->stash->{'taf'}->{'decoded'};
        }
    }
}

1;
