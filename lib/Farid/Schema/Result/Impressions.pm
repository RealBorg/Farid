use utf8;
package Farid::Schema::Result::Impressions;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("impressions");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "ip",
  { data_type => "inet", is_nullable => 0 },
  "path",
  { data_type => "text", is_nullable => 0 },
  "referer",
  { data_type => "text", is_nullable => 0 },
  "server",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-11 21:53:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e5OpjukAiC+4PUneyXWYLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
