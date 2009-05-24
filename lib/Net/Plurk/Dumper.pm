package Net::Plurk::Dumper;
use JavaScript::SpiderMonkey;
use JSON;
use LWP::UserAgent;
use HTTP::Cookies;

use Moose;

# use base qw(Class::Accessor::Fast);
# __PACKAGE__->mk_accessors( qw(id json_code debug) );

# Moose::Util::TypeConstraints

has 'id'        => ( is => 'rw', isa => 'Str' );
has 'json_code' => ( is => 'rw', isa => 'Str' );
has 'debug'     => ( is => 'rw', isa => 'Bool' );

has 'ua' => ( is => 'rw', isa => 'LWP::UserAgent' );
has 'js' => ( is => 'rw', isa => 'JavaScript::SpiderMonkey' );

has 'friends'  => ( is => 'rw', isa => 'HashRef' );
has 'settings' => ( is => 'rw', isa => 'HashRef' );

use warnings;
use strict;

=head1 NAME

Net::Plurk::Dumper - Dump plurks

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

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

my $base_url = 'http://www.plurk.com';

=head2 Net::Plurk::Dumper->new ( id => USERID )

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new({ %args });

    my $js = JavaScript::SpiderMonkey->new();
    $js->init();    # Initialize Runtime/Context

    $self->js( $js );
    my $cookie_jar = HTTP::Cookies->new(
        file => "$ENV{HOME}/.plurk_cookies.dat",
        autosave => 1,
    );

    my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );
    $ua->timeout(10);

    $self->ua( $ua );

    if( defined $args{id} and defined $args{password} ) {
        $self->login( %args );
    }

    $self->js->function_set( "get_json_var", sub {   
        $self->{js_ret} = from_json( $_[0] , { utf8 => 1 });
    });

    $self->js->function_set( "get_var" , sub {
        $self->{js_ret} = $_[0];
    });

    $self->json_code( $self->read_json_js );
    $self->load_json_js;

    $self->_init_meta;

    my $js_settings = $self->_parse_settings;
    $self->js->eval(qq| 
            $js_settings;
            var str = JSON.stringify( SETTINGS );
            get_json_var(str);
    |);
    $self->settings( $self->{js_ret} );

    my $js_friends  = $self->_parse_friends;
    $self->js->eval(qq| 
            $js_friends;
            var str = JSON.stringify( FRIENDS );
            get_json_var(str);
    |);
    $self->friends( $self->{js_ret} );
    return $self;
}


sub login {
    my ($self, %args ) = @_;
    my $res = $self->ua->post( "$base_url/Users/login" , {
        nick_name => $args{id} ,
        password => $args{password}
    });
    my $c = $res->decoded_content;
    die('LOGIN FAILED (Please try again):' . $c) if( $c =~ m{Please try again} );
    die('LOGIN FAILED (NOT 302):' . $c) if( $c !~ m{302 Found} );
}

=head2 LIST_REF fetch_plurks HASHREF Arguments

    Arguments:
        user_id:
        offset:

    the returned LIST_REF contains HASH_REF

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
    my ( $self, $args ) = @_;
    my $settings = $self->{settings};

    $args ||= {};
    $args->{user_id} ||= $settings->{user_id};
    return $self->_fetch_plurks($args);
}

sub _fetch_plurks {
    my ($self, $args ) = @_;
    my $url      = "$base_url/TimeLine/getPlurks";

    my $response;
    unless( defined $args->{offset} ) {
        $url .= qq|?user_id=@{[ $args->{user_id} ]}|;
        $response = $self->ua->get( $url );
    }
    else {
        $response = $self->ua->post( $url, {
            user_id => $args->{user_id},
            offset  => $args->{offset} 
        } );
    }
    my $c = $response->decoded_content; 
    unless( $response->is_success ) {
        die('Fail:' . $c );
    }
    return $self->get_js_json( $c );
}


sub fetch_userdata {
    my ( $self, $user_id ) = @_;
    my $url = "$base_url/Users/getUserData";
    my $response = $self->ua->post( $url , {
        page_uid => $user_id , 
    });
    die "post error: ", $response->status_line
        unless $response->is_success;
    my $c = $response->decoded_content ;
    return $self->get_js_json( $c );
}

# post:
#   known_friends   
#   ["3123451","20998","40008","3114347","3121484","21070","186992","3145970","3127252","765208","3137755"
#   ,"753660","3158365"]

#{"users": {"3583618": {"display_name": "VickiChen", "uid": 3583618, "gender": 0, "nick_name": "VickiChen"
#, "has_profile_image": 1, "id": 3583618, "avatar": "8"}, "3165699": {"display_name": "bluegina", "uid"
#: 3165699, "gender": 0, "nick_name": "bluegi
sub fetch_owner_profile_data {
    my $self = shift;

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
    my $url = "$base_url/Responses/get2";
    $url = 'http://www.plurk.com/Responses/get2';
    my $response = $self->ua->post( $url , {
        from_response => 0,
        plurk_id => $plurk_id ,
    });

    die "post error at $url: ", $response->status_line
        unless $response->is_success;

    my $c = $response->decoded_content ;
    return $self->get_js_json( $c );
}



sub load_json_js {
    my $self = shift;
    my $rc = $self->js->eval( qq| @{[ $self->json_code  ]}; |);
    die $@ unless( $rc );
}

sub read_json_js {
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

sub get_js_json {
    my ( $self, $str ) = @_;
    my $rc = $self->js->eval( qq|
        var json = $str;
        var str = JSON.stringify( json );
        get_json_var( str );
    |);
    my $js_ret = $self->{js_ret};
    die "JS EVAL FAILED: @{[ $@ ]}" unless( $rc );
    die "RETURN JSON OBJECT FAILED" unless( $js_ret );
    return $js_ret;
}

sub _parse_head {
    my $self = shift;
    my $html = shift;
    ($self->{head}) = $html =~ m{<head>(.*?)</head>}smi;
    pos($self->{head})=0;
}

sub _parse_settings {
    my $self = shift;
    pos($self->{head})=0;
    my ($js_settings) = ($self->{head} =~ m{<script.*?>.*?(var SETTINGS.*?;).*?</script>}smi );
    return $js_settings;
}

sub _parse_friends {
    my $self = shift;
    pos($self->{head})=0;
    my ($js_friends) = ($self->{head} =~ m{(var FRIENDS = .*?;)}smi);
    return $js_friends;
}

sub _init_meta {
    my $self = shift;
    my $url = "$base_url/@{[$self->id]}";
    my $response = $self->ua->get( $url );
    # warn $url if $self->debug;
    if ($response->is_success) {
        $self->_parse_head( $response->decoded_content );
    }
    else {
        die $response->status_line;
    }
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
