use inc::Module::Install;
use strict;
use warnings;
qx{ cp -v json.js  $ENV{HOME}/.json.js };
name           'Net-Plurk-Dumper';
all_from       'lib/Net/Plurk/Dumper.pm';

requires(
    'Test::More'               => 0,
    'JavaScript::SpiderMonkey' => 0,
    'JSON'                     => 0,
    'LWP::UserAgent'           => 0,
);
license 'perl';
# install_script 'myscript';
WriteAll;
