package Farid::Command::ImportX;
use Mojo::Base 'Mojolicious::Command', -signatures;

has description => 'import data from a X archive';
has usage => "Usage: $0 ImportX [path]\n";

use Digest::SHA;

use constant {
    XEPOCH => 1288834974657,
};

sub run ($self, $path) {
    $path = Mojo::File->new($path)->child('data')->to_abs;
    die unless -d $path;

    my $media_dir = $self->app->home->child('public', 'media')->to_abs;
    mkdir $media_dir;

    my $schema = $self->app->schema;
    $schema->txn_do(
        sub {
            my $account = $path->child("account.js");
            print "Processing $account\n";
            $account = $account->slurp;
            $account =~ s/window.YTD.account.part0 = //;
            $account = Mojo::JSON::decode_json($account);
            $account = $account->[0]->{account};

            my $profile = $path->child("profile.js");
            print "Processing $profile\n";
            $profile = $profile->slurp;
            $profile =~ s/window.YTD.profile.part0 = //;
            $profile = Mojo::JSON::decode_json($profile);
            $profile = $profile->[0]->{profile};

            my $user = $schema->resultset('Users')->update_or_create(
                {
                    id => $self->xid2id($account->{accountId}),
                    email => Digest::SHA::sha512_base64($account->{email}),
                    username => $account->{username},
                    displayname => $account->{accountDisplayName},
                    bio => $profile->{description}->{bio},
                    website => $profile->{description}->{website},
                    location => $profile->{description}->{location},
                }
            );

            for my $tweets ("$path/tweets.js", sort(glob("$path/tweets-part*.js"))) {
                my $tweets = Mojo::File->new($tweets);
                print "Processing $tweets\n";
                $tweets = $tweets->slurp;
                $tweets =~ s/^window.YTD.tweets.part\d+ = //;
                $tweets = Mojo::JSON::decode_json($tweets);
                for my $tweet_ (@{$tweets}) {
                    my $tweet = $tweet_->{tweet};
                    my $xid = $tweet->{id};
                    my $id = $self->xid2id($xid);
                    next if $user->search_related(
                        'postings',
                        {
                            -or => [
                                id => sprintf("%i", $id),
                                xid => sprintf("%i", $xid),
                            ],
                        }
                    )->count;
                    my $text = $tweet->{full_text};
                    for my $entity (@{$tweet->{entities}->{urls}}) {
                        my $url = $entity->{url};
                        my $expanded_url = $entity->{expanded_url};
                        if (defined($url) && defined($expanded_url)) {
                            $text =~ s/$url/$expanded_url/;
                        }
                    }
                    for my $entity (@{$tweet->{extended_entities}->{media}}) {
                        my $url = $entity->{url};
                        my $expanded_url = ''; # $entity->{expanded_url};
                        $text =~ s/$url/$expanded_url/;
                    }
                    my $posting = {
                        id => $id,
                        xid => $xid,
                        text => $text,
                        lang => $tweet->{lang} || '',
                        parent => $tweet->{in_reply_to_status_id} ? $self->xid2id($tweet->{in_reply_to_status_id}) : undef,
                    };
                    $posting = $user->create_related('postings', $posting);
                    for my $source (glob("$path/tweets_media/$xid-*")) {
                        $source = Mojo::File->new($source);
                        my $target = $source->basename;
                        $target =~ s/^$xid/$id/;
                        $target = $source->copy_to("$media_dir/$target");
                        if ($target->basename =~ /\.(jpg|png)$/) {
                            print "Found image $source\n";
                            $posting->create_related('medias',
                                {
                                    filename => $target->basename,
                                    type => 'image',
                                }
                            );
                        } elsif ($target->basename =~ /\.mp4$/) {
                            print "Found video $source\n";
                            $posting->create_related('medias',
                                {
                                    filename => $target->basename,
                                    type => 'video',
                                }
                            );
                        }
                    }
                }
            }
            my $note_tweets = "$path/note-tweet.js";
            if (-f $note_tweets) {
                print "Processing $note_tweets\n";
                $note_tweets = File::Slurp::read_file($note_tweets);
                $note_tweets =~ s/window.YTD.note_tweet.part0 = //;
                $note_tweets = JSON::decode_json($note_tweets);
                for my $note_tweet_ (@{$note_tweets}) {
                    my $note_tweet = $note_tweet_->{noteTweet};
                    my $xid = $note_tweet->{noteTweetId};
                    my $id = $self->xid2id($xid);
                    my $posting = $user->search_related('postings',
                            {
                                id => {
                                    #'>' => $xid - 4194304000,
                                    '>' => $id - 1_000_000_000,
                                    #'<' => $xid + 4194304000,
                                    '<' => $id + 1_000_000_000,
                                }
                            },
                            { 
                                order_by => \[ 'ABS(xid - ?)', $xid ],
                                rows => 1,
                            })->single;
                    if ($posting) {
                        print "Updated posting ".$posting->id." with extended text\n";
                        my $text = $note_tweet->{core}->{text};
                        for my $url (@{$note_tweet->{core}->{urls}}) {
                            my $shortUrl = $url->{shortUrl};
                            my $expandedUrl = $url->{expandedUrl};
                            $text =~ s/$shortUrl/$expandedUrl/;
                        }
                        $posting->update({ text => $text });
                    } else {
                        warn "Could not find posting for note tweet xid=$xid\n".JSON::encode_json($note_tweet);
                    }
                }
            }
            print "IMPORT SUCCESSFULLY COMPLETED\n";
        }
    );
}



sub xid2id {
    my ($self, $xid) = @_;

    my $ms = ( $xid >> 22 ) + XEPOCH();
    my $mid = ( $xid >> 12 ) & 0x3FF;
    my $seq = $xid & 0xFFF;

    my $id = $ms * 1_000_000 + $mid % 1000 * 1000 + $seq % 1000;
    return $id;
}

1;
