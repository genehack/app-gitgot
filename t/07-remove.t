#! perl

use autodie;
use strict;
use warnings;

use lib 't/lib';
use Test::BASE;
use Test::More;

use App::Cmd::Tester;
use App::GitGot;
use YAML              qw/ DumpFile LoadFile /;

my( $config , $dir ) = Test::BASE::write_fake_config();

{
  my $result = test_app( 'App::GitGot' => [ 'remove' , '-f' , $config ]);

  is   $result->stdout    , '' , 'nothing on STDOUT';
  like $result->stderr    ,
    qr/ERROR: You need to select one or more repos to remove/ ,
    'need to give some repos';
  is   $result->exit_code , 1  , 'exit with 1';
}

{
  my $result = test_app( 'App::GitGot' => [ 'remove' , '-f' , $config , 1 , '--force' ]);

  is $result->stdout    , '' , 'nothing on STDOUT';
  is $result->stderr    , '' , 'nothing on STDERR';
  is $result->exit_code , 0  , 'exit with 0';

  my $config   = LoadFile( $config );
  my $expected = [{
    name => 'foo.git' ,
    path => "$dir/foo.git" ,
    type => 'git' ,
    tags => 'foo' ,
  },{
    name => 'xxx.git' ,
    path => "$dir/xxx.git" ,
    type => 'git'
  }];
  is_deeply( $config , $expected , 'deleted repo' );
}

{
  my $result = test_app( 'App::GitGot' => [ 'remove' , '-f' , $config , 1 , '--force' , '-v' ]);

  is $result->stdout    , "Removed repo 'foo.git'" , 'expected on STDOUT';
  is $result->stderr    , ''                       , 'nothing on STDERR';
  is $result->exit_code , 0                        , 'exit with 0';

  my $config = LoadFile( $config );
  my $expected = [{
    name => 'xxx.git' ,
    path => "$dir/xxx.git" ,
    type => 'git'
  }];
  is_deeply( $config , $expected , 'deleted repo' );
}

done_testing();
