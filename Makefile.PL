use inc::Module::Install;
use strict;
use warnings;
name           'Net-Plurk';
all_from       'lib/Net/Plurk.pm';

requires(
    'Test::More'     => 0,
    'JSON'           => 0,
    'LWP::UserAgent' => 0,
    'HTTP::Cookies'  => 0,
    'DateTime::Tiny' => 0,
    'common::sense'  => 0,
);

test_requires
    "Text::Greeking::zh_TW" => "0.0.4";

license 'perl';
# install_script 'myscript';
WriteAll;
