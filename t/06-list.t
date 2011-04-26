#! perl

use autodie;
use strict;
use warnings;

use Test::More;

use App::Cmd::Tester;
use App::GitGot;
use File::Temp        qw/ tempdir tempfile /;
use YAML              qw/ DumpFile /;

my $dir           = tempdir(CLEANUP=>1);
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
  my $result = test_app( 'App::GitGot' => [ 'list' , '-f' , $name ]);

  my $out = $result->stdout;

  like $out , qr|1\)\s*bar\.git\s*git\s*github\@github.com:genehack/bar.git\s*\(Not checked out\)| , 'first repo';
  like $out , qr|2\)\s*foo\.git\s*git\s*ERROR: No remote and no repo\?\!| , 'second repo';

  is $result->stderr , '' , 'nothing on STDERR';
  is $result->exit_code , 0 , 'exit with 0';
}
{
  my $result = test_app( 'App::GitGot' => [ 'list' , '-f' , $name , '-q' ]);

  my $out = $result->stdout;

  like $out , qr|1\)\s*bar\.git| , 'first repo';
  like $out , qr|2\)\s*foo\.git| , 'second repo';

  is $result->stderr , '' , 'nothing on STDERR';
  is $result->exit_code , 0 , 'exit with 0';
}
{
  my $result = test_app( 'App::GitGot' => [ 'list' , '-f' , $name , '-v' ]);

  my $out = $result->stdout;

  like $out , qr|1\)\s*bar\.git\s*git\s*github\@github.com:genehack/bar.git\s*\(Not checked out\)| , 'first repo';
  like $out , qr|2\)\s*foo\.git\s*git\s*ERROR: No remote and no repo\?\!| , 'second repo';

  is $result->stderr , '' , 'nothing on STDERR';
  is $result->exit_code , 0 , 'exit with 0';
}

done_testing();
