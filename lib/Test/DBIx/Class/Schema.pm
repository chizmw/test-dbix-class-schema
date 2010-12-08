package Test::DBIx::Class::Schema;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too
our $VERSION = '0.01008';

# ensure we have "done_testing"
use Test::More 0.92;

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

    # make sure we can use the schema (namespace) module
    use_ok( $self->{namespace} );

    # let users pass in an existing $schema if they (somehow) have one
    if (defined $self->{schema}) {
        $schema = $self->{schema};
    }
    else {
        # get a schema to query
        $schema = $self->{namespace}->connect(
            $self->{dsn},
            $self->{username},
            $self->{password},
        );
    }
    isa_ok($schema, $self->{namespace});

    # create a new resultset object and perform tests on it
    # - this allows us to test ->my_column() without requiring data
    my $rs = $schema->resultset( $self->{moniker} )->new({});
    $self->_test_normal_methods($rs);
    $self->_test_special_methods($rs);
    $self->_test_resultset_methods($rs);

    # get an object to test methods against
    #   changed from ->first() to ->slice()->single() at dakkar's reqest
    #   he say's it's faster
    $record = $schema->resultset( $self->{moniker} )
                ->search({})
                ->slice(0,0)
                ->single();

    # no actual records - don't test against nothingness
    SKIP: {
        skip q{no records in the table}, 1
            if (not defined $record);

        # run tests on real records
        if (defined $self->{glue}) {
            isa_ok(
                $record,
                  $self->{namespace}
                . '::' . $self->{glue}
                . '::' . $self->{moniker}
            );
        }
        else {
            isa_ok($record, $self->{namespace} . '::' . $self->{moniker});
        }
        eval {
            $schema->txn_do(
                sub {
                    # 'normal' methods; row & relation
                    # we can try calling these as they gave no side-effects
                    $self->_test_normal_methods($record);
                    $self->_test_special_methods($record);
                    $self->_test_resultset_methods($record);


                    # rollback any evil changes that crept through from the
                    # tested calls
                    $schema->txn_rollback;
                }
            )
        };
        if (my $e=$@) {
            warn $e;
        }
    }; # end SKIP

    done_testing
        unless $ENV{TEST_AGGREGATE};
}

sub _test_normal_methods {
    my $self    = shift;
    my $record  = shift;

    my @std_method_types        = qw(columns relations);

    # 'normal' methods; row & relation
    # we can try calling these as they gave no side-effects
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
    return;
}

sub _test_special_methods {
    my $self    = shift;
    my $record  = shift;

    my @special_method_types    = qw(custom);

    # 'special' methods; custom
    # we can't call these as they may have unknown parameters,
    # side effects, etc
    foreach my $method_type (@special_method_types) {
        SKIP: {
            if (not @{ $self->{methods}->{$method_type} }) {
                skip qq{no $method_type methods}, 1;
            }

            can_ok(
                $record,
                @{ $self->{methods}->{$method_type} },
            );
        }
    } # foreach
    return;
}

sub _test_resultset_methods {
    my $self        = shift;
    my $schema      = shift->result_source->schema;
    my $resultset   = $schema->resultset( $self->{moniker} );

    my @resultset_method_types  = qw(resultsets);

    # resultset class methods - we need something slightly different here
    foreach my $method_type (@resultset_method_types) {
        SKIP: {
            skip qq{no resultsets methods}, 1
                unless @{ $self->{methods}->{resultsets} };

            can_ok(
                $resultset,
                @{ $self->{methods}->{resultsets} },
            );
        } # SKIP, no resultsets
    } # foreach
    return;
}

1;
__END__

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
            # required
            dsn       => 'dbi:Pg:dbname=mydb',
            namespace => 'MyDB::Schema',
            moniker   => 'SomeTable',
            # optional
            username  => 'some_user',
            password  => 'opensesame',
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

=head2 done_testing

Under normal circumstances there is no need to add C<done_testing> to your
test script; it's automatically called at the end of C<run_tests()> I<unless>
you are running tests under L<Test::Aggregate>.

If you are running aggregated tests you will need to add

  done_testing;

to your top-level script.

=head1 SEE ALSO

L<DBIx::Class>,
L<Test::More>,
L<Test::Aggregate>

=head1 AUTHOR

Chisel Wright C<< <chisel@chizography.net> >>

=head1 CONTRIBUTORS

Gianni Ceccarelli C<< <dakkar@thenautilus.net> >>

=head1 LICENSE

Copyright 2008-2010 by Chisel Wright

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
