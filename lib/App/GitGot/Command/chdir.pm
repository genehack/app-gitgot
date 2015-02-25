package App::GitGot::Command::chdir;

# ABSTRACT: open a subshell in a selected project
use Mouse;
extends 'App::GitGot::Command';
use strict;
use warnings;
use 5.010;
use namespace::autoclean;

sub command_names { qw/ chdir cd / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  unless ( $self->active_repos and $self->active_repos == 1 ) {
    say STDERR 'ERROR: You need to select a single repo';
    exit(1);
  }

  my( $repo ) = $self->active_repos;

  chdir $repo->path
    or say STDERR "ERROR: Failed to chdir to repo ($!)" and exit(1);

  exec $ENV{SHELL};
}

__PACKAGE__->meta->make_immutable;
1;
