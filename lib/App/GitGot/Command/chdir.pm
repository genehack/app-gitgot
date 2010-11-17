package App::GitGot::Command::chdir;
# ABSTRACT: open a subshell in a selected project

use Moose;
extends 'App::GitGot::Command';
use 5.010;

sub command_names { qw/ chdir cd / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  unless ( $self->active_repos and $self->active_repos == 1 ) {
    say "You need to select a single repo";
    exit;
  }

  my( $repo ) = $self->active_repos;

  chdir $repo->path;
  exec $ENV{SHELL};
}

1;
