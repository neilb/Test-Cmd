# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { $| = 1; plan tests => 9, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($run_env, $ret, $wdir, $test);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$ret = $run_env->write('run1', <<EOF);
print STDOUT "run1 STDOUT\\n";
print STDERR "run1 STDERR\\n";
exit 0;
EOF
ok($ret);
$ret = $run_env->write('run2', <<EOF);
print STDOUT "run2 STDOUT\\n";
print STDERR "run2 STDERR\\n";
exit 0;
EOF
ok($ret);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.
$test = Test::Cmd->new(interpreter => "$^X", workdir => '');
ok($test);

$test->prog('run1');
$test->run();
ok($? == 0);
$test->prog('run2');
$test->run();
ok($? == 0);
