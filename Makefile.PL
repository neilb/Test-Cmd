# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

use ExtUtils::MakeMaker;

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

@tests = (glob('t/*.t'), glob('t/Common/*.t'));

WriteMakefile(
    'NAME'	=> 'Test::Cmd',
    'VERSION_FROM' => 'Cmd.pm', # finds $VERSION
    'PM'	=> {
			'Cmd.pm'	=> '$(INST_LIBDIR)/Cmd.pm',
			'Common.pm'	=> '$(INST_LIBDIR)/Cmd/Common.pm',
		},
    'test'	=> {
			'TESTS' => "@tests",
		},
);
