# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 20, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($ret, $workdir_foo, $workdir_bar, $no_such_subdir);

my $test = Test::Cmd->new;
ok($test);
ok(! $test->workdir);

$test = Test::Cmd->new(workdir => undef);
ok($test);
ok(! $test->workdir);

$test = Test::Cmd->new(workdir => '');
ok($test);
ok($test->workdir);
ok(-d $test->workdir);

$test = Test::Cmd->new(workdir => 'dir');
ok($test);
ok($test->workdir);
ok(-d $test->workdir);

$no_such_subdir = $test->catfile('no', 'such', 'subdir');

$test = Test::Cmd->new(workdir => $no_such_subdir);
ok(! $test);

$test = Test::Cmd->new(workdir => 'foo');
ok($test);
$workdir_foo = $test->workdir;
ok($workdir_foo);

$ret = $test->workdir('bar');
ok($ret);
$workdir_bar = $test->workdir;
ok($workdir_bar);

$ret = $test->workdir($no_such_subdir);
ok(! $ret);
ok($workdir_bar eq $test->workdir);

ok(-d $workdir_foo);
ok(-d $workdir_bar);
