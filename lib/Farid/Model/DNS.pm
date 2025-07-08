package Farid::Model::DNS;

use Farid::Schema;
use File::Slurp;
use Net::DNS;
use POSIX;
use Sys::Hostname qw//;
use Sys::Syslog;

use strict;
use warnings;

my $resultset;

sub resultset {
    unless ($resultset) {
        $resultset = Farid::Schema->connect->resultset('Dns') 
    }
    return $resultset;
}

sub reply {
    my ($self, $query, $peer) = @_;

    return undef unless $query;

    unless (ref($query) eq 'Net::DNS::Packet') {
        $query = Net::DNS::Packet->new(\$query);
    }
    return undef unless $query && 
        $query->header->opcode eq 'QUERY' && 
        $query->header->qr == 0 && 
        $query->header->qdcount > 0;

    my $reply;
    for my $question ($query->question) {
        Sys::Syslog::syslog("debug", "%s %s", $peer, $question->string);
        if ($self->resultset->search({ name => lc($question->qname) })->count) {
            unless ($reply) {
                $reply = $query->reply($query);
                $reply->header->rcode('NOERROR');
                $reply->header->aa(1);
            }
            my @answer = $self->get_records($question->qname, $question->qclass, $question->qtype);
            my @additional;
            if ($question->qtype eq 'A') {
                @additional = $self->get_records($question->qname, 'IN', 'AAAA');
            } elsif ($question->qtype eq 'AAAA') {
                @additional = $self->get_records($question->qname, 'IN', 'A');
            } elsif ($question->qtype eq 'MX') {
                for (@answer) {
                    push @additional, $self->get_records($_->exchange, 'IN', 'A');
                    push @additional, $self->get_records($_->exchange, 'IN', 'AAAA');
                }
            } elsif ($question->qtype eq 'NS') {
                for (@answer) {
                    push @additional, $self->get_records($_->nsdname, 'IN', 'A');
                    push @additional, $self->get_records($_->nsdname, 'IN', 'AAAA');
                }
            }
            for (@answer, @additional) {
                Sys::Syslog::syslog("debug", "%s %s", $peer, $_->string);
            }
            $reply->push(answer => @answer);
            $reply->push(additional => @additional);
        }
    }
    return $reply;
}

sub get_records {
    my ($self, $qname, $qclass, $qtype) = @_;

    my @result;
    my $resultset = $self->resultset;
    if ($qtype eq 'AXFR') {
    } elsif ($qtype eq 'ANY') {
    } else {
        $resultset = $resultset->search(
            {
                name => lc($qname),
                class => $qclass,
                type => $qtype,
            },
            {
                order_by => \'RANDOM()',
            }
        );
        for my $row ($resultset->all) {
            my $rr = Net::DNS::RR->new(sprintf("%s %s %s %s", $qname, $qclass, $qtype, $row->data));
            if ($qtype eq 'MX') {
                $rr->preference(10) unless $rr->preference;
                $rr->exchange($rr->owner) unless $rr->exchange;
            } elsif ($qtype eq 'NS') {
                $rr->nsdname($rr->owner) unless $rr->nsdname;
            } elsif ($qtype eq 'SOA') {
                $rr->mname($rr->owner) unless $rr->mname;
                $rr->rname('hostmaster.'.$rr->owner) unless $rr->rname;
                $rr->serial(time()) unless $rr->serial;
                $rr->refresh(24*60*60) unless $rr->refresh;
                $rr->retry(60*60) unless $rr->retry;
                $rr->expire(365*24*60*60) unless $rr->expire;
                $rr->minimum(60*60) unless $rr->minimum;
            }
            $rr->ttl(60*60) unless $rr->ttl;
            push @result, $rr;
        }
    }
    return @result;
}

1;
