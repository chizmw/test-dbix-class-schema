package Test::DBIx::Class::Schema;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

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
    my ($schema, $rs, $record);

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
    $rs = $schema->resultset( $self->{moniker} );
    $record = $schema->resultset( $self->{moniker} )->new({});

    # make sure our record presents itself as the correct object type
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

    $self->_test_normal_methods($rs);
    $self->_test_special_methods($record);
    $self->_test_resultset_methods($rs);

    done_testing
        unless $ENV{TEST_AGGREGATE};
}

sub _test_normal_methods {
    my $self    = shift;
    my $rs  = shift;

    my @std_method_types        = qw(columns relations);

    # 'normal' methods; row & relation
    # we can try calling these as they gave no side-effects
    my @proxied;
    foreach my $method_type (@std_method_types) {
        SKIP: {
            if (not @{ $self->{methods}->{$method_type} }) {
                skip qq{no $method_type methods}, 1;
            }

            # try calling each method
            foreach my $method ( @{ $self->{methods}->{$method_type} } ) {
                # make sure we can call the method
                my $source = $rs->result_source;

                # 'normal' relationship
                if ($source->has_relationship($method)) {
                    eval {
                        my $related_source = $source->related_source($method);
                    };
                    is($@, q{}, qq{related source for '$method' OK});

                    next; # skip the tests that don't apply (below)
                }

                # many_to_many and proxy
                if ( $method_type eq 'relations' ) {
                    $DB::single=1 if $method eq 'currency';
                    my $result = $rs->new({});
                    if (can_ok( $result, $method )) {
                        my @relationships = $source->relationships;
                        my $is_proxied;
                        for my $relationship ( @relationships ) {
                            my $proxy =
                                $source->relationship_info($relationship)->{attrs}{proxy};
                            # If the relationship is proxied then we assume it
                            # works if we can call it, and it should be tested
                            # in the related result source
                            next if not $proxy;
                            $is_proxied = 1;
                            pass qq{'$method' relationship exists via proxied relationship '$relationship'};
                            last;
                        }
                        # many_to_many
                        isa_ok( $result->$method, 'DBIx::Class::ResultSet')
                            if not $is_proxied;
                    }
                }

                # column accessor
                elsif ( $method_type eq 'columns' ) {
                    if ( $source->has_column($method) ) {
                        pass qq{'$method' column defined in result_source};
                        eval {
                            my $col = $rs->get_column($method)->all;
                        };
                        is($@, q{}, qq{'$method' column exists in database});
                    }
                    else {
                        my @relationships = $source->relationships;
                        for my $relationship ( @relationships ) {
                            my $proxy =
                                $source->relationship_info($relationship)->{attrs}{proxy};
                            next if not $proxy;
                            if ( grep m{$method}, @$proxy ) {
                                eval { $rs->new({})->$method; };
                                is($@, q{}, qq{'$method' column exists via proxied relationship '$relationship'});
                            }
                            else {
                                fail qq{'$method' column does not exist and is not proxied};
                            }
                            last;
                        }
                    }
                    #ok($source->has_column($method), qq{$method: column defined in result_source});
                }

                # ... erm ... what's this?
                else {
                    die qq{unknown method type: $method_type};
                }
            }
        }
    } # foreach
    return;
}

sub _test_special_methods {
    shift->_test_methods(shift, [qw/custom/]);
}

sub _test_resultset_methods {
    shift->_test_methods(shift, [qw/resultsets/]);
}

sub _test_methods {
    my $self            = shift;
    my $thingy          = shift;
    my $method_types    = shift;

    # 'special' methods; custom
    # we can't call these as they may have unknown parameters,
    # side effects, etc
    foreach my $method_type (@{ $method_types} ) {
        SKIP: {
            skip qq{no $method_type methods}, 1
                    unless @{ $self->{methods}{$method_type} };
            ok(
                @{ $self->{methods}{$method_type} },
                qq{$method_type list found for testing}
            );
        }

        # call can on each method to make it obvious what's being tested
        foreach my $method (@{ $self->{methods}{$method_type} } ) {
            can_ok( $thingy, $method );
        }
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

=head1 CONTRIBUTORS

Gianni Ceccarelli C<< <dakkar@thenautilus.net> >>,
Darius Jokilehto

=cut
