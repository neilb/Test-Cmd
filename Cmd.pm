# This package tests an executable program or script,
# managing one or more temporary working directories,
# keeping track of standard and error output,
# and cleaning up after everything is done.

package Test::Cmd;

use strict;
use vars qw($VERSION @ISA);
use Cwd;
use File::Basename ();	# don't import the basename() method, we redefine it
use File::Find;
use File::Spec;

$VERSION = '0.02';
@ISA = qw(File::Spec);



=head1 NAME

Test::Cmd - Perl module for testing commands and scripts

=head1 SYNOPSIS

  use Test::Cmd;

  $test = Test::Cmd->new('prog' => 'program_or_script_to_test',
  			'interpreter' => 'script_interpreter',
			'string' => 'identifier_string',
			'workdir' => '',
			'subdir' => 'dir',
			'verbose' => 1);

  $test->verbose(1);

  $test->prog('program_or_script_to_test');

  $test->basename(@suffixlist);

  $test->interpreter('script_interpreter');

  $test->string('identifier string');

  $test->workdir('prefix');

  $test->workpath('subdir', 'file');

  $test->subdir('subdir', ...);
  $test->subdir(['sub', 'dir'], ...);

  $test->write('file', <<'EOF');
  contents of file
  EOF
  $test->write(['subdir', 'file'], <<'EOF');
  contents of file
  EOF

  $test->writable('dir', rwflag);

  $test->preserve(condition, ...);

  $test->cleanup(condition);

  $test->run('chdir' => 'dir', 'args' => 'arguments');

  $test->pass(condition);
  $test->pass(condition, funcref);

  $test->fail(condition);
  $test->fail(condition, funcref);
  $test->fail(condition, funcref, caller);

  $test->no_result(condition);
  $test->no_result(condition, funcref);
  $test->no_result(condition, funcref, caller);

  $test->stdout();

  $test->stderr();

  $test->diff();

  $test->here();

=head1 DESCRIPTION

The Test::Cmd module provides a framework for portable automated testing
of executable commands and scripts, especially commands and scripts that
require file system interaction.  This module is not restricted to testing
Perl scripts; the command or script to be tested may be any executable or
a script in any language, provided a means exists to execute the script
on the local system.

In addition to running tests and evaluating conditions, the Test::Cmd
module manages and cleans up one or more temporary workspace directories,
and provides methods for creating files and directories in those
workspace directories from in-line data (that is, here documents).
This allows tests to be completely self-contained.

The Test::Cmd module manipulates filenames and pathnames using the
File::Spec module to support writing tests portably across a variety of
operating and file systems.  The Test::Cmd class is in fact a subclass
of the File::Spec class, and File::Spec methods (File::Spec->catfile(),
File::Spec->file_name_is_absolute(), etc.) are available through the
Test::Cmd class and its instances.  Consequently, tests written using
Test::Cmd need not separately import the File::Spec module.

A Test::Cmd environment object is created via the usual invocation:

    $test = Test::Cmd->new();

Arguments to the Test::Cmd->new() method are keyword-value pairs that may
be used to initialize the object, typically by invoking the same-named
method as the keyword.

The Test::Cmd module may be used in conjunction with the Test module to
report test results in a format suitable for the Test::Harness module.
A typical use would be to call the Test::Cmd methods to prepare and
execute the test, and call the ok() method exported by the Test module
to test the conditions:

    use Test;
    use Test::Cmd;
    BEGIN { $| = 1; plan => 2 }
    $test = Test::Cmd->new(prog => 'test_program', workdir => '');
    ok($test);
    $wrote_file = $test->write('input_file', <<'EOF');
    This is input to test_program,
    which we expect to process this
    and exit successfully (status 0).
    EOF
    ok($wrote_file);
    $test->run('.', 'input_file');
    ok($? == 0);

Alternatively, the Test::Cmd module provides pass(), fail(), and
no_result() methods that report test results differently.  These methods
terminate the test immediately, reporting PASSED, FAILED, or NO RESULT
respectively, and exiting with status 0 (success), 1 or 2 respectively.
This allows for a distinction between an actual failed test and a test
that could not be properly evaluated because of an external condition
(such as a full file system or incorrect permissions):

    use Test::Cmd;
    $test = Test::Cmd->new(prog => 'test_program', workdir => '');
    Test::Cmd->no_result(! $test);
    $wrote_file = $test->write('input_file', <<'EOF');
    This is input to test_program,
    which we expect to process this
    and exit successfully (status 0).
    EOF
    $test->no_result(! $wrote_file);
    $test->run('.', 'input_file');
    $test->fail($? != 0);
    $test->pass;

It is not a good idea to intermix the two reporting models.
If you use the Test module and the Test->ok() method, do not use the
Test::Cmd->pass(), Test::Cmd->fail() or Test::Cmd->no_result() methods,
and vice versa.

=head1 METHODS

Methods supported by the Test::Cmd module include:

=over 4

=cut



my @Cleanup;
my $Run_Count;
my $Default;

BEGIN {
    $Run_Count = 0;

    # The File::Spec->tmpdir method was only added recently,
    # so we can't assume it's there.
    $Test::Cmd::TMPDIR = eval("File::Spec->tmpdir");

    # now we do win32 detection. what a mess :-(
    # if the version is 5.003, we can check $^O
    my $iswin32;
    if ($] <  5.003) {
	eval("require Win32");
	$iswin32 = ! $@;
    } else {
	$iswin32 = $^O eq "MSWin32";
    }

    if ($iswin32) {
    	eval("use Win32;");
	$Test::Cmd::_WIN32 = 1;
	$Test::Cmd::Temp_Prefix = "~testcmd$$-";
	$Test::Cmd::Cwd_Ref = \&Win32::GetCwd;
	if (! $Test::Cmd::TMPDIR) {
	    # Test for WIN32 temporary directories.
	    # The following is lifted from the 5.005056
	    # version of File::Spec::Win32::tmpdir.
	    foreach (@ENV{qw(TMPDIR TEMP TMP)}, qw(/tmp /)) {
		next unless defined && -d;
		$Test::Cmd::TMPDIR = $_;
		last;
	    }
	}
    } else {
    	$Test::Cmd::Temp_Prefix = "testcmd$$.";
	$Test::Cmd::Cwd_Ref = \&Cwd::cwd;
	if (! $Test::Cmd::TMPDIR) {
	    # Test for UNIX temporary directories.
	    # The following is lifted from the 5.005056
	    # version of File::Spec::Unix::tmpdir.
	    foreach ($ENV{TMPDIR}, "/tmp") {
		next unless defined && -d && -w _;
		$Test::Cmd::TMPDIR = $_;
		last;
	    }
	}
    }

    $Default = {};

    $Default->{failed} = 0;
    $Default->{verbose} = $ENV{VERBOSE} || 0;

    if (defined $ENV{PRESERVE}) {
    	$Default->{preserve}->{fail} = $ENV{PRESERVE} || 0;
    	$Default->{preserve}->{pass} = $ENV{PRESERVE} || 0;
    	$Default->{preserve}->{no_result} = $ENV{PRESERVE} || 0;
    } else {
    	$Default->{preserve}->{fail} = $ENV{PRESERVE_FAIL} || 0;
    	$Default->{preserve}->{pass} = $ENV{PRESERVE_PASS} || 0;
    	$Default->{preserve}->{no_result} = $ENV{PRESERVE_NO_RESULT} || 0;
    }

    sub handler {
	print STDERR "NO RESULT -- SIG$_ received.\n";
	foreach my $test (@Cleanup) {
	    $test->cleanup();
	}
	exit(2);
    }

    $SIG{HUP} = \&handler if $SIG{HUP};
    $SIG{INT} = \&handler;
    $SIG{QUIT} = \&handler;
    $SIG{TERM} = \&handler;
}

END {
    foreach my $test (@Cleanup) {
	$test->cleanup();
    }
}



=item C<new>

Create a new Test::Cmd environment.
Arguments with which to initialize the environment
are passed in as keyword-value pairs.

=cut

sub new {
    my $type = shift;
    my $self = {};

    bless $self, $type;

    %$self = %$Default;

    $self->{cleanup} = [];

    $self->{preserve} = {};
    %{$self->{preserve}} = %{$Default->{preserve}};

    $self->{cwd} = cwd(); 

    while (@_) {
    	my $keyword = shift;
	$self->{$keyword} = shift;
    }

    $self->workdir($self->{workdir});
    $self->prog($self->{prog});
    $self->subdir($self->{subdir}) if $self->{subdir};

    push @Cleanup, $self;

    $self;
}



=item C<verbose>

Sets the verbose level for the environment object to the specified value.

=cut

sub verbose {
    my $self = shift;
    $self->{verbose} = $_;
}



=item C<prog>

Specifies the executable program or script to be tested.  Returns the
absolute path name of the current program or script.

=cut

sub prog {
    my $self = shift;
    my $prog = shift;
    if ($prog) {
	# make sure we're always talking about the same program
    	if (! $self->file_name_is_absolute($prog)) {
    	    $prog = $self->catfile($self->{cwd}, $prog);
    	}
	$self->{prog} = $prog;
    }
    return $self->{prog};
}



=item C<basename>

Returns the basename of the current program or script.  Any specified
arguments are a list of file suffixes that may be stripped from the
basename.

=cut

sub basename {
    my $self = shift;
    return undef if ! $self->{prog};
    File::Basename::basename($self->{prog}, @_);
}



=item C<interpreter>

Specifies the program to be used to interpret C<prog> as a script.
Returns the current value of C<interpreter>.

=cut

sub interpreter {
    my $self = shift;
    my $interpreter = shift;
    $self->{interpreter} = $interpreter if $interpreter;
    $self->{interpreter};
}



=item C<string>

Specifies an identifier string for the functionality being tested to be
printed on failure or no result.

=cut

sub string {
    my $self = shift;
    my $string = shift;
    $self->{string} = $string if $string;
    $self->{string};
}



my $counter = 0;

sub _workdir_name {
    my $self = shift;
    while (1) {
	 $counter++;
	 my $name = $self->catfile($Test::Cmd::TMPDIR,
	 				$Test::Cmd::Temp_Prefix . $counter);
	 return $name if ! -e $name;
    }
}

=item C<workdir>

When an argument is specified, creates a temporary working directory
with the specified name.  If the argument is a NULL string (''),
the directory is named C<testcmd> by default, followed by the
unique ID of the executing process.

Returns the pathname to the temporary working directory.

=cut

sub workdir {
    my $self = shift;
    my $workdir = shift;
    if (defined($workdir)) {
#    	return if $workdir && $self->{workdir} eq $workdir;	# no change
	$self->{workdir} = $workdir ? $workdir : $self->_workdir_name;
	if (!mkdir($self->{workdir}, 0755)) {
	    $self->no_result("Unable to create work directory '$self->{workdir}': $!\n");
	}
	push(@{$self->{cleanup}}, $self->{workdir});
    }
    $self->{workdir};
}



=item C<workpath>

Returns the absolute path name to a subdirectory or file under the
current temporary working directory by concatenating the temporary
working directory name with the specified arguments.

=cut

sub workpath {
    my $self = shift;
    return undef if ! $self->{workdir};
    $self->catfile($self->{workdir}, @_);
}



=item C<subdir>

Creates new subdirectories under the temporary working dir, one for each
argument.  An argument may be an array reference, in which case the array
elements are concatenated together using the File::Spec->catfile method.
Subdirectories multiple levels deep must be created via a separate
argument for each level:

    $test->subdir('sub', ['sub', 'dir'], [qw(sub dir ectory)]);

Returns the number of subdirectories actually created.

=cut

sub subdir {
    my $self = shift;
    my $count = 0;
    foreach (@_) {
	my $newdir = $self->catfile($self->{workdir}, ref $_ ? @$_ : $_);
	if (mkdir($newdir, 0755)) {
	    $count++;
	}
    }
    return $count;
}



=item C<write>

Writes the specified text (second argument) to the specified file name
(first argument).  The file name may be an array reference, in which
case the array elements include subdirectory names to be concatenated
together.  The file is created under the temporary working directory.
Any subdirectories in the path must already exist.

=cut

sub write {
    my $self = shift;
    my $file = shift; # the file to write to
    $file = $self->catfile($self->{workdir}, ref $file ? @$file : $file);
    if (! open (OUT, ">$file")) {
    	return undef;
    }
    if (! print OUT @_) {
    	return undef;
    }
    return close(OUT);
}




=item C<writable>

Makes the specified directory tree writable (rwflag == TRUE) or not
writable (rwflag == FALSE).

=cut

sub _writable {
    if (!chmod 0755, $_) {
	no_result("Unable to change the access mode on '$_': $!\n");
    }
}

sub _writeprotect {
    if (!chmod 0555, $_) {
	no_result("Unable to change the access mode on '$_': $!\n");
    }
}

sub writable {
    my $self = shift;
    my $dir = shift;
    my $flag = shift;
    if ($flag) {
	finddepth(\&_writable,$dir);
    } else {
	finddepth(\&_writeprotect,$dir);
    }
}



=item C<preserve>

Arranges for the temporary working directories for the specified
Test::Cmd environment to be preserved for one or more conditions.
If no conditions are specified, arranges for the temporary working
directories to be preserved for all conditions.

=cut

sub preserve {
    my $self = shift;
    my @cond = (@_) ? @_ : qw(pass fail no_result);
    foreach my $cond (@cond) {
   	$self->{preserve}->{$cond} = 1;
    }
}



sub _nuke {
#    print STDERR "unlink($_)\n" if (!-d $_);
#    print STDERR "rmdir($_)\n" if (-d $_ && $_ ne ".");
    unlink($_) if (!-d $_);
    rmdir($_) if (-d $_ && $_ ne ".");
    1;
}



=item C<cleanup>

Removes any temporary working directories for the specified Test::Cmd
environment.  If the environment variable PRESERVE was set when
the Test::Cmd module was loaded, temporary working directories are
not removed.  If any of the environment variables PRESERVE_PASS,
PRESERVE_FAIL, or PRESERVE_NO_RESULT were set when the Test::Cmd module
was loaded, then temporary working directories are not removed if the
test passed, failed, or had no result, respectively.  Temporary working
directories are also preserved for conditions specified via the preserve()
method.

=cut

sub cleanup {
    my $self = shift;
    my $cond = shift;
    $cond = (($self->{failed} == 0) ? 'pass' : 'fail') if !$cond;
    if ($self->{preserve}->{$cond}) {
	print STDERR "Preserving work directory ".$self->{workdir}."\n" if $self->{verbose};
    	return;
    }
    chdir $self->{cwd}; # cd out of whatever work dir we're in
    foreach my $dir (@{$self->{cleanup}}) {
    	$self->writable($dir, "true");
	finddepth(\&_nuke, $dir);
	rmdir($dir);
    }
    $self->{cleanup} = [];
}



=item C<run>

Runs a test of the program or script for the test environment.  Standard
output and error output are saved for future retrieval via the stdout()
and stderr() methods.

Arguments are supplied as keyword-value pairs:

=over 4

=item C<args>

Specifies the command-line arguments to be supplied to the program
or script under test for this run:

	$test->run(args => 'arg1 arg2');

=item C<chdir>

Changes directory to the path specified as the value argument:

	$test->run(chdir => 'xyzzy');

If the specified path is not an absolute path name (begins with '/' on
Unix systems), then the subdirectory is relative to the temporary working
directory for the environment ($test->workdir).  Note that, by default,
no chdir is performed, so it is necessary to specify an explicit
chdir to the current directory:

	$test->run(chdir => '.');		# Unix-specific

	$test->run(chdir => $test->curdir);	# portable

to execute the test while under the temporary working directory.

=back
The script is run with the arguments specified as the second argument
of the run() method call.
first changeing directory
to the specified subdir (first argument) of the temporary working
directory.

Returns the return value from the system() call used to invoke the
program or script.

=cut

sub run {
    my $self = shift;
    my($args, $subdir);
    while (@_) {
    	my($key, $val) = splice(@_, 0, 2);
	if ($key eq 'args') {
		$args = $val;
	} elsif ($key eq 'chdir') {
		$subdir = $val;
	}
    }
    my $oldcwd;
    if ($subdir) {
	$oldcwd = Cwd::cwd();
    	if (! $self->file_name_is_absolute($subdir)) {
	    $subdir = $self->catfile($self->{workdir}, $subdir);
	}
	print STDERR "Changing to $subdir\n" if $self->{verbose};
	if (!chdir $subdir) {
	    $self->no_result("run: unable to chdir to $subdir: $!\n");
	}
    }
    $Run_Count++;
    my $stdout_file = $self->_stdout_file($Run_Count);
    my $stderr_file = $self->_stderr_file($Run_Count);
    my $cmd = $self->{prog};
    $cmd = $cmd." ".$args if $args;
    $cmd = $self->{interpreter}." ".$cmd if $self->{interpreter};
    $cmd =~ s/\$work/$self->{workdir}/g;
    $cmd = "$cmd 1>$stdout_file 2>$stderr_file";
    print STDERR "Invoking $cmd\n" if $self->{verbose};
    my $return = system($cmd);
    chdir $oldcwd if $oldcwd;
    return $return;
}



sub _to_value {
    my ($v) = @_;
    (ref $v or '') eq 'CODE' ? $v->() : $v;
}



=item C<pass>

Exits the test successfully.  Reports "PASSED" on the error output and
exits with a status of 0.  If a condition is supplied, only exits
the test if the condition evaluates TRUE.  If a function reference is
supplied, executes the function before reporting and exiting.

=cut

sub pass {
    my $self = shift;
    @_ = (1) if (@_ == 0); # provide default arg.
    my $cond = shift;
    my $funcref = shift;
    return if ! _to_value($cond);
    &$funcref() if $funcref;
    print STDERR "PASSED\n";
    $self->cleanup('pass');
    exit (0);
}



=item C<fail>

Exits the test unsuccessfully.  Reports "FAILED test of {string} at line
{line} of {file}." on the error output and exits with a status of 1.
If a condition is supplied, only exits the test if the condition
evaluates TRUE.  If a function reference is supplied, executes the
function before reporting and exiting.  If a caller level is supplied,
prints a calling trace N levels deep as part of reporting the failure.

=cut

sub fail {
    my $self = shift;
    @_ = (1) if (@_ == 0); # provide default arg.
    my $cond = shift;
    my $funcref = shift;
    my $caller = shift || 0;
    if (_to_value($cond)) {
	&$funcref() if $funcref;
	my $of_str = "";
	if (ref $self) {
	    $of_str = " of ".$self->basename;
	    if ($self->{string}) {
	    	$of_str .= " [$self->{string}]";
	    }
	}
	my $c = 0;
	my ($pkg,$file,$line,$sub) = caller($c++);
	print STDERR "FAILED test$of_str at line $line of $file";
	while ($c <= $caller) {
		($pkg,$file,$line,$sub) = caller($c++);
		print STDERR " ($sub)\n\tfrom line $line of $file";
	}
	print STDERR ".\n";
    	$self->cleanup('fail');
	exit (1);
    }
}



=item C<no_result>

Exits the test with an indeterminate result (the test could not be
performed due to external conditions such as, for example, a full
file system).  Reports "NO RESULT for test of {string} at line {line} of
{file}." on the error output and exits with a status of 2.  If a condition
is supplied, only exits the test if the condition evaluates TRUE.  If a
function reference is supplied, executes the function before reporting
and exiting.  If a caller level is supplied, prints a calling trace N
levels deep as part of reporting the failure.

=cut

sub no_result {
    my $self = shift;
    @_ = (1) if (@_ == 0); # provide default arg.
    my $cond = shift;
    my $funcref = shift;
    my $caller = shift || 0;
    if (_to_value($cond)) {
	&$funcref() if $funcref;
	my $of_str = "";
	if (ref $self) {
	    $of_str = " of ".$self->basename;
	    if ($self->{string}) {
	    	$of_str .= " [$self->{string}]";
	    }
	}
	my $c = 0;
	my ($pkg,$file,$line,$sub) = caller($c++);
	print STDERR "NO RESULT for test$of_str at line $line of $file";
	while ($c <= $caller) {
		($pkg,$file,$line,$sub) = caller($c++);
		print STDERR " ($sub)\n\tfrom line $line of $file";
	}
	print STDERR ".\n";
    	$self->cleanup('no_result');
	exit (2);
    }
}



sub _stdout_file {
    my $self = shift;
    my $count = shift;
    $self->catfile($self->{workdir}, "stdout.$count");
}

sub _stderr_file {
    my $self = shift;
    my $count = shift;
    $self->catfile($self->{workdir}, "stderr.$count");
}



sub _run_file {
    my $file = shift;
    if (!open(IN, "<$file")) {
    	return undef;
    }
    my @lines = <IN>;
    close(IN);
    return (wantarray ? @lines : join('', @lines));
}



=item C<stdout>

Returns the standard output from the specified run number.  If there is no
specified run number, then returns the standard output of the last run.
Returns the standard output as either a scalar or an array of output
lines, as appropriate for the calling context.  Returns undef if there
has been no test run.

=cut

sub stdout {
    my $self = shift;
    my $count = @_ ? shift : $Run_Count;
    return undef if ! $Run_Count;
    _run_file($self->_stdout_file($count));
}



=item C<stderr>

Returns the error output from the specified run number.  If there is
no specified run number, then returns the error output of the last run.
Returns the error output as either a scalar or an array of output lines,
as apporpriate for the calling context.  Returns undef if there has been
no test run.

=cut

sub stderr {
    my $self = shift;
    my $count = @_ ? shift : $Run_Count;
    return undef if ! $Run_Count;
    _run_file($self->_stderr_file($count));
}



=item C<diff>

To Be Written.

=cut

sub diff {
}



=item C<here>

Returns the absolute path name of the current working directory.
(This is essentially the same as Cwd::cwd, except that this preserves
the directory separators exactly as returned by the underlying
operating-system-dependent method.  The Cwd::cwd method canonicalizes
all directory separators to '/', which makes for consistent path name
representations within Perl, but may mess up another program or script
to which you try to pass the path name.)

=cut

sub here {
    &$Test::Cmd::Cwd_Ref();
}



1;
__END__

=back

=head1 ENVIRONMENT

Several environment variables affect the default values in a newly created
Test::Cmd environment object.  These environment variables must be set
when the module is loaded, not when the object is created.

=over 4

=item C<PRESERVE>

If set to a true value, all temporary working directories will
be preserved on exit, regardless of success or failure of the test.
The full path names of all temporary working directories will be reported
on error output.

=item C<PRESERVE_FAIL>

If set to a true value, all temporary working directories will be
preserved on exit from a failed test.  The full path names of all
temporary working directories will be reported on error output.

=item C<PRESERVE_NO_RESULT>

If set to a true value, all temporary working directories will be
preserved on exit from a test for which there is no result.  The full
path names of all temporary working directories will be reported on
error output.

=item C<PRESERVE_PASS>

If set to a true value, all temporary working directories will be
preserved on exit from a successful test.  The full path names of all
temporary working directories will be reported on error output.

=item C<VERBOSE>

When set to a true value, enables verbose reporting of various internal
things (path names, exact command line being executed, etc.).

=back

=head1 PORTABLE TESTS

Although the Test::Cmd module is intended to make it easier to write
portable tests for portable utilities that interact with file systems,
it is still very easy to write non-portable tests if you're not careful.

The best and most comprehensive set of portability guidelines is the
standard "Writing portable Perl" document at:

	http://www.perl.com/pub/doc/manual/html/pod/perlport.html

To reiterate one important point from the "WpP" document:  Not all Perl
programs have to be portable.  If the program or script you're testing
is UNIX-specific, you can (and should) use the Test::Cmd module to write
UNIX-specific tests.

That having been said, here are some hints that may help keep your tests
portable, if that's a requirement.

=over 4

=item Use Test::Cmd->here() for current directory path.

The normal Perl way to fetch the current working directory is to use the
Cwd::cwd() method.  Unfortunately, the Cwd::cwd() method canonicalizes
the path name it returns, changing the native directory separators into
the forward slashes favored by Perl and UNIX.  For most Perl scripts,
this makes a great deal of sense and keeps code uncluttered.

Passing in a file name that has had its directory separators altered,
however, may confuse the command or script under test, or make it
difficult to compare output from the command or script with an expected
result.  The Test::Cmd::here() method returns the absolute path name of
the current working directory, like Cwd::cwd(), but does not manipulate
the returned path in any way.

=item Use File::Spec methods for manipulating path names.

The File::Spec module provides a system-independent interface for
manipulating path names.  Because the Test::Cmd class is a sub-class of
the File::Spec class, you can use these methods directly as follows:

    	if (! Test::Cmd->file_name_is_absolute($prog)) {
		my $prog = Test::Cmd->catfile(Test::Cmd->here, $prog);
	}

For details about the available methods and their use, see the
documentation for the File::Spec module and its sub-modules, especially
the File::Spec::Unix modules.

=item Use Config for file-name suffixes, where possible.

The standard Config module provides values that

	$foo_exe = "foo$Config{_exe}";
	ok(-f $foo_exe);

Unfortunately, there is no existing $Config value that specifies the
suffix for a directly-executable Perl script.

=item Avoid generating executable programs or scripts.

How to make a file or script executable varies widely from system to
system, some systems using file name extensions to indicate executability,
others using a file permission bit.  The differences are complicated to
accomodate in a portable test script.  The easiest way to deal with this
complexity is to avoid it if you can.

If your test somehow requires executing a script that you generate from
the test itself, the best way is to generate the script in Perl and
then explicitly feed it to the Perl executable on the local system.
To be maximally portable, use the $^X variable instead of hard-coding
"perl" into the string you execute:

	$line = This is output from the generated perl script.";
	$test->write('script', <<EOF);
	print STDOUT "$line\\n";
	EOF
	$output = `$^X script`;
	ok($output eq "$line\n");

This completely avoids having to make the "script" file itself executable.
(Since you're writing your test in Perl, it's safe to assume that Perl
itself is executable.)

If you must generate a directly-executable script, then use the
$Config{startperl} variable at the start of the script to generate the
appropriate magic that will execute it as a Perl script:

	use Config;
	$line = This is output from the generated perl script.";
	$test->write('script', <<EOF);
	$Config{startperl};
	print STDOUT "$line\\n";
	EOF
	chdir($test->workdir);
	chmod(0755, 'script');	# POSIX-SPECIFIC
	$output = `script`;
	ok($output eq "$line\n");

=back 4

Addtional hints on how to write portable tests are welcome.

=head1 SEE ALSO

perl(1), File::Find(3), File::Spec(3), Test(3), Test::Harness(3).

A rudimentary page for the Test::Cmd module is available at:

	http://www.baldmt.com/Test-Cmd/

=head1 AUTHORS

Steven Knight, knight@baldmt.com

=head1 ACKNOWLEDGEMENTS

Thanks to Greg Spencer for the inspiration to create this package and
the initial draft of its implementation as a specific testing package
for the Cons software construction utility.  Information about Cons
is available at:

	http://www.dsmit.com/cons/

The general idea of managing temporary working directories in this way,
as well as the test reporting of the pass(), fail() and no_result()
methods, come from the testing framework invented by Peter Miller for
his Aegis project change supervisor.  Aegis is an excellent bit of work
which integrates creation and execution of regression tests into the
software development process.  Information about Aegis is available at:

	http://www.tip.net.au/~millerp/aegis.html

=cut
