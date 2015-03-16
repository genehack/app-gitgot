package App::GitGot::Command::clone;

# ABSTRACT: clone a remote repo and add it to your config
use 5.014;

use Cwd;
use Path::Tiny;
use IO::Prompt::Simple;
use Types::Standard -types;

use App::GitGot -command;
use App::GitGot::Repo::Git;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'defaults|D' => 'FIXME' ] ,
  );
}

sub _execute {
  my ( $self, $opt, $args ) = @_;

  my ( $repo , $path ) = @$args;

  $repo // ( say STDERR 'ERROR: Need the URL to clone!' and exit(1) );

  my $cwd = getcwd
    or( say STDERR "ERROR: Couldn't determine path" and exit(1) );

  my $name = path( $repo )->basename;
  $name =~ s/.git$//;

  $path //= "$cwd/$name";
  $path = path( $path )->absolute;

  my $tags;

  unless ( $self->opt->defaults ) {
    $name = prompt( 'Name: ' , $name );
    $path = prompt( 'Path: ' , $path );
    $tags = prompt( 'Tags: ' , $tags );
  }

  my $new_entry = App::GitGot::Repo::Git->new({ entry => {
    repo => $repo,
    name => $name,
    type => 'git',
    path => $path,
  }});
  $new_entry->{tags} = $tags if $tags;

  $new_entry->clone( $repo , $path );

  $self->add_repo( $new_entry );
  $self->write_config;
}

1;

### FIXME docs
