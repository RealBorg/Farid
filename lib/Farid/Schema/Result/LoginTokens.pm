use utf8;
package Farid::Schema::Result::LoginTokens;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("login_tokens");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "token",
  { data_type => "text", is_nullable => 0 },
  "created",
  { data_type => "timestamp", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("token");
__PACKAGE__->belongs_to(
  "user",
  "Farid::Schema::Result::Users",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-23 22:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V+UdSpdRKQCz3piIHdxpdw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
