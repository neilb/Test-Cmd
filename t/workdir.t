# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { $| = 1; plan tests => 20, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

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
