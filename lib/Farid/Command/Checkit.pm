package Farid::Command::Checkit;
use Mojo::Base 'Mojolicious::Command', -signatures;

require Time::HiRes;
require Mojo::UserAgent;
require Mojo::JSON;

has description => 'Service Monitoring Daemon';
has usage => "Usage: $0 Checkit\n";

sub run ($self, $interval = 600) {
    while (1) {
        my $time = Time::HiRes::time;
        eval {
            $self->run_checks($interval);
        };
        warn $@ if $@;
        my $sleep = $time + $interval - Time::HiRes::time;
        warn $sleep;
        Time::HiRes::sleep($sleep) if $sleep > 0;
    }
}

sub check_daytime ($self, $server, $arg) {
    my $result = '';

    require IO::Socket::IP;
    my $sock = IO::Socket::IP->new(
        PeerAddr => $server,
        PeerPort => 13,
        Proto    => 'tcp',
        Timeout  => 6,
    );
    if ($sock) {
        my $timeout = Time::HiRes::time + 6;
        $sock->blocking(0);
        while (Time::HiRes::time < $timeout) {
            my $buf;
            $sock->read($buf, 1024);
            $result .= $buf if length($buf);
            Time::HiRes::sleep(0.1);
        }
        $sock->close;
        $result =~ s/\r?\n$//;
        if ($result =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})[.,](\d+)([+-])(\d{2}):?(\d{2})$/) {
            $result = "OK: $result";
        } else {
            $result = "ERROR: $result";
        }
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_dns ($self, $server, $name) {
    my $result;

    require Net::DNS::Resolver;
    require Socket;
    my $resolver = Net::DNS::Resolver->new;
    $resolver->nameservers($server);
    my $response = $resolver->query($name, "A");
    if ($response) {
        $response = [ $response->answer ];
        $response = [ map($_->address, @{$response}) ];
        $response = [ sort( { Socket::inet_aton($a) cmp Socket::inet_aton($b) } @{$response}) ];
        $result = "OK: " . join(", ", @{$response});
    } else {
        $result = "ERROR: ", $resolver->errorstring;
    }
    return $result;
}

sub check_http ($self, $server, $arg) {
    my $result;

    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new(timeout => 6);
    my $time = Time::HiRes::time;
    my $res = $ua->get("http://$server/");
    if ($res->is_success) {
        $result = sprintf("OK: %s, %.3fs", $res->status_line, Time::HiRes::time - $time);
    } else {
        $result = sprintf("ERROR: %s, %.3fs", $res->status_line, Time::HiRes::time - $time);
    }
    return $result;
}

sub check_https ($self, $server, $arg) {
    my $result;

    require IO::Socket::SSL;
    require IO::Socket::SSL::Utils;
    my $sock = IO::Socket::SSL->new(
        PeerHost => $server,
        PeerPort => 443,
    );
    if ($sock) {
        my $cert = $sock->peer_certificate;
        $cert = IO::Socket::SSL::Utils::CERT_asHash($cert);
        my $not_after = $cert->{not_after};
        $result = $self->app->id2time($not_after * 1_000_000_000);
        if ($not_after < time) {
            $result = "ERROR: $result";
        } elsif (($not_after + 7 * 24 * 60 * 60) < time) {
            $result = "WARNING: $result";
        } else {
            $result = "OK: $result";
        }
        $sock->close;
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_ntp ($self, $server, $arg) {
    my $result;

    my $response;
    require Net::NTP;
    $response = { Net::NTP::get_ntp_response($server) };
    $result = sprintf("OK: %s %.3f %i %s",
        $self->app->id2time($response->{'Destination Timestamp'} * 1_000_000_000),
        $response->{Offset},
        $response->{Stratum},
        $response->{'Reference Clock Identifier'},
    );
    return $result;
}

sub check_smtp ($self, $server, $arg) {
    my $result = '';

    require IO::Socket::IP;
    my $sock = IO::Socket::IP->new(
        PeerAddr => $server,
        PeerPort => 25,
        Proto    => 'tcp',
        Timeout  => 6,
    );
    if ($sock) {
        my $timeout = Time::HiRes::time + 6;
        $sock->blocking(0);
        while (Time::HiRes::time < $timeout) {
            my $buf;
            $sock->read($buf, 1024);
            $result .= $buf if length($buf);
            Time::HiRes::sleep(0.1);
        }
        $sock->close;
        $result =~ s/\r?\n$//;
        if ($result =~ /^220\s+/) {
            $result = "OK: $result";
        } else {
            $result = "ERROR: $result";
        }
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_ssh ($self, $server, $arg) {
    my $result;

    require IO::Socket::IP;
    my $sock = IO::Socket::IP->new(
        PeerAddr => $server,
        PeerPort => 22,
        Proto    => 'tcp',
        Timeout  => 6,
    );
    if ($sock) {
        my $banner;
        my $timeout = Time::HiRes::time + 6;
        $sock->blocking(0);
        while (Time::HiRes::time < $timeout) {
            my $buf;
            $sock->read($buf, 1024);
            $banner .= $buf if length($buf);
            Time::HiRes::sleep 0.1;
        }
        $banner =~ s/\r?\n$//;
        $result = "OK: $banner";
        $sock->close;
    } else {
        $result = "ERROR: $!";
    }
    return $result;
}

sub check_systat ($self, $server, $arg) {
    my $result;

    require LWP::UserAgent;

    my $error = 0;
    my $warning = 0;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(6);
    my $res = $ua->get("http://$server/status.json");
    if ($res->is_success) {
        $res = $res->decoded_content;
        $res = Mojo::JSON::decode_json($res);
        if ($res->{memory}) {
            push @{$result}, sprintf("m: %.2f", $res->{memory});
            if ($res->{memory} > 31/32) {
                $error = 1;
            } elsif ($res->{memory} > 15/16) {
                $warning = 1;
            }
        }
        if ($res->{swap}) {
            push @{$result}, sprintf("s: %.2f", $res->{swap});
        }
        if ($res->{ac}) {
            if ($res->{ac} == 1) {
                push @{$result}, 'AC';
            } else {
                push @{$result}, 'BA';
                $warning = 1;
            }
        }
        if ($res->{battery}) {
            push @{$result}, sprintf("b: %.2f", $res->{battery});
            if ($res->{battery} < 3/4) {
                $warning = 1;
            } elsif ($res->{battery} < 1/4) {
                $error = 1;
            }
        }
        if (defined($res->{load1}) && defined($res->{load5}) && defined($res->{load15})) {
            push @{$result}, sprintf("l: %s %s %s", $res->{load1}, $res->{load5}, $res->{load15});
            if ($res->{load1} > 4 || $res->{load5} > 2 || $res->{load15} > 1) {
                $error = 1;
            } elsif ($res->{load1} > 2 || $res->{load5} > 1 || $res->{load15} > 0.5) {
                $warning = 1;
            }
        }
        if ($res->{uptime}) {
            push @{$result}, sprintf("u: %s", $res->{uptime});
        }
        $result = join(' ', @{$result});
        if ($error) {
            $result = "ERROR: $result";
        } elsif ($warning) {
            $result = "WARNING: $result";
        } else {
            $result = "OK: $result";
        }
    } else {
        $result = sprintf("ERROR: %s", $res->status_line);
    }
    return $result;
}


sub run_checks ($self, $interval) {
    my @checks = $self->app->resultset('Checkit')->search(undef, { order_by => [qw/server test/] })->all;
    for my $check (@checks) {
        my $result;
        my $time = Time::HiRes::time;
        eval {
            my $test = 'check_'.$check->test;
            $result = $self->$test($check->server, $check->args);
        };
        if ($@) {
            $result = "ERROR: $@";
        }
        $check->update({ date => time, result => $result });
        $self->app->log->debug(sprintf("%s->run_checks %s %s: %s", ref($self), $check->server, $check->test, $result));
        if ($interval) {
            my $sleep = $time + $interval / scalar(@checks) - Time::HiRes::time;
            Time::HiRes::sleep($sleep) if $sleep > 0;
        }
    }
}

1;
