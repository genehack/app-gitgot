package Test::BASE;
use parent 'Test::Class';

use strict;
use warnings;
use 5.010;

use Carp;
use File::Slurp;
use File::Temp   qw/ tempdir tempfile /;
use YAML         qw/ DumpFile /;

INIT { Test::Class->runtests }

sub build_fake_git_repo {
  my $repo = shift || 'foo.git';
  `mkdir $repo && cd $repo && git init && touch foo && git add foo && git ci -m"mu"`;
  `touch bar && git add bar && git ci -m"mu2"`;
  chdir $repo;
}

sub create_github_identity_file {
  write_file( '.github-identity' , <<EOF );
login luser
token my-user-token-thingie
EOF
}

sub create_tempdir_and_chdir {
  my $dir = tempdir(CLEANUP=>1);
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

  my( $fh , $name ) = tempfile();
  DumpFile( $name , $config );

  return( $name , $dir );
}

1;
