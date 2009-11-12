package Net::Plurk::Dumper;
use JSON;
use LWP::UserAgent;
use HTTP::Cookies;
use DateTime;
use JE;
use warnings;
use strict;

=head1 NAME

Net::Plurk::Dumper - Dump plurks

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Net::Plurk::Dumper;
    my $p = Net::Plurk::Dumper->new( 
                id => $plurk_id , 
                password => $passwd , 
                debug => 1 
            );
    my @plurks = $p->get_plurks( limit => 10 );
    my @friends = $p->get_friends();

=head1 DESCRIPTIONS

=head1 Accessors

=head2 settings

=head1 FUNCTIONS

=cut

use constant {
    base_url => 'http://www.plurk.com',
};


sub new {
    my $self = bless {} , shift;
    my $cookie_jar = HTTP::Cookies->new( file => "$ENV{HOME}/lwp_cookies.dat", autosave => 1 );
    my $ua = LWP::UserAgent->new( cookie_jar => $cookie_jar );

    $self->ua( $ua );
    return $self;
}


sub ua {
    my $self = shift;
    $self->{ua} = shift if @_;
    return $self->{ua};
}

sub login {
    my $self = shift;
    my $nick = shift;
    my $pass = shift;
    my $res = $self->ua->post( base_url . '/Users/login' , {
        nick_name => $nick,
        password => $pass,
    });

    my $c = $res->decoded_content;
    $res = $self->ua->get( base_url . '/' . $nick );

    my $meta;
    if ($res->is_success) {
        $meta = $self->_parse_head( $res->decoded_content );
    }
    else {
        warn $res->status_line;
        return 0;
    }
    return $meta;
}

=head2 _parse_head

meta:

    settings => {
          'global_filter' => '{}',
          'sound_mute' => 1,
          'show_location' => 1,
          'search_me' => 1,
          'view_plurks' => 0,
          'message_me' => 0,
          'user_id' => 3341956
    };


    friends => [ '3156986' => {
                         'timezone' => undef,
                         'location' => 'Taipei, Taiwan',
                         'uid' => 3156986,
                         'avatar' => 0,
                         'nick_name' => 'fourdollars',
                         'full_name' => 'Shih-Yuan Lee (FourDollars)',
                         'has_profile_image' => 1,
                         'display_name' => "\x{56db}\x{584a}\x{9322}",
                         'karma' => '88.25',
                         'id' => 3156986,
                         'gender' => 1
                       }, ... ]

=cut

sub _parse_head {
    my $self = shift;
    my $content = shift;
    my ($head) = ( $content =~ m{<head>(.*?)</head>}smi );
    my ($settings_string) = ( $head =~ m{var SETTINGS =\s*(\{.*?\});}smi );
    my ($friends_string)  = ( $head =~ m{var FRIENDS =\s*(.*?\});}smi );
    my ($fans_string)     = ( $head =~ m{var FANS =\s*(.*?\});}smi );

    my $settings = decode_json($settings_string);
    my $friends  = decode_json($friends_string);
    my $fans     = decode_json($fans_string);

    return $self->{meta} = {
        settings => $settings,
        friends => $friends,
        fans => $fans,
    };
}

sub meta { return $_[0]->{meta} };

=head2 get_owner_latest_plurks

plurk format: 

        [{
            'plurk_type' => 0,
            'lang' => 'tr_ch',
            'content' => "Miyagawa \x{5beb}\x{7684}  <a href=\"http://github.com/miyagawa/github-growler\" class=\"ex_link\" rel=\"nofollow\">github-growler</a>",
            'plurk_id' => 154287425,
            'responses_seen' => 0,
            'no_comments' => 0,
            'response_count' => 0,
            'limited_to' => undef,
            'content_raw' => "Miyagawa \x{5beb}\x{7684}  http://github.com/miyagawa/github-growler (github-growler)",
            'qualifier' => ':',
            'posted' => 'Sun, 08 Nov 2009 05:49:40 GMT',
            'is_unread' => 0,
            'owner_id' => 3341956,
            'id' => 154287425,
            'user_id' => 3341956
          } ,  .... ]

=cut

sub get_owner_latest_plurks {
    my $self = shift;

    my $now = DateTime->now;
    my $res = $self->ua->post('http://www.plurk.com/TimeLine/getPlurks',  {
        offset  => qq{"$now"},
        user_id => $self->meta->{settings}->{user_id},
    });
    my $json = $res->decoded_content;
    $json =~ s{new Date\("(.*?)"\)}{"$1"}g;
    my $plurks = decode_json( $json );
    return $plurks;
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

=item * Github Repository

L<http://github.com/c9s/net-plurk-dumper>

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
