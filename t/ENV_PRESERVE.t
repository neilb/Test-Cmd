# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { $| = 1; plan tests => 28, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

$here = Test::Cmd->here();
my @I_FLAGS = map(Test::Cmd->file_name_is_absolute($_) ? "-I$_" :
			"-I".Test::Cmd->catfile($here, $_), @INC);

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($run_env, $wdir, $ret, $test, $string);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

sub contents {
    my $file = shift;
    if (! open(FILE, $file)) {
    	return undef;
    }
    my $string = join('', <FILE>);
    if (! close(FILE)) {
    	return undef;
    }
    return $string;
}

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.
$ret = open(PERL, "|$^X -w @I_FLAGS >perl.stdout.1 2>perl.stderr.1");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
my($test, $wdir, $ret);
$test = Test::Cmd->new(workdir => '');
Test::Cmd->fail(! $test);
$wdir = $test->workdir;
$test->fail(! $wdir);
$ret = $test->write('file1', <<EOF_1);
Test file #1.
EOF_1
$test->fail(! $ret);
$test->cleanup;
$test->fail(-d $wdir);
$test->pass;
EOF
ok($ret);

$ret = close(PERL);
ok($ret);
ok($? == 0);

$string = contents("perl.stdout.1");
ok(defined $string);
ok(! $string);
$string = contents("perl.stderr.1");
ok(defined $string);
ok($string eq "PASSED\n");

$ENV{PRESERVE_PASS} = '1';

$ret = open(PERL, "|$^X -w @I_FLAGS >perl.stdout.2 2>perl.stderr.2");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
my($test, $wdir, $ret);
$test = Test::Cmd->new(workdir => '');
Test::Cmd->fail(! $test);
$wdir = $test->workdir;
$test->fail(! $wdir);
$ret = $test->write('file2', <<EOF_2);
Test file #2.
EOF_2
$test->fail(! $ret);
$test->cleanup('pass');
$test->fail(! -d $wdir);
$test->cleanup('fail');
$test->fail(-d $wdir);
$test->pass;
EOF
ok($ret);

$ret = close(PERL);
ok($ret);
ok($? == 0);

$string = contents("perl.stdout.2");
ok(defined $string);
ok(! $string);
$string = contents("perl.stderr.2");
ok(defined $string);
ok($string eq "PASSED\n");

delete $ENV{PRESERVE_PASS};
$ENV{PRESERVE_FAIL} = '1';

$ret = open(PERL, "|$^X -w @I_FLAGS >perl.stdout.3 2>perl.stderr.3");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
my($test, $wdir, $ret);
$test = Test::Cmd->new(workdir => '');
Test::Cmd->fail(! $test);
$wdir = $test->workdir;
$test->fail(! $wdir);
$ret = $test->write('file3', <<EOF_3);
Test file #3.
EOF_3
$test->fail(! $ret);
$test->cleanup('fail');
$test->fail(! -d $wdir);
$test->cleanup('pass');
$test->fail(-d $wdir);
$test->pass;
EOF
ok($ret);

$ret = close(PERL);
ok($ret);
ok($? == 0);

$string = contents("perl.stdout.3");
ok(defined $string);
ok(! $string);
$string = contents("perl.stderr.3");
ok(defined $string);
ok($string eq "PASSED\n");
