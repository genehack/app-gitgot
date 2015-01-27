#! perl

use autodie;
use strict;
use warnings;

use lib 't/lib';
use Test::BASE;
use Test::File;
use Test::More;

use App::Cmd::Tester;
use App::GitGot;
use App::GitGot::Command::add;
use Cwd;
use YAML              qw/ LoadFile /;

my $dir = Test::BASE::create_tempdir_and_chdir();

{
  my $result = test_app( 'App::GitGot' => [ 'add' ]);

  is   $result->stdout    , ''                              , 'empty STDOUT';
  like $result->stderr    , qr/Non-git repos not supported/ , 'expected error on STDERR';
  is   $result->exit_code , 1                               , 'exit with 1';
}

my $config = "$dir/gitgot";
file_not_exists_ok $config , 'no config';

Test::BASE::build_fake_git_repo();

{
  my $result = test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D' ]);

  is $result->stdout    , '' , 'nothing on stdout';
  is $result->stderr    , '' , 'nothing on stderr';
  is $result->exit_code , 0  , 'exit with 0';

  file_exists_ok $config , 'config exists';

  my $entry = LoadFile( $config );
  is( $entry->[0]{name} , 'foo.git' , 'expected name' );
  is( $entry->[0]{type} , 'git'     , 'expected type' );
  is( $entry->[0]{path} , getcwd()  , 'expected path' );
}

{
  my $result = test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D' ]);

  is   $result->stdout    , '' , 'empty STDOUT';
  like $result->stderr    ,
    qr/ERROR: Not adding entry for 'foo.git'; exact duplicate already exists/ ,
    'msg that cannot add same repo twice on STDERR';
  is   $result->exit_code , 1  , 'exit with 1';
}

chdir(); ## let File::Temp clean up...
done_testing();
