use utf8;
package Farid::Schema::Result::Dns;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("dns");
__PACKAGE__->add_columns(
  "name",
  { data_type => "text", is_nullable => 0 },
  "class",
  { data_type => "text", is_nullable => 0 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "data",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("name", "class", "type", "data");


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-26 11:06:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:msyOdq1e/08woEphAhlBaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
