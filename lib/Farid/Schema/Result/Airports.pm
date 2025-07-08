use utf8;
package Farid::Schema::Result::Airports;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("airports");
__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "country",
  { data_type => "text", is_nullable => 0 },
  "municipality",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "latitude",
  { data_type => "real", is_nullable => 0 },
  "longitude",
  { data_type => "real", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-11 21:53:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WlqBwWu1MvrQWvo71YSe4w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
