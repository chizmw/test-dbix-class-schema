package # hide from PAUSE
    TDCSTest::Schema::Audiophile;

use base 'DBIx::Class::Core';

__PACKAGE__->table('audiophile');

__PACKAGE__->add_columns(
    qw<
        audiophileid
        name
    >
);

__PACKAGE__->set_primary_key('audiophileid');

1;
