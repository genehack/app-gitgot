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

  my( @repos ) = $self->active_repos;

  my $target = $self->session ? 'session' : 'window';

  foreach my $repo ( @repos ) {

      # is it already opened?
      my %windows = reverse map { /^(\d+):::(\S+)/ }
        split "\n", `tmux list-$target -F"#I:::#W"`;

      if( my $window = $windows{$repo->name} ) {
          if ($self->session) {
              system 'tmux', 'switch-client', '-t' => $window;
          } else {
              system 'tmux', 'select-window', '-t' => $window;
          }
      }

      chdir $repo->path;

      if ($self->session) {
          delete local $ENV{TMUX};
          system 'tmux', 'new-session', '-d', '-s', $repo->name;
          system 'tmux', 'switch-client', '-t' => $repo->name;
      } else {
          system 'tmux', 'new-window', '-n', $repo->name;
      }
  }
}

__PACKAGE__->meta->make_immutable;
1;
