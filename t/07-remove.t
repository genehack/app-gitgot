#! perl

use 5.014;                      # strict, unicode_strings
use warnings;
use autodie;

use lib 't/lib';
use Test::BASE;
use Test2::V0;

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
    name => 'bargle.git' ,
    path => "$dir/bargle.git" ,
    repo => 'github@github.com:genehack/bargle.git' ,
    type => 'git' ,
  },{
    name => 'foo.git' ,
    path => "$dir/foo.git" ,
    type => 'git' ,
    tags => 'foo' ,
  },{
    name => 'xxx.git' ,
    path => "$dir/xxx.git" ,
    type => 'git'
  }];
  is $config , $expected , 'deleted repo';
}

{
  my $result = test_app( 'App::GitGot' => [ 'remove' , '-f' , $config , 2 , '--force' , '-v' ]);

  like $result->stdout    , qr/^Removed repo 'foo\.git'/ , 'expected on STDOUT';
  is   $result->stderr    , ''                           , 'nothing on STDERR';
  is   $result->exit_code , 0                            , 'exit with 0';

  my $config = LoadFile( $config );
  my $expected = [{
    name => 'bargle.git' ,
    path => "$dir/bargle.git" ,
    repo => 'github@github.com:genehack/bargle.git' ,
    type => 'git' ,
  },{
    name => 'xxx.git' ,
    path => "$dir/xxx.git" ,
    type => 'git'
  }];
  is $config , $expected , 'deleted repo';
}

chdir('/');  # clean up temp files
done_testing();
