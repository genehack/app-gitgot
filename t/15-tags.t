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
use App::GitGot::Command::tag;

use Cwd;
use YAML;

my $dir = Test::BASE::create_tempdir_and_chdir();
my $config = "$dir/gitgot";

Test::BASE::build_fake_git_repo();
test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D' ]);

my $result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, ] );

is $result->stdout => '', 'no tag to begin with';

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

$result = test_app( 'App::GitGot' => [ 'tag', '-f', $config, '--add', qw/ perl git / ] );

is $result->error => " doesn't seem to be in a git directory\n", 'outside of repo';

chdir(); ## let File::Temp clean up...
done_testing();
