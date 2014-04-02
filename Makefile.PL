# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
    '
# A couple of development targets to generate a text version of
# the POD documentation, for easier inclusion on the web page.
.podhtml:  $(DISTVNAME).html $(DISTNAME)-Common-$(VERSION).html
	@rm -f $@ && touch $@

.podtxt:  $(DISTVNAME).txt $(DISTNAME)-Common-$(VERSION).txt
	@rm -f $@ && touch $@

$(DISTVNAME).html:	Cmd.pm
	@rm -f $@
	pod2html Cmd.pm > $@

$(DISTVNAME).txt:	Cmd.pm
	@rm -f $@
	pod2text Cmd.pm > $@

$(DISTNAME)-Common-$(VERSION).html:	Common.pm
	@rm -f $@
	pod2html Common.pm > $@

$(DISTNAME)-Common-$(VERSION).txt:	Common.pm
	@rm -f $@
	pod2text Common.pm > $@
';
}

WriteMakefile(
    'NAME'	=> 'Test::Cmd',
    'VERSION_FROM' => 'lib/Test/Cmd.pm',

    PREREQ_PM => {
        'strict'            => 0,
        'warnings'          => 0,
        'Exporter'          => 0,
        'File::Basename'    => 0,
        'File::Find'        => 0,
        'File::Spec'        => 0,
        'Config'            => 0,
        'Cwd'               => 0,
        'File::Copy'        => 0,
    },

    ($mm_ver >= 6.52
        ? (CONFIGURE_REQUIRES => {
                'ExtUtils::MakeMaker' => 6.30,
          })
        : ()
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
                'Test' => 0,
          })
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilbowers/Test-Cmd',
                    url  => 'git://github.com/neilbowers/Test-Cmd.git',
                },
            },
          })
    ),


);
