# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
my $iswin32;
BEGIN {
    $| = 1;
    if ($] <  5.003) {
	eval("require Win32");
	$iswin32 = ! $@;
    } else {
	$iswin32 = $^O eq "MSWin32";
    }
    plan tests => 28, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($test, $ret, $wdir, $wdir_file2, $wdir_foo_file1);
my @lines;

$test = Test::Cmd->new(workdir => '', subdir => 'foo');
ok($test);

$wdir = $test->workdir;
ok($wdir);
$wdir_file1 = $test->catfile($wdir, 'file1');
ok($wdir_file1);
$wdir_file2 = $test->catfile($wdir, 'file2');
ok($wdir_file2);
$wdir_foo_file3 = $test->catfile($wdir, 'foo', 'file3');
ok($wdir_foo_file3);

$ret = open(OUT, ">$wdir_file1");
ok($ret);
$ret = close(OUT);
ok($ret);

$ret = open(OUT, ">$wdir_file2");
ok($ret);
$ret = print OUT <<'_EOF_';
Test
file
#2.
_EOF_
ok($ret);
$ret = close(OUT);
ok($ret);

$ret = open(OUT, ">$wdir_foo_file3");
ok($ret);
$ret = print OUT <<'_EOF_';
Test
file
#3.
_EOF_
ok($ret);
$ret = close(OUT);
ok($ret);

#
$ret = $test->read(\@lines, 'no_file');
ok(! $ret);

$ret = $test->read(\$contents, 'no_file');
ok(! $ret);

$ret = $test->read(\@lines, 'file1');
ok($ret);
ok(! $lines[0]);

$ret = $test->read(\$contents, 'file1');
ok($ret);
ok(! $contents);

$ret = $test->read(\@lines, 'file2');
ok($ret);
ok(join('', @lines) eq "Test\nfile\n#2.\n");

$ret = $test->read(\$contents, 'file2');
ok($ret);
ok($contents eq "Test\nfile\n#2.\n");

$ret = $test->read(\@lines, ['foo', 'file3']);
ok($ret);
ok(join('', @lines) eq "Test\nfile\n#3.\n");

$ret = $test->read(\$contents, ['foo', 'file3']);
ok($ret);
ok($contents eq "Test\nfile\n#3.\n");
