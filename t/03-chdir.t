#! perl

use autodie;
use strict;
use warnings;

use Test::More;

use App::Cmd::Tester;
use App::GitGot;
use File::Temp        qw/ tempdir tempfile /;
use YAML              qw/ DumpFile /;

my $dir = tempdir(CLEANUP=>1);

my $config = [{
  name => 'foo.git' ,
  path => "$dir/foo.git" ,
  type => 'git'
},{
  name => 'bar.git' ,
  path => "$dir/bar.git" ,
  type => 'git'
}];

my( $fh , $name ) = tempfile();
DumpFile( $name , $config );

{
  my $result = test_app( 'App::GitGot' => [ 'chdir' , '-f' , $name ]);
  is $result->stdout , '' , 'nothing on STDOUT';
  like $result->stderr ,
    qr/ERROR: You need to select a single repo/ ,
    'need to select a repo';
  is $result->exit_code , 1 , 'exit with 1';
}

{
  my $result = test_app( 'App::GitGot' => [ 'chdir' , '-f' , $name , 1 ]);
  is $result->stdout   , '' , 'no output';
  like $result->stderr , qr/Failed to chdir to repo/ , 'msg about non-existant dir';
  is $result->exit_code , 1 , 'exit with 1';
}


done_testing();
