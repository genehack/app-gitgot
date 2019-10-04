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
use App::GitGot::Command::add;
use Class::Load                 qw/ try_load_class /;
use Cwd;
use YAML                        qw/ LoadFile /;


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

  like $result->stdout, qr/
        Add \s repository \s at \s '.*?'\? \s+ \(y\/n\) \s \[y\]: \s y \s+
        Name\? \s+ \[foo.git\]: \s+ foo.git \s+
        Tracking \s remote\? \s+  : \s+
        Tags\? \s+  \[\]:
   /x, 'interaction auto-filled';

  my $err = $result->stderr;
  $err =~ s/-\w on unopened filehandle STDOUT.*?\n//g; # test_app mess with STDOUT
  is $err    , '' , 'nothing on stderr';
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
    qr/Repository at '.+' already registered with Got, skipping/,
    'msg that cannot add same repo twice on STDERR';
  is   $result->exit_code , 0, 'exit with 0';
}

chdir('/'); ## clean up tempfiles

subtest 'recursive behavior' => sub {
 SKIP:
  {
    skip 'Test requires Path::Iterator::Rule' , 1
      unless try_load_class( 'Path::Iterator::Rule' );

    my $dir = Test::BASE::create_tempdir_and_chdir();

    for my $repo ( qw/ alpha beta / ) {
        Test::BASE::build_fake_git_repo( $repo );
        chdir '..';
    }
    my $config = "$dir/gitgot";

    my $result = test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D', '--recursive' ]);
    $result->error
      and diag("App::GitGot add -f $config -D --recursive failed: " . $result->error);

    is [ sort map { $_->{name} } @{ LoadFile($config) } ]  => [
        qw/ alpha beta /
    ], 'all repositores detected';

    chdir();
  }
};

done_testing();
