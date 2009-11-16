#!/usr/bin/env perl
use common::sense;
use Test::More;
use Net::Plurk;

plan(skip_all => 'export NET_PLURK_TEST="$username $password" to run this test.') unless ($ENV{NET_PLURK_TEST});

my ($username, $password) = split " ", $ENV{NET_PLURK_TEST};

my $p = Net::Plurk->new;
$p->login($username, $password);

is(ref($p->meta->{friends}), "HASH");
is(ref($p->meta->{fans}),    "HASH");

done_testing;
