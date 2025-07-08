use utf8;
package Farid::Schema::Result::Users;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "displayname",
  { data_type => "text", is_nullable => 0 },
  "bio",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "website",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "location",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "source",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "login_tokens",
  "Farid::Schema::Result::LoginTokens",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "peers",
  "Farid::Schema::Result::Peers",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "postings",
  "Farid::Schema::Result::Postings",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2025-06-23 22:40:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8G/wP1HMavDNENvqO6ZyFg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
