package App::GitGot::Command::do;

# ABSTRACT: run command in many repositories
use 5.014;
use feature 'unicode_strings';

use Capture::Tiny qw/ capture_stdout /;
use File::chdir;
use Types::Standard -types;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'command|e=s' => 'command to execute in the different repos' => { required => 1 } ] ,
    [ 'with_repo'   => 'prepend all output lines with the repo name' => { default => 0 } ] ,
  );
}

sub _execute {
  my $self = shift;

  for my $repo ( $self->active_repos ) {
    $self->_run_in_repo( $repo => $self->opt->command );
  }
}

sub _run_in_repo {
  my( $self, $repo, $cmd ) = @_;

  if ( not -d $repo->path ) {
    printf "repo %s: no repository found at path '%s'\n",
      $repo->label, $repo->path;
    return;
  }

  say "\n## repo ", $repo->label, "\n" unless $self->opt->with_repo;

  my $prefix = $self->opt->with_repo ? $repo->label . ': ' : '';

  say $prefix, $_ for split "\n", capture_stdout {
    $CWD = $repo->path;
    system $cmd;
  };
}

1;

### FIXME docs
