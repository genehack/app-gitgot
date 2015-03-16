package Test::BASE;
use parent 'Test::Class';

use 5.014;                      # strict, unicode_strings
use warnings;

use Carp;
use Path::Tiny;
use YAML               qw/ DumpFile /;

INIT {
  my $config = Path::Tiny->tempfile();
  $ENV{GIT_CONFIG} = $config;
  Test::Class->runtests;
}

sub build_fake_git_repo {
  my $repo = shift || 'foo.git';
  `mkdir $repo && cd $repo && git init && touch foo && git add foo && git commit -m"mu"`;
  `cd $repo && touch bar && git add bar && git commit -m"mu2"`;
  chdir $repo;
}

sub create_github_identity_file {
  path( '.github-identity')->spew(<<EOF);
user luser
pass my-user-token-thingie
EOF
}

sub create_tempdir_and_chdir {
  my $dir = Path::Tiny->tempdir(CLEANUP=>1);
  chdir $dir;
  return $dir;
}

sub write_fake_config {
  my $dir = create_tempdir_and_chdir();

  my $config = [{
    name => 'foo.git' ,
    path => "$dir/foo.git" ,
    type => 'git',
    tags => 'foo' ,
  },{
    name => 'bar.git' ,
    path => "$dir/bar.git" ,
    repo => 'github@github.com:genehack/bar.git' ,
    type => 'git'
  },{
    name => 'xxx.git' ,
    path => "$dir/xxx.git" ,
    type => 'git'
  },{
    name => 'bargle.git' ,
    path => "$dir/bargle.git" ,
    repo => 'github@github.com:genehack/bargle.git' ,
    type => 'git'
  }];

  build_fake_git_repo( 'xxx.git' );
  chdir('..');

  build_fake_git_repo( 'bar.git' );
  chdir('..');

  my $name = Path::Tiny->tempfile();
  DumpFile( $name , $config );

  return( $name , $dir );
}

1;
