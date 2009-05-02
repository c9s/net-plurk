#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Plurk::Dumper' );
}

diag( "Testing Net::Plurk::Dumper $Net::Plurk::Dumper::VERSION, Perl $], $^X" );
