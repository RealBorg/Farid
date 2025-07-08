use utf8;
package Farid::Schema::Result::Postings;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("postings");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "xid",
  { data_type => "bigint", is_nullable => 1 },
  "text",
  { data_type => "text", is_nullable => 0 },
  "lang",
  { data_type => "char", default_value => "", is_nullable => 0, size => 3 },
  "parent",
  { data_type => "bigint", is_nullable => 1 },
  "user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "medias",
  "Farid::Schema::Result::Medias",
  { "foreign.posting_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "user",
  "Farid::Schema::Result::Users",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-23 22:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZMriiR4ubrJyOB/NbOMFZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
