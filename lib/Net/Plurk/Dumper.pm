package Net::Plurk::Dumper;
use JavaScript::SpiderMonkey;
use Data::Dumper::Simple;
use JSON;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( qw(id settings js json_code) );
use warnings;
use strict;

=head1 NAME

Net::Plurk::Dumper - Dump plurks

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::Plurk::Dumper;

    my $p_dumper = Net::Plurk::Dumper->new(
            id => 'c9s'
    );


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=cut

my $base_url = 'http://www.plurk.com/';

sub new {
    my $class = shift;
    my %args = @_;

    my $js = JavaScript::SpiderMonkey->new();
    $js->init();    # Initialize Runtime/Context

    my $self = $class->SUPER::new({ js => $js , %args });

    $self->js->function_set( "set_accessor", sub {   
        my ( $accessor_name, $js_str ) = @_;
        $self->$accessor_name( from_json( $data_obj ) );
    } );

    $self->json_code( $self->_load_json_js );

    my $js_settings = $self->fetch_settings;
    $self->_eval_json( $js_settings, 'SETTINGS' , 'settings' );

    return $self;
}

sub fetch_plurks {
    my $self = shift;
    my $settings = $self->{settings};
    return $self->_fetch_plurks( user_id => $settings->{user_id}  ,  offset => $settings->{offset} );
}

sub _fetch_plurks {
    my $self = shift;
    my %args = @_;
    my $url = '';

}

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

sub fetch_settings {
    my $self = shift;
    
    my $url = $base_url . $self->id;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    my $response = $ua->get( $url );
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

sub _load_json_js {
    open my $fh, '< json.js';
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

1; # End of Net::Plurk::Dumper
