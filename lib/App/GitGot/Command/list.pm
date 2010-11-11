package App::GitGot::Command::list;
# ABSTRACT: list managed repositories

use Moose;
extends 'App::GitGot::Command';
use 5.010;

sub command_names { qw/ list ls / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

  for my $repo ( $self->active_repos ) {
    my $repo_remote = ( $repo->repo and -d $repo->path ) ? $repo->repo
      : ( $repo->repo ) ? $repo->repo . ' (Not checked out)'
        : ( -d $repo->path ) ? 'NO REMOTE'
          : 'ERROR: No remote and no repo?!';

    my $msg = sprintf "%-${max_len}s  %-4s  %s\n",
      $repo->label, $repo->type, $repo_remote;

    printf "%3d) ", $repo->number;

    if ( $self->quiet ) { say $repo->label }
    elsif ( $self->verbose ) {
      printf "$msg    tags: %s\n" , $repo->tags;
    }
    else { print $msg}
  }
}

1;
