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

Version 0.01

=cut

our $VERSION = '0.01';

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
        my $o = from_json( $js_str );
        $self->$accessor_name( $o );
    } );

    $self->json_code( $self->load_json_js );

    my $js_settings = $self->_fetch_settings;
    $self->_eval_json( $js_settings, 'SETTINGS' , 'settings' );

    return $self;
}

=head2 LIST_REF = $self->fetch_plurks

=cut

sub fetch_plurks {
    my $self = shift;
    my $settings = $self->{settings};
    return $self->_fetch_plurks( user_id => $settings->{user_id}  ,  offset => $settings->{offset} );
}

sub fetch_plurk_responses {
    my ( $self, $plurk_id ) = @_;
    my $url = $base_url . "Responses/get2";
    my $response = $self->ua->post( $url , {
        from_response => 0,
        plurk_id => $plurk_id ,  #plurk id
    });

    die "post error: ", $response->status_line
        unless $response->is_success;

#    die "Weird content type at $url -- ", $response->content_type
#        unless $response->content_is_html;

    my $content = $response->decoded_content ;
    print $content;
#    if ( $response->decoded_content =~ m{AltaVista found ([0-9,]+) results} ) {
#
#        # The substring will be like "AltaVista found 2,345 results"
#        print "$word: $1\n";
#    }
#    else {
#        print "Couldn't find the match-string in the response\n";
#    }
#

}

sub _fetch_plurks {
    my $self = shift;
    my $user_id = $self->settings->{user_id};
    my $url = $base_url . "TimeLine/getPlurks?user_id=$user_id";
    
    my $response = $self->ua->get( $url );
    return unless( $response->is_success );

    my $c = $response->decoded_content;  # or whatever
    $self->_eval_json("var json=$c;",'json','plurks');
    return $self->plurks;
}


# XXX: i would like to use JE
sub _eval_json {
    my ( $self, $js_code, $varname, $accessor_name ) = @_;
    my $json_code = $self->json_code;
    my $rc = $self->js->eval( qq!
        $json_code
        $js_code
        var str = JSON.stringify( $varname );
        set_accessor( '$accessor_name' ,  str );
    !);
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
