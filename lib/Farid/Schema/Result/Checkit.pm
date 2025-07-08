use utf8;
package Farid::Schema::Result::Checkit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("checkit");
__PACKAGE__->add_columns(
  "server",
  { data_type => "text", is_nullable => 0 },
  "test",
  { data_type => "text", is_nullable => 0 },
  "args",
  { data_type => "text", is_nullable => 0 },
  "date",
  { data_type => "integer", is_nullable => 1 },
  "result",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("server", "test");


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-11 21:53:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hjWhIFU6LMxMzcEMvAtV0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
