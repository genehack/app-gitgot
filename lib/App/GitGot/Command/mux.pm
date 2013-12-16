package App::GitGot::Command::mux;
# ABSTRACT: open a tmux window for a selected project

use Mouse;
extends 'App::GitGot::Command';
use 5.010;

has session => (
    traits        => [qw(Getopt)],
    isa           => 'Bool',
    is            => 'ro',
    cmd_aliases   => 's',
    documentation => 'use tmux-sessions',
);

sub command_names { qw/ mux tmux / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  unless ( $self->active_repos and $self->active_repos == 1 ) {
    say STDERR 'ERROR: You need to select a single repo';
    exit(1);
  }

  my( $repo ) = $self->active_repos;

  my $target = $self->session ? 'session' : 'window';

  # is it already opened?
  my %windows = reverse map { /^(\d+):::(\S+)/ }
    split "\n", `tmux list-$target -F"#I:::#W"`;

  if( my $window = $windows{$repo->name} ) {
    if ($self->session) {
        exec 'tmux', 'switch-client', '-t' => $window;
    } else {
        exec 'tmux', 'select-window', '-t' => $window;
    }
  }

  chdir $repo->path;

  if ($self->session) {
    delete local $ENV{TMUX};
    system 'tmux', 'new-session', '-d', '-s', $repo->name;
    exec 'tmux', 'switch-client', '-t' => $repo->name;
  } else {
    exec 'tmux', 'new-window', '-n', $repo->name;
  }

}

__PACKAGE__->meta->make_immutable;
1;
