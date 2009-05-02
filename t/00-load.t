#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 3;

BEGIN {
	use_ok( 'Net::Plurk::Dumper' );
}


my $p = Net::Plurk::Dumper->new( id => 'c9s');
ok( $p );
my $plurks = $p->fetch_plurks;
ok( $plurks );
