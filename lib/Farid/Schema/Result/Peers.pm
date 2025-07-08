use utf8;
package Farid::Schema::Result::Peers;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("peers");
__PACKAGE__->add_columns(
  "url",
  { data_type => "text", is_nullable => 0 },
  "user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "access_log_id",
  { data_type => "bigint", is_nullable => 1 },
  "impressions_id",
  { data_type => "bigint", is_nullable => 1 },
  "posting_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("url");
__PACKAGE__->belongs_to(
  "user",
  "Farid::Schema::Result::Users",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-23 22:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kzarUJDancZui8yi57ctgg

use HTTP::Date;
use LWP::UserAgent;
use JSON;
use URI;

my $ua;

sub fetch_json {
    my ($self, $url) = @_;

    my $data = $self->user_agent->get($url);
    die "$url: ".$data->status_line unless $data->is_success;
    $data = $data->content;
    $data = JSON::decode_json($data);
    return $data;
}

sub fetch_media {
    my ($self, $filename, $uri) = @_;

    Ninkilim->log->debug(__PACKAGE__."->fetch_media($filename) from $uri");
    if (-f $filename) {
        my $response = $self->user_agent->head($uri);
        if ($response->header('Content-Length') && $response->header('Content-Length') != -s $filename) {
            Ninkilim->log->debug(__PACKAGE__.'->fetch_media('.$filename.'): Size does not match Content-Length');
            unlink $filename;
        }
    }
    unless (-f $filename) {
        Ninkilim->log->debug(__PACKAGE__.'->fetch_media('.$filename.'): Downloading');
        my $response = $self->user_agent->get($uri, ':content_file' => "$filename");
        if ($response->is_success) {
            Ninkilim->log->debug(__PACKAGE__.'->fetch_media('.$filename.'): Download succeeded');
            if (my $mtime = $response->header('Last-Modified')) {
                $mtime = HTTP::Date::str2time($mtime);
                utime $mtime, $mtime, $filename;
            }
        } else {
            Ninkilim->log->warn(__PACKAGE__.'->fetch_media('.$filename.'): Download failed');
            unlink $filename;
        }
    }
}

sub fetch_postings {
    my ($self, %args) = @_;

    my $url = URI->new($self->url);
    $url->path('/postings');
    %args = (
        format => 'json',
        include_replies => 1,
        include_rt => 1,
        min_id => $self->posting_id,
        rows => 100,
        sort => 'asc',
        %args,
    );
    $url->query_form(%args);
    my $data = $self->fetch_json($url);
    $data = $data->{postings};
    return @{$data};
}

sub user_agent {
    my ($self) = @_;

    unless ($ua) {
        $ua = LWP::UserAgent->new(
            timeout => 6,
        );
    }

    return $ua;
}

1;
