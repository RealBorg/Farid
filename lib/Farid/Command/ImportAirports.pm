package Farid::Command::ImportAirports;
use Mojo::Base 'Mojolicious::Command', -signatures;

use IO::File;
use Text::CSV;

has description => 'import airports from private/airports.txt';
has usage => "Usage: $0 ImportAirports\n";

sub run ($self) {
    my $fh = $self->app->home->child('private', 'airports.csv')->open('r');
    die $@ unless $fh;
    my $schema = $self->app->schema;
    $schema->txn_do(sub {
        my $csv = Text::CSV->new({ auto_diag => 1, binary => 1 });
        $csv->column_names($csv->getline($fh));
        my $rs = $schema->resultset('Airports');
        while (my $row = $csv->getline_hr($fh)) {
            if ($row->{icao_code} && $row->{iso_country} && $row->{municipality} && $row->{name} && $row->{latitude_deg} && $row->{longitude_deg}) {
                $rs->create({
                    id => $row->{icao_code},
                    country => $row->{iso_country},
                    municipality => $row->{municipality},
                    name => $row->{name},
                    latitude => $row->{latitude_deg},
                    longitude => $row->{longitude_deg},
                });
            }
        }
    });
}

1;
