package # hide from PAUSE
    TDCSTest;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use TDCSTest::Schema;

# lifted from DBIx::Class' DBICTest.pm
sub _database {
    my $self = shift;
    my $db_file = "t/var/DBIxClass.db";

    unlink($db_file) if -e $db_file;
    unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn = $ENV{"DBICTEST_DSN"} || "dbi:SQLite:${db_file}";
    my $dbuser = $ENV{"DBICTEST_DBUSER"} || '';
    my $dbpass = $ENV{"DBICTEST_DBPASS"} || '';

    my @connect_info = ($dsn, $dbuser, $dbpass, { AutoCommit => 1 });

    return @connect_info;
}

# lifted from DBIx::Class' DBICTest.pm
sub init_schema {
    my $self = shift;
    my %args = @_;

    my $schema;

    if ($args{compose_connection}) {
      $schema = TDCSTest::Schema->compose_connection(
                  'TDCSTest', $self->_database
                );
    } else {
      $schema = TDCSTest::Schema->compose_namespace('TDCSTest');
    }
    if ( !$args{no_connect} ) {
      $schema = $schema->connect($self->_database);
      $schema->storage->on_connect_do(['PRAGMA synchronous = OFF']);
    }
    if ( !$args{no_deploy} ) {
        __PACKAGE__->deploy_schema( $schema );
        __PACKAGE__->populate_schema( $schema ) if( !$args{no_populate} );
    }
    return $schema;
}

# lifted from DBIx::Class' DBICTest.pm
sub deploy_schema {
    my $self = shift;
    my $schema = shift;

    if ($ENV{"DBICTEST_SQLT_DEPLOY"}) {
        return $schema->deploy();
    } else {
        open IN, "t/lib/sqlite.sql";
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        ($schema->storage->dbh->do($_) || print "Error on SQL: $_\n") for split(/;\n/, $sql);
    }
}

sub populate_schema {
    my $self    = shift;
    my $schema  = shift;

    # let's have some artists
    $schema->populate(
        'Artist',
        [
            [ qw/artistid name/ ],

            [ 1, 'Perlfish' ],
            [ 2, 'Fall Out Code' ],
            [ 3, 'Inside Outers' ],
            [ 4, 'Chisel' ],
        ],
    );

    # let's have some CDs
    $schema->populate(
        'CD',
        [
            [ qw/cdid artistid title year/ ],

            [ 1, 1, 'Something Smells Odd', 1999 ],
            [ 2, 1, 'Always Strict', 2001 ],
            [ 3, 2, 'Refactored Again', 2002 ],
            [ 4, 4, 'Tocata in Chisel', 2011 ],
        ],
    );

    # let's have some Tracks
    $schema->populate(
        'Track',
        [
            [ qw/trackid cdid title position/ ],

            [ 1, 4, 'Chisel Suite (part 1)', 1 ],
            [ 2, 4, 'Chisel Suite (part 2)', 2 ],
            [ 3, 4, 'Chisel Suite (part 3)', 3 ],
        ],
    );

    $schema->populate(
        'Shop',
        [
            [ qw/shopid name/ ],

            [ 1, 'Potify' ],
            [ 2, 'iTunez' ],
            [ 3, 'Media Mangler' ],
        ],
    );

    $schema->populate(
        'Audiophile',
        [
            [ qw/audiophileid name/ ],

            [ 1, 'Chisel' ],
            [ 2, 'Darius' ],
        ],
    );
}

1;
