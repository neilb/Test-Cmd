# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
BEGIN { $| = 1; plan tests => 6, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($test, $ret, @lines, @regexes);

$ret = Test::Cmd->match("abcde\n", "a.*e\n");
ok($ret);

$test = Test::Cmd->new;
ok($test);

$ret = $test->match("abcde\n", "a.*e\n");
ok($ret);

$ret = $test->match(<<'_EOF_', <<'_EOF_');
12345
abcde
_EOF_
1\d+5
a.*e
_EOF_
ok($ret);

@lines = ( "vwxyz\n", "67890\n" );
@regexes = ( "v[^a-u]*z\n", "6\\S+0\n");

$ret = $test->match(\@lines, \@regexes);
ok($ret);
