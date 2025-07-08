package Farid::Command::SyncPostings;
use Mojo::Base 'Mojolicious::Command', -signatures;

use Mojo::JSON;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util;

has description => 'fetch postings from peers';
has usage => "Usage: $0 SyncPeers [rows=1000]\n";

my $cache;
my $useragent;

sub run ($self, $rows = 1000) {
    for my $peer ($self->app->schema->resultset('Peers')->all) {
        eval {
            for my $posting ($self->fetch_postings($peer)) {
                $peer->update({ posting_id => $posting->{id} });
                $self->import_posting($posting);
            }
        };
        $self->log->warn($@) if $@;
    }
}

sub fetch_postings ($self, $peer) {
    my $url = Mojo::URL->new($peer->url);
    $url->path('/postings.json');
    $url->query(
        include_replies => 1,
        include_rt => 1,
        min_id => $peer->posting_id // 0,
        rows => $rows,
        sort => 'asc',
    )
    my $res = $self->useragent->get($url)->result;
    die Mojo::JSON::encode_json($res->error) unless $res->is_success;
    $res = $res->json;
    return @{$res};
}

sub import_posting ($self, $posting) {
    next if $cache->{$posting->{id}};
    $cache->{$posting->id} = $self->app->schema->resultset('Postings')->search({ id => $posting->{id} })->count;
    next if $cache->{$posting->{id}};
    my $user = $self->import_user($posting->{user}, $peer);
    my $posting_db = $user->find_or_create_related('postings',
        {
            id => $posting->{id},
            text => $posting->{text},
            lang => $posting->{lang},
            parent => $posting->{parent} ? $posting->{parent} : undef,
        }
    );
    for my $media (@{$posting->{medias}}) {
        $self->log->debug("Found media ".$media->{filename});
        my $file = $self->app->home->child('public', 'media', $media->{filename});
        $file->download($media->{url});
        $posting_db->find_or_create_related('medias',
            {
                filename => $media->{filename},
                type => $media->{type},
            }
        );
    }
    $cache->{$posting->{id}} = 1;
}

sub import_user ($self, $user, $peer) {
    my $source = Mojo::URL->new($peer->url)->host;
    my $result = $self->app->schema->resultset('Users')->find_or_create(
        {
            id => $user->{id},
            email => $user->{email},
            username => $user->{username},
            displayname => $user->{displayname},
            bio => $user->{bio},
            website => $user->{website},
            location => $user->{location},
            source => $source,
        }
    );
    if ($source eq $user->source) {
        $user->update(
            {
                email => $posting->{user}->{email},
                username => $posting->{user}->{username},
                displayname => $posting->{user}->{displayname},
                bio => $posting->{user}->{bio},
                website => $posting->{user}->{website},
                location => $posting->{user}->{location},
            }
        );
    }
}

sub useragent ($self) {
    $useragent //= Mojo::UserAgent->new;
    return $useragent;
}

1;
