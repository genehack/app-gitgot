#! perl

use autodie;
use strict;
use warnings;

use lib 't/lib';
use Test::BASE;
use Test::More;

use App::Cmd::Tester;
use App::GitGot;
use YAML              qw/ DumpFile /;

my( $config , $dir ) = Test::BASE::write_fake_config();

{
  my $result = test_app( 'App::GitGot' => [ 'list' , '-f' , $config ]);

  like $result->stdout ,
    qr|1\)\s*bar\.git\s*git\s*github\@github.com:genehack/bar.git\s*\(Not checked out\)| ,
    'first repo';

  like $result->stdout ,
    qr|2\)\s*foo\.git\s*git\s*ERROR: No remote and no repo\?\!| ,
    'second repo';

  is $result->stderr    , '' , 'nothing on STDERR';
  is $result->exit_code , 0  , 'exit with 0';
}

{
  my $result = test_app( 'App::GitGot' => [ 'list' , '-f' , $config , '-q' ]);

  like $result->stdout , qr|1\)\s*bar\.git| , 'first repo';
  like $result->stdout , qr|2\)\s*foo\.git| , 'second repo';

  is $result->stderr    , '' , 'nothing on STDERR';
  is $result->exit_code , 0  , 'exit with 0';
}

{
  my $result = test_app( 'App::GitGot' => [ 'list' , '-f' , $config , '-v' ]);

  like $result->stdout ,
    qr|1\)\s*bar\.git\s*git\s*github\@github.com:genehack/bar.git\s*\(Not checked out\)| ,
    'first repo';

  like $result->stdout ,
    qr|2\)\s*foo\.git\s*git\s*ERROR: No remote and no repo\?\!| ,
    'second repo';

  is $result->stderr    , '' , 'nothing on STDERR';
  is $result->exit_code , 0  , 'exit with 0';
}

done_testing();
