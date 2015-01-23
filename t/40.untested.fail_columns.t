use strict;
use warnings;
use Test::More 0.92;
use Test::Builder::Tester;

use Test::DBIx::Class::Schema;

use lib 't/lib';
use UnexpectedTest;

# we plan the number of tests so that we don't get ourselves into trouble with
# done_testing being called multiple times
plan tests => 10;

# evil globals
my ($schema);

$schema = UnexpectedTest->init_schema();
isa_ok($schema, 'UnexpectedTest::Schema');

# create a new test object
my $schematest = Test::DBIx::Class::Schema->new({
    # required
    schema    => $schema,
    namespace => 'UnexpectedTest::Schema',
    moniker   => 'SpanishInquisition',
    test_missing => 1,
});
isa_ok($schematest, 'Test::DBIx::Class::Schema');

# setup columns to test
$schematest->methods({
    columns => [qw(id name)],
    relations => [],
    custom => [],
    resultsets => [],
});


FORGOT_TO_TEST: {
    # stop testing one of the columns we know we have defined
    $schematest->methods({
        columns     => [qw(id)],
        relations   => [],
        custom      => [],
        resultsets  => [],
    });

    test_out(
        q{ok 1 - use UnexpectedTest::Schema;},
        q{ok 2 - The object isa UnexpectedTest::Schema},
        q{ok 3 - The record object is a ::SpanishInquisition},
        q{ok 4 - 'id' column defined in result_source},
        q{ok 5 - 'id' column exists in database},
        q{ok 6 # skip no relations methods},
        q{ok 7 # skip no custom methods},
        q{ok 8 # skip no resultsets methods},
        q{not ok 9 - All known columns defined in test},
        q{ok 10 - All known relations defined in test},
    );


# ok 1 - use UnexpectedTest::Schema;
# ok 2 - The object isa UnexpectedTest::Schema
# ok 3 - The record object is a ::SpanishInquisition
# ok 4 - 'id' column defined in result_source
# ok 5 - 'id' column exists in database
# ok 6 # skip no relations methods
# ok 7 # skip no custom methods
# ok 8 # skip no resultsets methods
# not ok 9 - planned to run 4 but done_testing() expects 8

    test_err(
    "#   Failed test 'All known columns defined in test'",
    "#   at /home/jason/git/public/test-dbix-class-schema/lib/Test/DBIx/Class/Schema.pm line 237.",
    "#          got: '1'",
    "#     expected: '0'",
    "# Defined in schema class but untested - name",
    );

    $schematest->run_tests();

    test_test(title => 'test output as expected for untested column');
}

# DO NOT USE: done_testing;
