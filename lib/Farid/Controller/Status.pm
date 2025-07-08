package Farid::Controller::Status;

use File::Slurp;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub index ($self) {
    my $status;
    if (my $data = File::Slurp::read_file('/proc/meminfo', array_ref => 1, error_mode => 'quiet')) {
        my $meminfo;
        for (@{$data}) {
            if (/(\w+):\s+(\d+)\s+kB/) {
                $meminfo->{$1} = $2;
            }
        }
        if ($meminfo->{MemTotal}) {
            $status->{'memory'} = sprintf(
                '%.2f', 
                ($meminfo->{'MemTotal'} - $meminfo->{'MemAvailable'}) / $meminfo->{'MemTotal'},
            );
        }
        if ($meminfo->{SwapTotal}) {
            $status->{'swap'} = sprintf(
                '%.2f', 
                ($meminfo->{'SwapTotal'} - $meminfo->{'SwapFree'}) / $meminfo->{'SwapTotal'},
            );
        }
    }

    if (my $loadavg = File::Slurp::read_file('/proc/loadavg', array_ref => 1, error_mode => 'quiet')) {
        if ($loadavg->[0] =~ /^(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+/) {
            $status->{'load1'} = $1;
            $status->{'load5'} = $2;
            $status->{'load15'} = $3;
        }
    }

    if (my $uptime = read_file('/proc/uptime', err_mode => 'quiet')) {
        if ($uptime =~ /^(\d+)/) {
            $uptime = $1;
            $status->{uptime} = sprintf(
                "%sd%sh%sm%ss",
                int($uptime / (24*60*60)),
                int(($uptime % (24*60*60)) / (60*60)),
                int(($uptime % (60*60)) / 60),
                int($uptime % 60),
            );
        }
    }

    {
        my $energy_full = read_file('/sys/class/power_supply/BAT0/energy_full', err_mode => 'quiet');
        my $energy_now = read_file('/sys/class/power_supply/BAT0/energy_now', err_mode => 'quiet');
        if ($energy_full && $energy_now) {
            chomp $energy_full;
            chomp $energy_now;
            $status->{'battery'} = sprintf("%.2f", $energy_now / $energy_full);
        }
    }

    if (my $ac = read_file('/sys/class/power_supply/AC0/online', err_mode => 'quiet')) {
        chomp $ac;
        if ($ac eq '1') {
            $status->{ac} = 1;
        } else {
            $status->{ac} = 0;
        }
    }
    $self->respond_to(
        html => { status => $status },
        json => { json => $status },
    );
}

1;
