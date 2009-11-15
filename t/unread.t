#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAML;
use Net::Plurk;
use encoding 'utf8';

unless ($ENV{NET_PLURK_TEST}) {
    plan skip_all => 'export NET_PLURK_TEST="$username $password" to run this test.';
}
my ($username, $password) = split " ", $ENV{NET_PLURK_TEST};

my $p = Net::Plurk->new;
$p->login(username => $username, password => $password);

my $plurks = $p->get_unread_plurks;

is(ref($plurks), "ARRAY", "The return value of get_unread_plurks is an arrayref of plurks");

for(@$plurks) {
    is(ref($_), "HASH", "... this plurk is a hash");
    is(ref($_->{owner}), "HASH", "... this plurk joins 'owner' info as a hash");
    ok($_->{owner}{id} > 0, ".. the owner uid seems to be correct.");
}

done_testing;
