# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Config;
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
    plan tests => 34, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my($run_env, $ret, $testx, $test, $subdir);

#
# The following complicated dance attempts to ensure we can create
# an executable Perl script named "scriptx" on both UNIX and Win32
# systems.  We want it to be Perl since its about the only thing
# that we can rely on in common between the systems.
#
# The UNIX side is easy; we just put our desired Perl script in
# the file name with $Config{startperl} at the top, chmod it
# executable, and away we go.
#
# For Win32, we go the route of creating a "scriptx.bat" file with
# the magic header that reads as both an NT and a Perl script.
# The hassle is that we want this .bat file to be executable
# regardless of where we are at the moment, and the only way I
# could figure out how to do this was to put the absolute path
# name to the file in the .bat file as the first argument to
# the perl.exe invocation.  This means that we have to create our
# initial running environments up front, so we know where the
# "scriptx.bat" file will end up and can put its path name in
# itself.
#
# If anyone cares to suggest an easier way to do this, I'd be
# thrilled to hear about it.
#
$My_Config{_bat} = $iswin32 ? '.bat' : '';

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

my $script = "script";
my $scriptx = "scriptx$My_Config{_bat}";

if ($iswin32) {
    my $workpath_scriptx = $run_env->workpath($scriptx);
    $My_Config{startperl} = <<EOF;
\@rem = '--*-PERL-*--';
\@rem = '
\@echo off
rem setlocal
set ARGS=
:loop
if .%1==. goto endloop
set ARGS=%ARGS% %1
shift
goto loop
:endloop
rem ***** This assumes PERL is in the PATH *****
perl.exe $workpath_scriptx %ARGS%
goto endofperl
\@rem ';
EOF
    $My_Config{endperl} = <<'EOF';
#:endofperl
EOF
    $My_Config{cwd_pkg} = 'Win32';
    $My_Config{cwd_sub} = 'Win32::GetCwd';
} else {
    $My_Config{startperl} = $Config{startperl};
    $My_Config{endperl} = '';
    $My_Config{cwd_pkg} = 'Cwd';
    $My_Config{cwd_sub} = 'cwd';
}

#
$ret = $run_env->write($script, <<EOF);
use $My_Config{cwd_pkg};
my \$cwd = $My_Config{cwd_sub}();
print STDOUT "$script:  STDOUT:  \$cwd:  '\@ARGV'\\n";
print STDERR "$script:  STDERR:  \$cwd:  '\@ARGV'\\n";
exit 0;
EOF
ok($ret);

$ret = $run_env->write($scriptx, <<EOF);
$My_Config{startperl}
use $My_Config{cwd_pkg};
my \$cwd = $My_Config{cwd_sub}();
print STDOUT "$scriptx:  STDOUT:  \$cwd:  '\@ARGV'\\n";
print STDERR "$scriptx:  STDERR:  \$cwd:  '\@ARGV'\\n";
exit 0;
$My_Config{endperl};
EOF
ok($ret);

$ret = chmod(0755, $scriptx) if ! $iswin32;
skip($iswin32, $ret == 1);

ok(! -x $script);
ok(-x $scriptx);

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.

#
$test = Test::Cmd->new(prog => 'script', interpreter => "$^X", workdir => '', subdir => 'script_subdir');
ok($test);

$test->run();
ok($? == 0);
ok($test->stdout eq "script:  STDOUT:  $wdir:  ''\n");
ok($test->stderr eq "script:  STDERR:  $wdir:  ''\n");

$test->run(args => 'arg1 arg2 arg3');
ok($? == 0);
ok($test->stdout eq "script:  STDOUT:  $wdir:  'arg1 arg2 arg3'\n");

$test->run(chdir => $test->curdir, args => 'x y z');
ok($? == 0);
ok($test->stdout eq "script:  STDOUT:  ${\$test->workdir}:  'x y z'\n");
ok($test->stderr eq "script:  STDERR:  ${\$test->workdir}:  'x y z'\n");

$subdir = $test->workpath('script_subdir');

$test->run(chdir => 'script_subdir');
ok($? == 0);
ok($test->stdout eq "script:  STDOUT:  $subdir:  ''\n");
ok($test->stderr eq "script:  STDERR:  $subdir:  ''\n");

#
$testx = Test::Cmd->new(prog => 'scriptx', workdir => '', subdir => 'scriptx_subdir');
ok($testx);

$testx->run();
ok($? == 0);
ok($testx->stdout eq "$scriptx:  STDOUT:  $wdir:  ''\n");
ok($testx->stderr eq "$scriptx:  STDERR:  $wdir:  ''\n");

$testx->run(args => 'foo bar');
ok($? == 0);
ok($testx->stdout eq "$scriptx:  STDOUT:  $wdir:  'foo bar'\n");
ok($testx->stderr eq "$scriptx:  STDERR:  $wdir:  'foo bar'\n");

$testx->run(chdir => $testx->curdir, args => 'baz');
ok($? == 0);
ok($testx->stdout eq "$scriptx:  STDOUT:  ${\$testx->workdir}:  'baz'\n");
ok($testx->stderr eq "$scriptx:  STDERR:  ${\$testx->workdir}:  'baz'\n");

$subdir = $testx->workpath('scriptx_subdir');

$testx->run(chdir => 'scriptx_subdir');
ok($? == 0);
ok($testx->stdout eq "$scriptx:  STDOUT:  $subdir:  ''\n");
ok($testx->stderr eq "$scriptx:  STDERR:  $subdir:  ''\n");
