#! perl

use autodie;
use strict;
use warnings;

use Test::File;
use Test::More;

use App::Cmd::Tester;
use App::GitGot;
use Cwd               qw/ abs_path /;
use File::Temp        qw/ tempdir  /;
use YAML              qw/ LoadFile /;

my $dir    = tempdir(CLEANUP=>1);
chdir $dir;

my $config = abs_path( "$dir/gitgot" );
file_not_exists_ok $config , 'config does not exist';

$ENV{GITGOT_FAKE_GIT_WRAPPER} = 1;

{
  my $result = test_app( 'App::GitGot' => [ 'clone' , '-f' , $config ]);
  is $result->stdout , '' , 'nothing on STDOUT';
  like $result->stderr ,
    qr/ERROR: Need the URL to clone/ ,
    'need to give a URL';
  is $result->exit_code , 1 , 'exit with 1';
  file_not_exists_ok $config , 'failed command does not create config';
}

{
  my $result = test_app( 'App::GitGot' => [ 'clone' , '-f' , $config , '-D' ,
                                            'http://genehack.org/fake-git-repo.git' ]);

  is $result->stdout    , '' , 'no output';
  is $result->stderr    , '' , 'nothing on STDERR';
  is $result->exit_code , 0  , 'exit with 0';

  file_exists_ok $config , 'now config exists';

  my $entry = LoadFile( $config );
  is( $entry->[0]{name} , 'fake-git-repo'                  , 'expected name' );
  is( $entry->[0]{type} , 'git'                            , 'expected type' );
  is( $entry->[0]{path} , abs_path( "$dir/fake-git-repo" ) , 'expected path' );
}


done_testing();
