#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Net::Plurk;
use encoding 'utf8';

unless ($ENV{NET_PLURK_TEST}) {
    plan skip_all => 'export NET_PLURK_TEST="$username $password" to run this test.';
}
my ($username, $password) = split " ", $ENV{NET_PLURK_TEST};

my $p = Net::Plurk->new;
$p->login($username, $password);

my $data = $p->get_own_profile_data;

is(ref($data), "HASH");

is(ref($data->{users}), "HASH");
is(ref($data->{unread_plurks}), "ARRAY");
is(ref($data->{plurks}), "ARRAY");

is(ref($p->{heap}{users}), "HASH");

for(keys %{$data->{users}}) {
    is_deeply(
        $p->{heap}{users}{$_},
        $data->{users}{$_},
        "user info is merged into the heap"
    );
}

done_testing;
