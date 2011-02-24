package # hide from PAUSE
    TDCSTest::Schema::Person;

use base 'DBIx::Class::Core';

__PACKAGE__->table('person');

__PACKAGE__->add_columns(
    qw<
        personid
        name
    >
);

__PACKAGE__->set_primary_key('personid');

__PACKAGE__->has_many(
    cdshop_audiophiles => 'CDShopAudiophile',
    { 'foreign.personid' => 'self.personid' },
);

1;
