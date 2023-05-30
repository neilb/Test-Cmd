#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( BAIL_OUT isa_ok ok plan subtest use_ok ) ], tests => 4;
my $class;

BEGIN {
  $class = 'Test::Cmd';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

subtest 'verbosity not specified at creation time' => sub {
  plan tests => 3;

  isa_ok my $test = Test::Cmd->new, $class;
  ok( !$test->{ verbose }, 'is false' );

  $test->verbose( 1 );
  ok( $test->{ verbose }, 'set to true' );
};

subtest 'verbosity set to true at creation time' => sub {
  plan tests => 3;

  isa_ok my $test = Test::Cmd->new( verbose => 1 ), $class;
  ok( $test->{ verbose }, 'is true' );

  $test->verbose( 0 );
  ok( !$test->{ verbose }, 'set to false' );
};

subtest 'verbosity set to false at creation time' => sub {
  plan tests => 3;

  isa_ok my $test = Test::Cmd->new( verbose => 0 ), $class;
  ok( !$test->{ verbose }, 'is false' );

  $test->verbose( 1 );
  ok( $test->{ verbose }, 'set to true' );
};
