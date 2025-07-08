package Farid;
use Mojo::Base 'Mojolicious', -signatures;
use Farid::Schema;
use Sys::Hostname;
use Time::HiRes;

my $schema;

sub id2time ($self, $id) {
    my @tm = gmtime($id / 1_000_000_000);
    return sprintf("%04u-%02u-%02u %02u:%02u:%02uZ", $tm[5] + 1900, $tm[4] + 1, $tm[3], $tm[2], $tm[1], $tm[0]);
}

sub schema ($self) {
    unless ($schema) {
        $schema = Farid::Schema->connect;
    }
    return $schema;
}

sub resultset ($self, $name) {
    return $self->schema->resultset($name);
}

sub startup ($self) {

    push @{$self->commands->namespaces}, 'Farid::Command';
    my $config = $self->config(
        {
            hypnotoad => {
                accepts => 100,
                listen => [ 'http://127.0.0.1:3000' ],
                proxy => 1,
                workers => 8,
            },
            secrets => [
                'c902fdf6a5d705de04aaaac54d70a8a7b037c263',
            ],
        }
    );

    # Configure the application
    $self->secrets($config->{secrets});

    # Hooks
    $self->hook(before_dispatch => sub ($c) {
        $c->stash->{'received'} = Time::HiRes::time() * 1000000000;
    });
    $self->hook(after_dispatch => sub ($c) {
        eval {
            $c->resultset('AccessLog')->create({
                id => sprintf("%u", $c->stash->{'received'}),
                ip => $c->tx->remote_address,
                path => $c->req->url->path,
                status => $c->res->code,
                duration => Time::HiRes::time() * 1000000000 - $c->stash->{'received'},
                server => Sys::Hostname::hostname,
                referer => $c->req->headers->referer // '',
            });
        };
        $self->log->warn($@) if $@;
    });

    # Helpers
    $self->helper(resultset => \&resultset);
    $self->helper(rs => \&resultset);
    $self->helper(schema => \&schema);
    $self->helper(id2time => \&id2time);

    # Router
    my $r = $self->routes;
    $r->get('/')->to('Home#index');
    $r->get('/accesslog' => [ format => [qw/html json/] ])->to('Accesslog#index', format => 'html');
    $r->get('/accesslog/sync' => [ format => [qw/html json/] ])->to('Accesslog#sync', format => 'html');
    $r->get('/articles')->to('Articles#index');
    $r->get('/articles/:title')->to('Articles#by_title')->name('articles_title');
    $r->get('/articles/:title/:lang' => [ format => [qw/html md mp3 txt/] ] )->to('Articles#by_title_lang', format => 'html');
    $r->get('/articles/sitemap', [ format => [qw/html json txt xml/] ])->to('Articles#sitemap', format => 'txt');
    $r->get('/checkit', [ format => [qw/html json/] ])->to('Checkit#index', format => 'html');
    $r->get('/dns', [ format => [qw/html json/] ])->to('Dns#index', format => 'html');
    $r->get('/impressions' => [ format => [qw/html json/] ])->to('Impressions#index', format => 'html');
    $r->get('/impressions/sync' => [ format => [qw/html json/] ])->to('Impressions#sync', format => 'html');
    $r->get('/impressions/top' => [ format => [qw/html json/] ])->to('Impressions#top', format => 'html');
    $r->get('/impressions/trending' => [ format => [qw/html json/] ])->to('Impressions#trending', format => 'html');
    $r->get('/postings', [ format => [qw/html json/] ])->to('Postings#index', format => 'html');
    $r->get('/postings/:id')->to('Postings#posting');
    $r->get('/random')->to('Random#index');
    $r->get('/status' => [ format => [qw/html json/] ])->to('Status#index');
    $r->get('/users' => [ format => [qw/html json/] ])->to('Users#index', format => 'html');
    $r->get('/users/:username' => [ format => [qw/html json/] ])->to('Users#username', format => 'html');
    $r->get('/weather/:country/:airport_id' => [ format => [qw/html/] ])->to('Weather#index', country => '', airport_id => '', format => 'html');
    $r->get('/weather/metar/:country/:airport_id' => [ format => [qw/html mp3/] ])->to('Weather#metar', country => '', airport_id => '', format => 'html');
    $r->get('/weather/taf/:country/:airport_id' => [ format => [qw/html mp3/] ])->to('Weather#taf', country => '', airport_id => '', format => 'html');
    $r->get('/*')->to('NotFound#index');

    #    for my $route (@{$r->children}) {
    #    printf("%s %s\n", $route->to_string, $route->name);
    #}

    $self->renderer->cache(Mojo::Cache->new(max_keys => 0));
}

1;
