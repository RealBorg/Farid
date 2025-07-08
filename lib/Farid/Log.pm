package Farid::Log;

use Sys::Syslog;

BEGIN {
    Sys::Syslog::openlog(__PACKAGE__, 'nofatal,perror,pid', 'daemon');
}

sub debug {
    my ($self, @message) = @_;
    Sys::Syslog::syslog(LOG_DEBUG, @message) if $self->is_debug;
}

sub info {
    my ($self, @message) = @_;
    Sys::Syslog::syslog(LOG_INFO, @message);
}

sub is_debug {
    my ($self) = @_;

    return 1;
}

sub warn {
    my ($self, @message) = @_;
    Sys::Syslog::syslog(LOG_WARNING, @message);
}

sub error {
    my ($self, @message) = @_;
    Sys::Syslog::syslog(LOG_ERR, @message);
}

sub fatal {
    my ($self, @message) = @_;
    Sys::Syslog::syslog(LOG_CRIT, @message);
}

1;
