package App::GitGot::Command::mux;

# ABSTRACT: open a tmux window for a selected project
use 5.014;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ mux tmux / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'dirty|D'   => 'open session or window for all dirty repos' ] ,
    [ 'session|s' => 'use tmux-sessions (default: tmux windows)' ] ,
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  my @repos = $self->opt->dirty ? $self->_get_dirty_repos() : $self->active_repos();

  my $target = $self->opt->session ? 'session' : 'window';

 REPO: foreach my $repo ( @repos ) {
    # is it already opened?
    my %windows = reverse map { /^(\d+):::(\S+)/ }
      split "\n", `tmux list-$target -F"#I:::#W"`;

    if( my $window = $windows{$repo->name} ) {
      if ($self->opt->session) {
        system 'tmux', 'switch-client', '-t' => $window;
      }
      else {
        system 'tmux', 'select-window', '-t' => $window;
      }
      next REPO;
    }

    chdir $repo->path;

    if ($self->opt->session) {
      delete local $ENV{TMUX};
      system 'tmux', 'new-session', '-d', '-s', $repo->name;
      system 'tmux', 'switch-client', '-t' => $repo->name;}
    else {
      system 'tmux', 'new-window', '-n', $repo->name;
    }
  }
}

sub _get_dirty_repos {
  my $self = shift;

  my @dirty_repos;
  foreach my $repo ( @{ $self->full_repo_list } ) {
    my $status = $repo->status();

    unless ( ref( $status )) {
      die "You need at least Git version 1.7 to use the --dirty flag.\n";
    }

    push @dirty_repos , $repo
      if $status->is_dirty;
  }

  return @dirty_repos;
}

1;

## FIXME docs
