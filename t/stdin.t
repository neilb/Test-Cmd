# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { $| = 1; plan tests => 16, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($run_env, $ret, $wdir, $test, @lines);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$ret = $run_env->write('run', <<EOF);
while (<>) {
	s/X/Y/g;
	print;
}
exit 0;
EOF
ok($ret);
$ret = $run_env->write('input', <<EOF);
X on X this X line X
EOF
ok($ret);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.
$test = Test::Cmd->new(prog => 'run', interpreter => "$^X", workdir => '');
ok($test);

ok(! defined $test->stdout);

$test->run('args' => 'input');
ok($? == 0);
ok($test->stdout eq "Y on Y this Y line Y\n");

$test->run('stdin' => "X is X here X tooX\n");
ok($? == 0);
ok($test->stdout eq "Y is Y here Y tooY\n");

$test->run('stdin' => <<_EOF_);
X here X
X there X
_EOF_
ok($? == 0);
ok($test->stdout eq "Y here Y\nY there Y\n");

@lines = qq(
X line X
X another X
);
$test->run('stdin' => \@lines);
ok($? == 0);
ok($test->stdout eq "\nY line Y\nY another Y\n");
