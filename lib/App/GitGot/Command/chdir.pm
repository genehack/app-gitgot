package App::GitGot::Command::chdir;

# ABSTRACT: open a subshell in a selected project
use 5.014;
use feature 'unicode_strings';

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
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

1;

### FIXME docs
