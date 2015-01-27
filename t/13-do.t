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
use App::GitGot::Command::do;

use Capture::Tiny qw/ capture /;

use Cwd;

my $dir = Test::BASE::create_tempdir_and_chdir();
my $config = "$dir/gitgot";

for my $repo ( qw/ alpha beta / ) {
    Test::BASE::build_fake_git_repo($repo);
    test_app( 'App::GitGot' => [ 'add' , '-f' , $config  , '-D' ]);
    open my $fh, '>', "$repo.txt";
    print $fh "test";
    chdir '..';
}

@ARGV = ( qw/ do -f /, $config, qw/ --command ls --all / );

my( $stdout, $stderr, $exit ) = capture {
    App::GitGot->run;
};

like $stdout  , qr/##.*alpha.*alpha\.txt/s, 'alpha is listed';
like $stdout  , qr/##.*beta.*beta\.txt/s, 'beta is listed';
is $stderr    , '' , 'nothing on stderr';

@ARGV = ( qw/ do -f /, $config, qw/ --with_repo --command ls --all / );

( $stdout, $stderr, $exit ) = capture {
    App::GitGot->run;
};

like $stdout  , qr/alpha: alpha\.txt/, 'output preprended with repo name';


chdir(); ## let File::Temp clean up...
done_testing();
