package Foo;
use Class::Enum (
    key    => [ qw( id name) ],
    values => 1,
    const  => sub { uc $_->{name} },
    {
        id   => 0,
        name => 'twitter',
    },
    {
        id   => 1,
        name => 'facebook',
    },
);

package bar;
use Test::More;
use Test::Exception;
use strict;
use warnings;
use Scalar::Util qw(refaddr);

is_deeply +Foo->from_id(0), +{ id => 0, name => 'twitter' }, "key";

is_deeply scalar(Foo->values), [
    {
        id   => 0,
        name => 'twitter',
    },
    {
        id   => 1,
        name => 'facebook',
    },
], "values";

is +Foo::TWITTER()->{id}, 0, "constant";

subtest same_instance => sub {
    ok refaddr(Foo::TWITTER) == refaddr(Foo->from_id(0));
    ok refaddr(Foo::TWITTER) == refaddr(Foo->from_name('twitter'));
};

dies_ok { Foo->from_id(2) }, "not defined key";

done_testing;
