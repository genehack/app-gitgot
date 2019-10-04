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
use App::GitGot::Command::move;

use Cwd;
use YAML;

my $dir = Test::BASE::create_tempdir_and_chdir();
my $config = "$dir/gitgot";

Test::BASE::build_fake_git_repo('alpha');

my $one = test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D' ]);
$one->error
  and diag("App::GitGot add -f $config -D failed: " . $one->error);
chdir '..';

my $two = test_app( 'App::GitGot' => [ 'move', '-f', $config, '--dest', "$dir/gamma", 'alpha' ] );
$two->error
  and diag("App::GitGot move -f $config --dest $dir/gamma alpha failed: " . $two->error);

ok ! -d 'alpha', 'alpha is gone';
ok -d 'gamma', '...and replaced by gamma';

$config = YAML::LoadFile( $config );

is $config->[0]->{name} => 'alpha', 'right repo';
like $config->[0]->{path} => qr#.*/gamma#, 'moved to its new location';

chdir('/'); ## clean up temp files
done_testing();
