package # hide from PAUSE
    TDCSTest::Schema::Track;

use base 'DBIx::Class::Core';

__PACKAGE__->table('track');

__PACKAGE__->add_columns(
    qw<
        trackid
        cd
        position
        title
    >
);

__PACKAGE__->set_primary_key('trackid');

1;
