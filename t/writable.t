# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 14, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

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
$wdir = $test->workdir;
ok($wdir);
$test->writable($wdir, 0);

$ret = chdir($wdir);
ok($ret);
# If we're running as root, then non-writability tests fail because root
# can write to anything.  Let them know why we're skipping those tests.
print "# Skipping tests because you're running with EUID of 0\n" if $> == 0;
skip($> == 0, ! -w $test->curdir);
skip($> == 0, ! -w 'file1');
skip($> == 0, ! -w 'foo');
skip($> == 0, ! -w $test->workpath('foo', 'file2'));

$test->writable($wdir, 1);
ok(-w $test->curdir);
ok(-w 'file1');
ok(-w 'foo');
ok(-w $test->workpath('foo', 'file2'));
