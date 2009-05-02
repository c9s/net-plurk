#!/usr/bin/env perl
use JavaScript::SpiderMonkey;
use Data::Dumper::Simple;

my $js = JavaScript::SpiderMonkey->new();
$js->init();    # Initialize Runtime/Context

# Define a perl callback for a new JavaScript function
$js->function_set( "print_to_perl", sub {   
            warn Dumper( @_ );
    } );

# Create a new (nested) object and a property
# $js->property_by_path("new");

open FH,'<','json.js';
local $/;
my $json_code = <FH>;
close FH;

# date: new Date('Sat, 02 May 2009 05:37:23')
# Execute some code
my $rc = $js->eval( qq!
        $json_code
        var data = {
            date: new Date('Sat, 02 May 2009 05:37:23'),
            x : 1,
            y : 2,
        };
        var str = JSON.stringify( data );
        print_to_perl( str );
    !
);
warn Dumper( $rc );


# my $rc = $js->eval( q!
#                 
#                document.location.href = append("http://", "www.aol.com");
# 
#                print_to_perl("URL is ", document.location.href);
# 
#                function append(first, second) {
#                     return first + second;
#                }
#            !
# );
# print $rc;
# 
