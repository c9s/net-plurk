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
