#
# This file tests the schema used during testing
# It's a sanity check to make sure we're still testing against
# the data we think we have
#
use strict;
use warnings;  

use Test::More;
use lib qw(t/lib);
use TDCSTest;

# evil globals
my ($schema, $artist, $cd);

$schema = TDCSTest->init_schema();

plan tests => 13;

ok(defined $schema, q{schema object defined});

$artist = $schema->resultset('Artist')->find(1);
is($artist->name, q{Perlfish},
    q{artist is Perlfish});

$artist = $schema->resultset('Artist')->find(2);
is($artist->name, q{Fall Out Code},
    q{artist is Fall Out Code});

$artist = $schema->resultset('Artist')->find(3);
is($artist->name, q{Inside Outers},
    q{artist is Inside Outers});

$cd = $schema->resultset('CD')->find(1);
is($cd->title, q{Something Smells Odd},
    q{title is Something Smells Odd});
is($cd->year, 1999,
    q{year is 1999});
is($cd->artist->name, q{Perlfish},
    q{CD artist is Perlfish});

$cd = $schema->resultset('CD')->find(2);
is($cd->title, q{Always Strict},
    q{title is Always Strict});
is($cd->year, 2001,
    q{year is 2001});
is($cd->artist->name, q{Perlfish},
    q{CD artist is Perlfish});

$cd = $schema->resultset('CD')->find(3);
is($cd->title, q{Refactored Again},
    q{title is Refactored Again});
is($cd->year, 2002,
    q{year is 2002});
is($cd->artist->name, q{Fall Out Code},
    q{CD artist is Fall Out Code});
