#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 7;

BEGIN {
	use_ok( 'Net::Plurk::Dumper' );
}


my $p = Net::Plurk::Dumper->new( id => 'jserv');
ok( $p );
my $plurks = $p->fetch_plurks;
ok( $plurks );

my $plurk_res = $p->fetch_plurk_responses( $plurks->[0]->{plurk_id} );
ok( defined $plurk_res->{responses} , 'get responses' );
ok( defined $plurk_res->{friends}   , 'get friends' );

$plurk_res = $p->fetch_plurk_responses( $plurks->[0]->{plurk_id} );
ok( defined $plurk_res->{responses} , 'get responses' );
ok( defined $plurk_res->{friends}   , 'get friends');

# for my $msg ( @{ $plurk_res->{responses} } ) {
#     ok( defined $msg->{content_raw} );
#     warn $msg->{content_raw};
# }


