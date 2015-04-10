package Test::BASE;
use parent 'Test::Class';

use 5.014;                      # strict, unicode_strings
use warnings;

use Carp;
use File::chdir;
use File::Temp         qw/ tempdir tempfile /;
use Path::Tiny;
use YAML               qw/ DumpFile /;

INIT {
  my $config = tempfile(UNLINK => 1);
  $ENV{GIT_CONFIG} = $config;
  Test::Class->runtests;
}

sub build_fake_git_repo {
  my $repo = shift || 'foo.git';
  path($repo)->mkpath;
  $CWD = $repo;
  `git init`;
  `git config user.name "Boo"`;
  `git config user.email "radley\@example.com"`;
  foreach my $x ( qw/ foo bar / ) {
    path($x)->touch;
    `git add $x`;
    `git commit -m"$x"`;
  }
  chdir $repo;
}

sub create_github_identity_file {
  path( '.github-identity')->spew(<<EOF);
user luser
pass my-user-token-thingie
EOF
}

sub create_tempdir_and_chdir {
  my $dir = tempdir(CLEANUP=>1);
  chdir $dir;
  return path($dir)->realpath;
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

  my( undef , $name ) = tempfile(UNLINK=>1);
  DumpFile( $name , $config );

  return( $name , $dir );
}

1;
