package Farid::Checkit;

use Farid::Log;
use Farid::Schema;
use Farid::Util;
use IO::Socket::IP;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;
use JSON;
use LWP::UserAgent;
use Net::DNS;
use Net::NTP;
use Socket;
use Time::HiRes;

sub check_daytime {
    my ($self, $server) = @_;
    my $result = '';

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

sub check_dns {
    my ($self, $server, $name) = @_;

    my $result;

    my $resolver = Net::DNS::Resolver->new;
    $resolver->nameservers($server);
    my $response = $resolver->query($name, "A");
    if ($response) {
        $response = [ $response->answer ];
        $response = [ map($_->address, @{$response}) ];
        $response = [ sort( { inet_aton($a) cmp inet_aton($b) } @{$response}) ];
        $result = "OK: " . join(", ", @{$response});
    } else {
        $result = "ERROR: ", $resolver->errorstring;
    }
    return $result;
}

sub check_http {
    my ($self, $server) = @_;
    my $result;

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

sub check_https {
    my ($self, $server) = @_;
    my $result;

    my $sock = IO::Socket::SSL->new(
        PeerHost => $server,
        PeerPort => 443,
    );
    if ($sock) {
        my $cert = $sock->peer_certificate;
        $cert = CERT_asHash($cert);
        my $not_after = $cert->{not_after};
        $result = Farid::Util->s2datetime($not_after);
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

sub check_ntp {
    my ($self, $server) = @_;
    my $result;

    my $response;
    eval {
        $response = { Net::NTP::get_ntp_response($server) };
    };
    if ($response) {
        $result = sprintf("OK: %s %.3f %i %s",
            Farid::Util->s2datetime($response->{'Destination Timestamp'}),
            $response->{Offset},
            $response->{Stratum},
            $response->{'Reference Clock Identifier'},
        );
    } else {
        $result = "ERROR: $@";
    }
    return $result;
}

sub check_smtp {
    my ($self, $server) = @_;
    my $result = '';

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

sub check_ssh {
    my ($self, $server) = @_;
    my $result;

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

sub check_systat {
    my ($self, $server) = @_;
    my $result;
    my $error = 0;
    my $warning = 0;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(6);
    my $res = $ua->get("http://$server/status.json");
    if ($res->is_success) {
        $res = $res->decoded_content;
        $res = JSON::decode_json($res);
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

sub get_checks {
    my ($self) = @_;

    my @checks = Farid::DB->dbix->query('SELECT * FROM checkit')->hashes;

    return @checks;
}

sub run_checks {
    my ($self, $interval) = @_;

    my $rs = Farid::Schema->connect->resultset('Checkit');
    my $count = $rs->count;
    for my $check ($rs->search(undef, { order_by => [qw/server test/] })->all) {
        my $result;
        my $time = time;
        eval {
            my $test = 'check_'.$check->test;
            $result = $self->$test($check->server, $check->args);
        };
        if ($@) {
            $result = "ERROR: $@";
        }
        $check->update({ date => time, result => $result });
        Farid::Log->debug("%s->run_checks %s %s: %s", $self, $check->server, $check->test, $result);
        if ($interval) {
            my $sleep = time - $time + ($interval / $count);
            warn $sleep;
            sleep $sleep;
        }
    }
}

1;
