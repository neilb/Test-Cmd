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
    plan tests => 21, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($test, $ret, $wdir);

$test = Test::Cmd->new(workdir => '', subdir => 'foo');
ok($test);
$ret = $test->write('file1', <<EOF);
Test file #1.
EOF
ok($ret);
$ret = $test->write(['foo', 'file2'], <<EOF);
Test file #2.
EOF
ok($ret);
$ret = $test->write(['bar', 'file3'], <<EOF);
Test file #3 (should not get created).
EOF
ok(! $ret);

$ret = $test->write($test->workpath('file4'), <<EOF);
Test file #4.
EOF
ok($ret);
$ret = $test->write($test->workpath('foo', 'file5'), <<EOF);
Test file #5.
EOF
ok($ret);
$ret = $test->write($test->workpath('bar', 'file6'), <<EOF);
Test file #6 (should not get created).
EOF
ok(! $ret);

$wdir = $test->workdir;
ok($wdir);

# I don't understand why, but setting read-only on a Windows NT
# directory on Windows NT still allows you to create a file.
# That doesn't make sense to my UNIX-centric brain, but it does
# mean we need to skip the related tests on Win32 platforms.
$ret = chmod(0500, $wdir);
skip($iswin32, $ret == 1);
$ret = $test->write('file7', <<EOF);
Test file #7 (should not get created).
EOF
skip($iswin32 || $> == 0, ! $ret);

$ret = chdir($wdir);
ok($ret);
ok(-d 'foo');
ok(! -d 'bar');
ok(-f 'file1');
ok(-f $test->workpath('foo', 'file2'));
ok(! -f $test->workpath('bar', 'file3'));
ok(-f 'file4');
ok(-f $test->workpath('foo', 'file5'));
ok(! -f $test->workpath('bar', 'file6'));
skip($iswin32 || $> == 0, ! -f 'file7');
