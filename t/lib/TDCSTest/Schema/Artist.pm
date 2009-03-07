package # hide from PAUSE
    TDCSTest::Schema::Artist;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
    qw<
        artistid
        name
    >
);

__PACKAGE__->set_primary_key('artistid');

1;
