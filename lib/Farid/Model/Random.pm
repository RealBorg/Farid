package Farid::Model::Random;
use IO::File;

sub alnum {
    my ($self, $length) = @_;

    return $self->map($self->bytes($length), [0..9,'a'..'z','A'..'Z']);
}

sub bytes {
    my ($self, $length) = @_;

    my $fh = IO::File->new('/dev/urandom', O_RDONLY);
    die $! unless $fh;
    my $random;
    my $bytes_read = $fh->sysread($random, $length);
    die unless $bytes_read == $length;
    return $random;
}

sub hex {
    my ($self, $length) = @_;
    return $self->map($self->bytes($length), [0..9,'a'..'f']);
}

sub map {
    my ($self, $bytes, $charset) = @_;

    my $length = length($bytes);
    my $char_count = scalar(@{$charset});
    $bytes = [ unpack("C$length", $bytes) ];
    $bytes = [ map($_ % $char_count, @{$bytes}) ];
    $bytes = [ map($charset->[$_], @{$bytes}) ];
    $bytes = join('', @{$bytes});
    return $bytes;
}

sub num {
    my ($self, $length) = @_;
    return $self->map($self->bytes($length), [0..9]);
}

1;
