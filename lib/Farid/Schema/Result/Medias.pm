use utf8;
package Farid::Schema::Result::Medias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("medias");
__PACKAGE__->add_columns(
  "posting_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "filename",
  { data_type => "text", is_nullable => 0 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("filename");
__PACKAGE__->belongs_to(
  "posting",
  "Farid::Schema::Result::Postings",
  { id => "posting_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-23 22:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LTq8/hmXCs3+IctBMDf1YA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
