#! perl

use 5.014;                      # strict, unicode_strings
use warnings;
use autodie;

use lib 't/lib';
use Test::BASE;
use Test::More;

use App::Cmd::Tester;
use App::GitGot;

my( $config , $dir ) = Test::BASE::write_fake_config();

{
  my $result = test_app( 'App::GitGot' => [ 'chdir' , '-f' , $config ]);

  is   $result->stdout    , '' , 'nothing on STDOUT';
  like $result->stderr    ,
    qr/ERROR: You need to select a single repo/ ,
    'need to select a repo';
  is   $result->exit_code , 1  , 'exit with 1';
}

{
  my $result = test_app( 'App::GitGot' => [ 'chdir' , '-f' , $config , 2 ]);

  is   $result->stdout    , ''                          , 'no output';
  like $result->stderr    , qr/Failed to chdir to repo/ , 'msg about non-existant dir';
  is   $result->exit_code , 1                           , 'exit with 1';
}

chdir(); ## let File::Temp clean up...
done_testing();
