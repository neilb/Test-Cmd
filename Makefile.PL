# Copyright 1999-2000 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
sub MY::postamble {
    '
# A couple of development targets to generate a text version of
# the POD documentation, for easier inclusion on the web page.
.podhtml:  $(DISTVNAME).html
	@rm -f $@ && touch $@

.podtxt:  $(DISTVNAME).txt
	@rm -f $@ && touch $@

$(DISTVNAME).html:	Cmd.pm
	@rm -f $@
	pod2html Cmd.pm > $@

$(DISTVNAME).txt:	Cmd.pm
	@rm -f $@
	pod2text Cmd.pm > $@
';
}
WriteMakefile(
    'NAME'	=> 'Test::Cmd',
    'VERSION_FROM' => 'Cmd.pm', # finds $VERSION
    'PM'	=> {
			'Cmd.pm'	=> '$(INST_LIBDIR)/Cmd.pm'
		},
);
