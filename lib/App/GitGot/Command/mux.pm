package App::GitGot::Command::mux;
# ABSTRACT: open a tmux window for a selected project

use Mouse;
extends 'App::GitGot::Command';
use 5.010;

sub command_names { qw/ mux tmux / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  unless ( $self->active_repos and $self->active_repos == 1 ) {
    say STDERR 'ERROR: You need to select a single repo';
    exit(1);
  }

  my( $repo ) = $self->active_repos;

  # is it already opened?
  my %windows = reverse map { /^(\d+):\s+(\S+)/ }
    split "\n", `tmux list-windows`;

  if( my $window = $windows{$repo->name} ) {
      exec 'tmux', 'select-window', '-t' => $window;
  }


  chdir $repo->path;

  exec 'tmux', 'new-window', '-n', $repo->name; 

}

__PACKAGE__->meta->make_immutable;
1;
