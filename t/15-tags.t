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
use App::GitGot::Command::tag;

use Cwd;
use YAML;

my $dir = Test::BASE::create_tempdir_and_chdir();
my $config = "$dir/gitgot";

Test::BASE::build_fake_git_repo();
my $result = test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D' ]);
$result->error
  and diag("App::GitGot add -f $config -D failed: " . $result->error);

{
  my $result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, ] );

  is $result->stdout => '', 'no tag to begin with';
}

subtest 'add tags' => sub {
    my $result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, '--add', qw/ perl git / ] );
    is $result->stdout => "tags added\n", 'added tags';

    $result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, ] );
    like $result->stdout => qr/git\s*perl/m, 'tags are listed';
};

subtest 'remove tags' => sub {
    my $result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, '--remove', qw/ git / ] );
    is $result->stdout => "tags removed\n", 'remove tags';

    $result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, ] );
    like $result->stdout => qr/^\s*perl\s*$/m, 'no more git'
};

my $yaml = YAML::LoadFile( $config );

is $yaml->[0]->{tags} => 'perl', 'config holds the tags';

$result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, '--remove', '--add', qw/ git / ] );

is $result->stdout => "can't --add and --remove at the same time\n", 'simultaneous add/remove';

chdir '..';
my $current_dir = getcwd();

$result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, '--add', qw/ perl git / ] );

is $result->error => "$current_dir doesn't seem to be in a git directory\n", 'outside of repo';

chdir('/'); ## clean up temp files
done_testing();
