use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
sub MY::postamble {
    '
# A couple of development targets to generate a text version of
# the POD documentation, for easier inclusion on the web page.
.podtxt:  $(DISTVNAME).txt
	@rm -f $@ && touch $@

$(DISTVNAME).txt:	Cmd.pm
	@rm -f $@
	pod2text Cmd.pm > $@
';
}
WriteMakefile(
    'NAME'	=> 'Test::Cmd',
    'VERSION_FROM' => 'Cmd.pm', # finds $VERSION
);
