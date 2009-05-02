use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Plurk::Dumper',
    AUTHOR              => 'Cornelius <cornelius.howl@gmail.com>',
    VERSION_FROM        => 'lib/Net/Plurk/Dumper.pm',
    ABSTRACT_FROM       => 'lib/Net/Plurk/Dumper.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'Perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Plurk-Dumper-*' },
);
