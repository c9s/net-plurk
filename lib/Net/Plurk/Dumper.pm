package Net::Plurk::Dumper;
use JavaScript::SpiderMonkey;
use JSON;
use LWP::UserAgent;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(ua id settings js json_code plurks) );
use warnings;
use strict;

=head1 NAME

Net::Plurk::Dumper - Dump plurks

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Net::Plurk::Dumper;

    my $p = Net::Plurk::Dumper->new(
            id => 'c9s'
    );

    my $plurks = $p->fetch_plurks;

    for ( @$plurks ) {
        use Data::Dumper::Simple;
        warn Dumper( $_ );
    }

=head1 DESCRIPTIONS

L<Net::Plurk::Dumper> use L<JavaScript::SpiderMonkey> 
( spidermonkey library L<http://www.mozilla.org/js/spidermonkey/> ) to evaluate
the plurk JS code (the JSON contains Date Object) , it should be invalid JSON.
or we should call it JS not JSON.

so that you will need spidermoneky and L<JavaScript::SpiderMonkey> installed
to use this module.

=head1 Accessors

=head2 settings

=head1 FUNCTIONS

=cut

my $base_url = 'http://www.plurk.com/';

=head2 Net::Plurk::Dumper->new ( id => USERID )

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $js = JavaScript::SpiderMonkey->new();
    $js->init();    # Initialize Runtime/Context

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $self = $class->SUPER::new({ js => $js , %args });
    $self->ua( $ua );

    $self->js->function_set( "set_accessor", sub {   
        my ( $accessor_name, $js_str ) = @_;
        my $o = from_json( $js_str , { utf8 => 1 } );
        $self->$accessor_name( $o );
    } );

    $self->json_code( $self->load_json_js );

    my $js_settings = $self->_fetch_settings;
    $self->_eval_json( $js_settings, 'SETTINGS' , 'settings' );

    return $self;
}

=head2 LIST_REF = $self->fetch_plurks

    LIST_REF contains HASH_REF

        'plurk_type' => 2,
        'lang' => 'tr_ch',
        'content' => 
        'plurk_id' => 53031904,
        'responses_seen' => 0,
        'no_comments' => 0,
        'limited_to' => undef,
        'content_raw' => 
        'response_count' => 11,
        'qualifier' => 'says',
        'posted' => 'Sat, 23 May 2009 01:58:09 GMT',
        'is_unread' => 0,
        'user_id' => 3158365,
        'owner_id' => 3158365,
        'id' => 53031904

=cut

sub fetch_plurks {
    my $self = shift;
    my $settings = $self->{settings};
    return $self->_fetch_plurks( user_id => $settings->{user_id}  ,  offset => $settings->{offset} );
}



=head2 HASH_REF : fetch_plurk_responses ( STRING plurk_id )
    
    HASH_REF:
        friends: (HASH_REF)

            key (userid)
            '3393538' => {
                'uid'               => 3393538,
                'avatar'            => '3',
                'id'                => 3393538,
                'nick_name'         => 'miaoski',
                'has_profile_image' => 1,
                'display_name'      => 'miaoski',
                'gender'            => 1
                },

        responses: (ARRAY_REF contains HASH_REF)

            'lang' => 'tr_ch'
            'content' => "\x{e5}\x{87}\x{8c}\x{e6}\x{99}\x{a8}\x{ef}\x{bc}\x{8c}\x{e7}\x{82}\x{b8}\x{e7}\x{89}\x{9b}\x{e8}\x{82}\x{89}\x{ef}\x{bc}\x{9f}\x{ef}\x{bc}\x{81}"
            'plurk_id' => 53295424
            'content_raw' => "\x{e5}\x{87}\x{8c}\x{e6}\x{99}\x{a8}\x{ef}\x{bc}\x{8c}\x{e7}\x{82}\x{b8}\x{e7}\x{89}\x{9b}\x{e8}\x{82}\x{89}\x{ef}\x{bc}\x{9f}\x{ef}\x{bc}\x{81}"
            'qualifier' => ':'
            'posted' => 'Sat, 23 May 2009 17:32:46 GMT'
            'user_id' => 20998
            'id' => 254582956

=cut

sub fetch_plurk_responses {
    my ( $self, $plurk_id ) = @_;
    my $url = $base_url . "Responses/get2";
    my $response = $self->ua->post( $url , {
        from_response => 0,
        plurk_id => $plurk_id ,  #plurk id
    });

    die "post error: ", $response->status_line
        unless $response->is_success;

    my $c = $response->decoded_content ;

    my $js_ret; 
    $self->js->function_set( "set_var", sub {   
        my ( $js_str ) = @_;
        $js_ret = from_json( $js_str , { utf8 => 1 });
    });

    eval  {
    my $rc = $self->js->eval( qq!
        @{[ $self->json_code  ]}
        var json = $c;
        var str = JSON.stringify( json );
        set_var( str );
    !);
    };

    return $js_ret;
}

sub _fetch_plurks {
    my $self = shift;
    my $user_id = $self->settings->{user_id};
    my $url = $base_url . "TimeLine/getPlurks?user_id=$user_id";
    
    my $response = $self->ua->get( $url );
    return unless( $response->is_success );

    my $c = $response->decoded_content; 
    $self->_eval_json("var json=$c;",'json','plurks');
    return $self->plurks;
}


# XXX: i would like to use JE
sub _eval_json {
    my ( $self, $js_code, $varname, $accessor_name ) = @_;
    my $json_code = $self->json_code;
    eval {
    my $rc = $self->js->eval( qq!
        $json_code
        $js_code
        var str = JSON.stringify( $varname );
        set_accessor( "$accessor_name" ,  str );
    !);
    };
}

sub _fetch_settings {
    my $self = shift;
    
    my $url = $base_url . $self->id;

    my $response = $self->ua->get( $url );
    if ($response->is_success) {
        my $c = $response->decoded_content;  # or whatever
        my ($head) = $c =~ m{<head>(.*?)</head>}smi;
        pos($head)=0;
        my ($js_setting) = ($head =~ m{<script.*?>(.*?)</script>}smi );
        return $js_setting;
    }
    else {
        die $response->status_line;
    }
}

sub load_json_js {
    my $self = shift;
    my $filename = shift || $ENV{HOME} . '/.json.js';

    if( ! -e $filename ) {
        die("Can not load $filename");
    }

    open my $fh, '<' , $filename ;
    local $/;
    my $json = <$fh>;
    close $fh;
    return $json;
}

=head1 AUTHOR

Cornelius, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-plurk-dumper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Plurk-Dumper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Plurk::Dumper

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Plurk-Dumper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Plurk-Dumper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Plurk-Dumper>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Plurk-Dumper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cornelius, all rights reserved.

This program is released under the following license: Perl


=cut

1;
