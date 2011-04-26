#! perl

use autodie;
use strict;
use warnings;

use Test::More;

use App::Cmd::Tester;
use App::GitGot;
use File::Temp        qw/ tempdir tempfile /;
use YAML              qw/ DumpFile LoadFile /;

my $dir           = tempdir();#CLEANUP=>1);
my( $fn , $name ) = tempfile();

my $config = [{
  name => 'foo.git' ,
  path => "$dir/foo.git" ,
  type => 'git' ,
  tags => 'foo' ,
},{
  name => 'bar.git' ,
  path => "$dir/bar.git" ,
  repo => 'github@github.com:genehack/bar.git' ,
  type => 'git'
}];
DumpFile( $name , $config );

{
  my $result = test_app( 'App::GitGot' => [ 'remove' , '-f' , $name ]);
  is $result->stdout , '' , 'nothing on STDOUT';
  like $result->stderr ,
    qr/ERROR: You need to select one or more repos to remove/ ,
      'need to give some repos';
  is $result->exit_code , 1 , 'exit with 1';
}

{
  my $result = test_app( 'App::GitGot' => [ 'remove' , '-f' , $name , 1 , '--force' ]);
  is $result->stdout , '' , 'nothing on STDOUT';
  is $result->stderr , '' , 'nothing on STDERR';
  is $result->exit_code , 0 , 'exit with 0';

  my $config = LoadFile( $name );
  my $expected = [{
    name => 'foo.git' ,
    path => "$dir/foo.git" ,
    type => 'git' ,
    tags => 'foo' ,
  }];
  is_deeply( $config , $expected , 'deleted repo' );
}

{
  my $result = test_app( 'App::GitGot' => [ 'remove' , '-f' , $name , 1 , '--force' , '-v' ]);
  is $result->stdout , "Removed repo 'foo.git'" , 'expected on STDOUT';
  is $result->stderr , '' , 'nothing on STDERR';
  is $result->exit_code , 0 , 'exit with 0';
  my $config = LoadFile( $name );
  my $expected = [];
  is_deeply( $config , $expected , 'deleted repo' );
}

done_testing();
