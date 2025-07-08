use utf8;
package Farid::Schema::Result::Aviationweather;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("aviationweather");
__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "text",
  { data_type => "text", is_nullable => 0 },
  "date",
  { data_type => "bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id", "type");


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-11 21:53:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FklV1QzIk/kZ/1fFQCBnvg

use feature 'signatures';

sub decode {
    my ($self, $airport) = @_;
    
    my @text = split(/\s+/, $self->text);
    unshift @text, 'METAR' unless $text[0] eq 'TAF';
    my $location = $text[1];
    my $id = $airport->{'id'};
    my $municipality = $airport->{'municipality'};
    foreach (@text) {
        if (s/^$id$/for $municipality/) {
        } elsif (s/^(\d\d)(\d\d)(\d\d)Z$/issued on $1 at $2$3.\n/) {
        } elsif (/^(\d\d\d\d)$/) {
            $_ = "Visibility ";
            if ($1 == 9999) {
                $_ .= "10 kilometers or more.\n";
            } else {
                if (int($1 / 1000) > 0) {
                    $_ .= sprintf("%i Thousand", int($1 / 1000));
                }
                if ($1 % 1000 > 0) {
                    $_ .= sprintf("%i Hundred", $1 % 1000 / 100);
                }
                $_ .= " Meters.\n";
            }
        } elsif (/^(\d\d\d)(\d\d)(?:G(\d\d))?KT/) {
            $_ = sprintf("Wind %s Degrees at %i", $1, $2);
            if ($3) {
                $_ .= sprintf(" Gusting %i", $3);
            }
            $_ .= " knots.\n";
        } if (s/^AUTO$//) {
        } elsif (/^([+-])?(BC|BR|DZ|FG|FZ|GS|GR|HA|RA|RE|SA|SH|SN|TS)+/) {
            s/^[+]/ Heavy /;
            s/^[-]/ Light /;
            s/BC/ Patches of /;
            s/BR/ Mist /;
            s/DZ/ Drizzle /;
            s/FG/ Fog /;
            s/FZ/ Freezing /;
            s/GR/ Hail /;
            s/GS/ Snow Pellets /;
            s/HA/ Haze /;
            s/RA/ Rain /;
            s/RE/ Recent /;
            s/SA/ Sand /;
            s/SH/ Showers of /;
            s/SN/ Snow /;
            s/TS/ Thunderstorm /;
            s/VC/ Vicinity /;
            $_ .= ".\n";
        } elsif (s/^BECMG$/Becoming/) {
        } elsif (/^(BKN|FEW|OVC|SCT)(\d\d\d)/) {
            if ($1 eq 'FEW') {
                $_ = "Few ";
            } elsif ($1 eq 'SCT') {
                $_ = "Scattered ";
            } elsif ($1 eq 'BKN') {
                $_ = "Broken ";
            } elsif ($1 eq 'OVC') {
                $_ = "Overcast ";
            }

            if ($2 > 10) {
                $_ .= sprintf("%i Thousand ", $2 / 10);
            }
            if ($2 % 10 > 0) {
                $_ .= sprintf("%i Hundred ", $2 % 10);
            }
            if ($2 == 0) {
                $_ .= "0";
            }
            $_ .= "Feet.\n";
        } elsif (s/^CAVOK$/Ceiling and Visibility OK.\n/) {
        } elsif (/(\d\d\d)V(\d\d\d)/) {
            $_ = sprintf("Wind Varying Between %i and %i Degrees.\n", $1, $2);
        } elsif (s/(\d\d\d\d)\/(\d\d\d\d)/from $1 to $2.\n/) {
        } elsif (s/^METAR$/Current Conditions/) {
        } elsif (/^(M?\d\d)\/(M?\d\d)$/) {
            my $t = $1;
            my $d = $2;
            $t =~ s/M/ minus /;
            $d =~ s/M/ minus /;
            $_ = sprintf("Temperature %i, Dew Point %i.\n", $t, $d);
        } elsif (s/^NOSIG$/No Significant Change Expected.\n/) {
        } elsif (s/^NSC$/No Significant Clouds.\n/) {
        } elsif (s/^NSW$/No Significant Weather.\n/) {
        } elsif (s/^FM/from /) {
        } elsif (s/^PROB(\d\d)/Probability $1.\n/) {
        } elsif (s/^Q(\d\d\d\d)/QNH $1.\n/) {
        } elsif (s/^TAF$/Forecast/) {
        } elsif (s/^TEMPO/Temporary Conditions/) {
        } elsif (/^TN(M?\d\d)\/(\d\d)(\d\d)Z$/) {
            my $t = $1;
            my $d = "$2$3";
            $t =~ s/M/-/;
            $_ = sprintf("Minimum Temperature %i at %s.\n", $t, $d);
        } elsif (/^TX(M?\d\d)\/(\d\d)(\d\d)Z$/) {
            my $t = $1;
            my $d = "$2$3";
            $t =~ s/M/minus /;
            $_ = sprintf("Maximum Temperature %s at %s.\n", $t, $d);
        } elsif (/^VRB(\d\d)KT/) {
            $_ = sprintf("Wind Variable at %s Knots.\n", $1);
        } elsif (/^VV(\d\d\d)/) {
            $_ = sprintf("Vertical Visibility %s Hundred Feet.\n", $1);
        }
    }
	$_ = join(" ", @text);
    #s/000/ thousand /g;
    #s/00/ hundred /g;
    s/0/ Zero /g;
    s/1/ One /g;
    s/2/ Two /g;
    s/3/ Three /g;
    s/4/ Four /g;
    s/5/ Five /g;
    s/6/ Six /g;
    s/7/ Seven /g;
    s/8/ Eight /g;
    s/9/ Nine /g;
    s/ +/ /g;
    s/ ([.,])/$1/g;
    s/^ +//gm;
    return $_;
}

1;
