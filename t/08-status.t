#! perl

use autodie;
use strict;
use warnings;

use lib 't/lib';
use Test::BASE;
use Test::More;

use App::Cmd::Tester;
use App::GitGot;

my( $config , $dir ) = Test::BASE::write_fake_config();

$ENV{GITGOT_FAKE_GIT_WRAPPER} = 1;

{
  my $result = test_app( 'App::GitGot' => [ 'status' , '-f' , $config , '-C' ]);

  like $result->stdout , qr|1\)\s+bar\.git\s+\:\s+OK| , 'repo 1';
  like $result->stdout , qr|3\)\s+foo\.git\s+\:\s+ERROR: repo 'foo.git' does not exist| , 'repo 3';
  like $result->stdout , qr|4\)\s+xxx\.git\s+\:\s+OK| , 'repo 4';

  is   $result->stderr    , '' , 'nothing on STDERR';
  is   $result->exit_code , 0  , 'exit with 0';
}

{
  my $result = test_app( 'App::GitGot' => [ 'status' , '-f' , $config , '-C' , '-v' ]);

  like $result->stdout , qr|1\)\s+bar\.git\s+\:\s+OK| , 'repo 1';
  like $result->stdout , qr|3\)\s+foo\.git\s+\:\s+ERROR: repo 'foo.git' does not exist| , 'repo 3';
  like $result->stdout , qr|4\)\s+xxx\.git\s+\:\s+OK| , 'repo 4';

  is   $result->stderr    , '' , 'nothing on STDERR';
  is   $result->exit_code , 0  , 'exit with 0';
}

chdir(); ## let File::Temp clean up...
done_testing();
