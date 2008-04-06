package Test::DBIx::Class::Schema;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too
our $VERSION = '0.01003';

use Test::More;

sub new {
    my ($proto, $options) = @_;
    my $self = (defined $options) ? $options : {};
    bless $self, ref($proto) || $proto;
    return $self;
}

# for populating the correct part of $self
sub methods {
    my ($self, $hashref) = @_;

    $self->{methods} = $hashref;

    return;
}

sub run_tests {
    my ($self) = @_;
    my ($schema, $record, $resultset);

    $self->{num_tests} =
          7                             # fixed number of tests
        + @{ $self->{methods}->{columns}   }
        + @{ $self->{methods}->{relations} }
        + @{ $self->{methods}->{custom}    }
    ;

    plan tests => $self->{num_tests};

    # make sure we can use the schema (namespace) module
    use_ok( $self->{namespace} );

    # get a schema to query
    $schema = $self->{namespace}->connect(
        $self->{dsn}
    );
    isa_ok($schema, $self->{namespace});

    SKIP: {
        # if we don't have any records, it's pretty hard to test
        # available methods
        if (not $schema->resultset( $self->{moniker} )->search({})->count()) {
            if ($ENV{TEST_VERBOSE}) {
                diag qq{no records in $self->{moniker}};
            }
            skip
                qq{no records in $self->{moniker}},
                ($self->{num_tests} - 2)
            ;
        }

        # get an object to test methods against
        $record = $schema->resultset( $self->{moniker} )->search({})->first();
        isa_ok($record, $self->{namespace} . '::' . $self->{moniker});

        my @std_method_types = qw(columns relations custom);

        eval {
            $schema->txn_do(
                sub {
                    foreach my $method_type (@std_method_types) {
                        SKIP: {
                            if (not @{ $self->{methods}->{$method_type} }) {
                                skip qq{no $method_type methods}, 1;
                            }

                            can_ok(
                                $record,
                                @{ $self->{methods}->{$method_type} },
                            );
                            # try calling each method
                            foreach my $method ( @{ $self->{methods}->{$method_type} } ) {
                                eval { $record->$method };
                                is($@, q{}, qq{calling $method() didn't barf});
                            }
                        }
                    } # foreach

                    # resultset class methods - we need something slightly different here
                    SKIP: {
                        skip qq{no resultsets methods}, 1
                            unless @{ $self->{methods}->{resultsets} };

                        $resultset = $schema->resultset( $self->{moniker} )->search({});
                        can_ok(
                            $resultset,
                            @{ $self->{methods}->{resultsets} },
                        );
                    } # SKIP, no resultsets


                    # rollback any evil changes that crept through from the
                    # tested calls
                    $schema->txn_rollback;
                }
            )
        };
        if ($@) {
            warn $@;
        }

    } # SKIP, no records
}

=pod

=head1 NAME

Test::DBIx::Class::Schema - DBIx::Class schema sanity checking tests

=head1 DESCRIPTION

It's really useful to be able to test and confirm that DBIC classes have and
support a known set of methods.

Testing these one-by-one is more than tedious and likely to discourage you
from writing the relevant test scripts.

As a lazy person myself I don't want to write numerous near-identical scripts.

Test::DBIx::Class::Schema takes the copy-and-paste out of DBIC schema class testing.

=head1 SYNOPSIS

Create a test script that looks like this:

    #!/usr/bin/perl
    # vim: ts=8 sts=4 et sw=4 sr sta
    use strict;
    use warnings;

    # load the module that provides all of the common test functionality
    use Test::DBIx::Class::Schema;

    # create a new test object
    my $schematest = Test::DBIx::Class::Schema->new(
        {
            dsn       => 'dbi:Pg:dbname=mydb',
            namespace => 'MyDB::Schema',
            moniker   => 'SomeTable',
        }
    );

    # tell it what to test
    $schematest->methods(
        {
            columns => [
                qw[
                    id
                    column1
                    column2
                    columnX
                    foo_id
                ]
            ],

            relations => [
                qw[
                    foo
                ]
            ],

            custom => [
                qw[
                    some_method
                ]
            ],

            resultsets => [
                qw[
                ]
            ],
        }
    );

    # run the tests
    $schematest->run_tests();

Run the test script:

  prove -l t/schematest/xx.mydb.t

=head1 SEE ALSO

L<DBIx::Class>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

Copyright 2008 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
