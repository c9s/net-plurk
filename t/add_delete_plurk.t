#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use encoding 'utf8';
use Test::More;
use Net::Plurk;
use Text::Greeking::zh_TW;

unless ($ENV{NET_PLURK_TEST}) {
    plan skip_all => 'export NET_PLURK_TEST="$username $password" to run this test.';
}
my ($username, $password) = split " ", $ENV{NET_PLURK_TEST};

my $p = Net::Plurk->new;
$p->login($username, $password);

my $text = Text::Greeking::zh_TW->new;
$text->paragraphs(1);
$text->sentences(1);
$text = substr($text->generate, 0, 90);

my $pu = $p->add_plurk(content => "$text Testing Net::Plurk...");

is(ref($pu), "HASH");

ok($pu->{plurk}{id} > 0);

my $deleted = $p->delete_plurk($pu->{plurk}{id});

is($deleted, "ok", "delete_plurk should respond \"ok\"");

done_testing;
