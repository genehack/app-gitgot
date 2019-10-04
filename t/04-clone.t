#! perl

use 5.014;                      # strict, unicode_strings
use warnings;
use autodie;

use lib 't/lib';
use Test::BASE;
use Test::File;
use Test2::V0;

use App::Cmd::Tester;
use App::GitGot;
use Path::Tiny;
use YAML              qw/ LoadFile /;

my $dir    = Test::BASE::create_tempdir_and_chdir();
my $config = path( "$dir/gitgot" );
file_not_exists_ok $config , 'config does not exist';

$ENV{GITGOT_FAKE_GIT_WRAPPER} = 1;

{
  my $result = test_app( 'App::GitGot' => [ 'clone' , '-f' , $config ]);

  is   $result->stdout    , '' , 'nothing on STDOUT';
  like $result->stderr    ,
    qr/ERROR: Need the URL to clone/ ,
    'need to give a URL';
  is   $result->exit_code , 1  , 'exit with 1';

  file_not_exists_ok $config , 'failed command does not create config';
}

{
  my $result = test_app( 'App::GitGot' => [ 'clone' , '-f' , $config , '-Dq' ,
                                            'http://genehack.org/fake-git-repo.git' ]);

  is $result->stdout    , '' , 'no output';
  is $result->stderr    , '' , 'nothing on STDERR';
  is $result->exit_code , 0  , 'exit with 0';

  file_exists_ok $config , 'now config exists';

  my $entry = LoadFile( $config );
  is( $entry->[0]{name} , 'fake-git-repo'              , 'expected name' );
  is( $entry->[0]{type} , 'git'                        , 'expected type' );
  is( $entry->[0]{path} , ''.path( "$dir/fake-git-repo" ) , 'expected path' );
}

chdir('/'); ## clean up temp files
done_testing();
