package # hide from PAUSE
    TDCSTest::Schema::CD;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cd');

__PACKAGE__->add_columns(
    qw<
        cdid
        artist
        title
        year
    >
);

__PACKAGE__->set_primary_key('cdid');

__PACKAGE__->belongs_to( artist => 'TDCSTest::Schema::Artist' );


1;
