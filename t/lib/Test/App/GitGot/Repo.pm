package Test::App::GitGot::Repo;
use parent 'Test::BASE';

use 5.014;                      # strict, unicode_strings
use warnings;

use App::GitGot::Repo;
use File::Temp         qw/ tempdir /;
use Path::Tiny;
use Test2::V0;

sub new_ok($$) {
    my($class, $args, $title) = @_;
    my $obj = $class->new(@$args);
    isa_ok $obj, $class;
    return $obj;
}

sub fixtures :Test(startup) {
  my $test = shift;

  $test->{lib} = 'App::GitGot::Repo';

  $test->make_base_fixtures;
}

sub test_constructor :Test(2) {
  my $test  = shift;
  my $lib   = $test->{lib};
  my $entry = $test->{entry};

  new_ok( $lib , [{ entry => $entry }] );

  like dies { $lib->new({}) },
    qr/Must provide entry/ , 'expected error message' ;
}

sub test_accessors :Tests(8) {
  my $test = shift;

  my $full = $test->{full};
  my $min  = $test->{min};

  # only test the ones that get munged in BUILDALL...

  is( $full->name , 'my-full-repo' , 'full name' );
  is( $min->name  , 'my-repo'      , 'min  name' );

  is( $full->number , 1 , 'full number' );
  is( $min->number  , 0 , 'min  number' );

  is( $full->repo , 'git@github:/luser/my-full-repo.git' , 'full repo' );
  is( $min->repo  , ''                                   , 'min repo'  );

  is( $full->tags , 'tag1,tag2' , 'full tags' );
  is( $min->tags  , ''          , 'min  tags' );

}

sub test_in_writable_format :Tests(2) {
  my $test = shift;

  {
    my $entry = {
      name   => 'my-repo' ,
      path   => $test->{minpath} ,
      type   => 'git' ,
    };
    my $min   = $test->{min};

    is $min->in_writable_format , $entry , 'min serialized properly';
  }
  {
    my $entry = {
      name  => 'my-full-repo' ,
      path  => '/home/luser/proj/my-full-repo' ,
      type  => 'git' ,
      repo  => 'git@github:/luser/my-full-repo.git' ,
      tags  => 'tag1,tag2' ,
    };
    my $full = $test->{full};

    is $full->in_writable_format , $entry , 'full serialized properly';
  }
}

sub cleanup :Test(shutdown) { chdir('/') }

sub make_base_fixtures {
  my $test = shift;
  my $lib  = $test->{lib};

  $test->{minpath} = _make_git_repo();

  $test->{entry} = {
    name   => 'my-repo' ,
    path   => $test->{minpath} ,
    type   => 'git' ,
  };

  $test->{full} = $lib->new({
    count => 1 ,
    entry => {
      path  => '/home/luser/proj/my-full-repo' ,
      type  => 'git' ,
      repo  => 'git@github:/luser/my-full-repo.git' ,
      tags  => 'tag1,tag2' ,
      label => 'testlabel' ,
    } ,
  });

  $test->{min}  = $lib->new({ entry => $test->{entry} });
}

sub _make_git_repo {
  my $dir = tempdir(CLEANUP=>1);
  chdir( $dir );
  `git init`;
  path('foo')->touch;
  `git add foo`;
  `git commit -m"mu"`;
  return $dir;
}

1;
