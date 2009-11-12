use inc::Module::Install;
use strict;
use warnings;
name           'Net-Plurk';
all_from       'lib/Net/Plurk.pm';

requires(
    'Test::More'               => 0,
    'JSON'                     => 0,
    'LWP::UserAgent'           => 0,
    'HTTP::Cookies' => 0,
    'DateTime' => 0,
);
license 'perl';
# install_script 'myscript';
WriteAll;
