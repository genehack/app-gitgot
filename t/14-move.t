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
use App::GitGot::Command::move;

use Cwd;
use YAML;

my $dir = Test::BASE::create_tempdir_and_chdir();
my $config = "$dir/gitgot";

Test::BASE::build_fake_git_repo('alpha');
test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D' ]);
chdir '..';

test_app( 'App::GitGot' => [ 'move', '-f', $config, '--dest', "$dir/gamma", 'alpha' ] );

ok ! -d 'alpha', 'alpha is gone';
ok -d 'gamma', '...and replaced by gamma';

$config = YAML::LoadFile( $config );

is $config->[0]->{name} => 'alpha', 'right repo';
like $config->[0]->{path} => qr#.*/gamma#, 'moved to its new location'; 

chdir(); ## let File::Temp clean up...
done_testing();
