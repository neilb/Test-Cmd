# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { $| = 1; plan tests => 35, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

$here = Test::Cmd->here();
my @I_FLAGS = map(Test::Cmd->file_name_is_absolute($_) ? "-I$_" :
			"-I".Test::Cmd->catfile($here, $_), @INC);

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

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($run_env, $ret, $wdir, $test, $string);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$ret = $run_env->write('run', <<EOF);
print STDOUT "run:  STDOUT\\n";
print STDERR "run:  STDERR\\n";
exit 0;
EOF
ok($ret);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.
$ret = open(PERL, "|$^X -w @I_FLAGS >stdout.1 2>stderr.1");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
$test = Test::Cmd->new(prog => 'run', interpreter => "$^X", workdir => '');
$test->run();
Test::Cmd->fail($? == 0);
EOF
ok($ret);

$ret = close(PERL);
ok(! $ret);
ok(($? >> 8) == 1);

$string = contents("stdout.1");
ok($string eq "");
$string = contents("stderr.1");
ok($string eq "FAILED test at line 4 of -.\n");

#
$ret = open(PERL, "|$^X -w @I_FLAGS >stdout.2 2>stderr.2");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
$test = Test::Cmd->new(prog => 'run', interpreter => "$^X", workdir => '');
$test->run();
$test->fail($? == 0);
EOF
ok($ret);

$ret = close(PERL);
ok(! $ret);
ok(($? >> 8) == 1);

$string = contents("stdout.2");
ok($string eq "");
$string = contents("stderr.2");
ok($string eq "FAILED test of run\n\tat line 4 of -.\n");

#
$ret = open(PERL, "|$^X -w @I_FLAGS >stdout.3 2>stderr.3");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
$test = Test::Cmd->new(prog => 'run', interpreter => "$^X", string => 'xyzzy', workdir => '');
$test->run();
$test->fail($? == 0);
EOF
ok($ret);

$ret = close(PERL);
ok(! $ret);
ok(($? >> 8) == 1);

$string = contents("stdout.3");
ok($string eq "");
$string = contents("stderr.3");
ok($string eq "FAILED test of run [xyzzy]\n\tat line 4 of -.\n");

#
$ret = open(PERL, "|$^X -w @I_FLAGS >stdout.4 2>stderr.4");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
$test = Test::Cmd->new(prog => 'run', interpreter => "$^X", workdir => '');
$test->run();
$test->fail($? == 0 => sub {print STDERR "Printed on failure.\n"});
EOF
ok($ret);

$ret = close(PERL);
ok(! $ret);
ok(($? >> 8) == 1);

$string = contents("stdout.4");
ok($string eq "");
$string = contents("stderr.4");
ok($string eq "Printed on failure.\nFAILED test of run\n\tat line 4 of -.\n");

#
$ret = open(PERL, "|$^X -w @I_FLAGS >stdout.5 2>stderr.5");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
sub test_it {
	my $self = shift;
	$self->run();
	$self->fail($? == 0 => undef, 1);
}
$test = Test::Cmd->new(prog => 'run', interpreter => "$^X", workdir => '');
&test_it($test);
EOF
ok($ret);

$ret = close(PERL);
ok(! $ret);
ok(($? >> 8) == 1);

$string = contents("stdout.5");
ok($string eq "");
$string = contents("stderr.5");
ok($string eq "FAILED test of run\n\tat line 5 of - (main::test_it)\n\tfrom line 8 of -.\n");
