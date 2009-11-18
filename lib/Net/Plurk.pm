package Net::Plurk;
use common::sense;
use JSON qw(encode_json);
use LWP::UserAgent;
use DateTime::Tiny;

=head1 NAME

Net::Plurk - Plurk API

=cut

our $VERSION = 9.32115 ;

=head1 SYNOPSIS

    my $d = Net::Plurk->new;

    $d->login( 'username' , 'password' );

    my $plurks = $d->get_owner_latest_plurks();

    my $data = $d->get_user_data();

    my $ret = $d->add_plurk( content => "zzzzz" );

    use Data;warn Dumper( $ret );


=head1 DESCRIPTIONS

=head1 FUNCTIONS

=cut

use constant {
    base_url => 'http://www.plurk.com',
};


=head2 req_json( uri , params )

post parameters to plurk api , return decoded json

=cut

sub req_json {
    my $self = shift;
    my ( $url , $param ) = @_;

    $url = base_url . $url unless $url =~ /^http:/;
    my $req  = $self->ua->post( $url , $param );

    my $json = $req->decoded_content;

    my $data = decode_json( $json );

    if (ref($data->{users}) eq "HASH") {
        while (my ($k, $v) = each %{ $data->{users} }) {
            $self->{heap}{users}{$k} = $v;
        }
    }

    return $data;
}

=head2 new

=cut

sub new {
    my $self = bless {} , shift;
    my $ua = LWP::UserAgent->new( cookie_jar => {} );
    $self->ua( $ua );
    $self->{heap} = {};
    return $self;
}


=head2 ua

User agent, a LWP::UserAgent object.

=cut

sub ua {
    my $self = shift;
    $self->{ua} = shift if @_;
    return $self->{ua};
}


=head2 post( request path , arguments )

=cut

sub post {
    my $self = shift;
    my $path = shift;
    $self->ua->post(base_url . $path, @_);
}

sub decode_json($) {
    my $json = shift;
    $json =~ s{new Date\("(.*?)"\)}{"$1"}g;
    JSON::decode_json($json);
}

=head2 login( username , password )

login

=cut

sub login {
    my $self = shift;
    my $nick = shift;
    my $pass = shift;

    my $res = $self->post('/Users/login' , {
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

=head2 meta

return meta data hashref , which contains settings , friends , fans data.

=cut

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

    my $now = DateTime::Tiny->now;
    my $res = $self->post('/TimeLine/getPlurks',  {
        offset  => qq{"$now"},
        user_id => $self->meta->{settings}->{user_id}
    });

    my $plurks = decode_json($res->decoded_content);

    # Join plurk user info.
    my $users = $self->{heap}{users};
    for my $pu (@$plurks) {
        $pu->{owner} = $users->{$pu->{owner_id}} if $users->{$pu->{owner_id}};
    }

    return $plurks;
}

sub get_unread_plurks {
    my $self = shift;

    my $response  = $self->req_json(
        '/Users/getUnreadPlurks' => {
            # This tells plurk.com to include all required user info in the response.
            known_friends => "[]"
        }
    );

    my $plurks = $response->{unread_plurks};

    # Join plurk user info.
    my $users = $self->{heap}{users};
    for my $pu (@$plurks) {
        $pu->{owner} = $users->{$pu->{owner_id}} if $users->{$pu->{owner_id}};
    }

    return $plurks;
}

=head2 get_own_profile_data

http://www.plurk.com/Users/getOwnProfileData

=cut

sub get_own_profile_data {
    my $self = shift;
    my $friend_ids = shift || [];

    $self->req_json('/Users/getOwnProfileData' => {
        known_friends =>  encode_json( $friend_ids ),
    });
}

=head2 get_response_n( user_id , plurk_ids )

http://www.plurk.com/Poll/getResponsesN/3341956

plurk_ids:

    2lvyg8,2lvwkv,2lvvk7,2lvul7,2lvt6k ...

response:

        [{
            "lang": "tr_ch",
            "posted": new Date("Thu, 12 Nov 2009 17:22:47 GMT"),
            "content_raw": "\u597d\u7d2f\u55da\u55b5...",
            "responses_seen": 0,
            "qualifier": ":",
            "plurk_id": 157699389,
            "response_count": 2,
            "owner_id": 3701915,
            "id": 157699389,
            "content": "\u597d\u7d2f\u55da\u55b5...",
            "user_id": 3341956,
            "is_unread": 0,
            "limited_to": null,
            "no_comments": 0,
            "plurk_type": 0
        },
        {
            "lang": "tr_ch",
            "posted": new Date("Wed, 11 Nov 2009 12:31:36 GMT"),
            "content_raw": "\u6211\u559c\u6b61\u9019\u7db2\u7ad9   http:\/\/www.jldesign.tv\/",
            "user_id": 3341956,
            "plurk_type": 0,
            "plurk_id": 156732836,
            "response_count": 2,
            "owner_id": 4024314,
            "no_comments": 0,
            "content": "\u6211\u559c\u6b61\u9019\u7db2\u7ad9   <a href=\"http:\/\/www.jldesign.tv\/\" class=\"ex_link\" rel=\"nofollow\">www.jldesign.tv\/<\/a>",
            "responses_seen": 0,
            "is_unread": 0,
            "limited_to": null,
            "id": 156732836,
            "qualifier": "is"
        }]

=cut

sub get_response_n {
    my $self = shift;
    my $user_id  = shift;
    my $ids = shift;
    return $self->req_json( 'http://www.plurk.com/Poll/getResponsesN/' . $user_id , { plurk_ids => join(',',@$ids ) });
}

=head2 get_user_data

http://www.plurk.com/Users/getUserData

post:
        page_uid	3341956

response:

        {
        "num_of_fans": 178,
        "invite_url": "http:\/\/www.plurk.com\/c9s\/invite",
        "is_friend": false,
        "cliques": [{
            "user_id": 3341956,
            "friends": "|3173618||3168852||3158365||3137755||186992||3457834||3294830||3389620||3539966||3453719||3289766||3961080|",
            "name": "Geeks"
        },
        {
            "user_id": 3341956,
            "friends": "|3137755||3332446||3265130||900477||3177902||3185157||3160092||1558140||3367439||3376036||765208||753660||3514076||3210573||3631135||3422497||273546||3537112||3638713||3425595||3755142||3121484||3542124||3165008||3459057||3787337||3496909||3650383||3206900||3777181||241405||3578960||3686964||4123117||3349034||3481782||3145171||193136||4106788||4593464|",
            "name": "Girls"
        },
        {
            "user_id": 3341956,
            "friends": "|3289766||3173618||3160092||3626549||3326111||3158366|",
            "name": "SA"
        }],
        "num_of_friends": 220,
        "is_warned": false,
        "fans": [],
        "can_follow": true,
        "has_facebook": false,
        "friend_status": 0,
        "is_following": false,
        "show_inivted_guide": false,
        "friends": []
        }

=cut

sub get_user_data {
    my $self = shift;
    return $self->meta->{user_data} if $self->meta->{user_data};
    my $req = $self->ua->post( 'http://www.plurk.com/Users/getUserData' , { page_uid => $self->meta->{settings}->{user_id}, });
    my $response = $req->decoded_content;
    my $json = decode_json ( $response );
    return $self->meta->{user_data} = $json;
}

=head2 add_plurk

http://www.plurk.com/TimeLine/addPlurk

post:
    content	Hola
    lang	tr_ch
    no_comments	0
    posted	"2009-11-12T17:40:13"
    qualifier	:
    uid	3341956

response:

    {"plurk": {"responses_seen": 0, "qualifier": ":", "plurk_id": 157706966,
    "response_count": 0, "limited_to": null, "no_comments": 0, "is_unread": 0,
    "lang": "tr_ch", "content_raw": "Hola", "user_id": 3341956, "plurk_type":
    0, "id": 157706966, "content": "Hola", "posted": new Date("Thu, 12 Nov 2009
    17:40:13 GMT"), "owner_id": 3341956}, "error": null}

=cut

sub add_plurk {
    my $self = shift;
    my %args = @_;

    $self->req_json('/TimeLine/addPlurk', {
        content     => "",
        no_comments => '0',
        lang        => 'tr_ch',
        posted      => '"' . DateTime::Tiny->now . '"',
        qualifier   => ':',
        uid         => $self->meta->{settings}->{user_id},
        %args,
    });
}


=head2 delete_plurk( $plurk_id )

http://www.plurk.com/TimeLine/addPlurk

post:
    plurk_id: 160357721

response (not json):

    "ok"

=cut

sub delete_plurk {
    my $self = shift;
    my $id   = shift;

    return unless $id;
    my $r = $self->post('/TimeLine/deletePlurk', { plurk_id => $id });

    return $r->decoded_content;
}

=head1 AUTHOR

Cornelius, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-plurk-dumper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Plurk-Dumper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Plurk

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
