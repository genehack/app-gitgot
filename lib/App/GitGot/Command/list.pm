package App::GitGot::Command::list;
# ABSTRACT: list managed repositories

use Moose;
extends 'App::GitGot::Command';
use 5.010;

sub command_names { qw/ list ls / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_name;

  for my $repo ( $self->active_repos ) {
    my $repo_name;

    if ( $repo->repo and -d $repo->path ) { $repo_name = $repo->repo }
    elsif ( $repo->repo ) { $repo_name = $repo->repo . ' (Not checked out)' }
    elsif ( -d $repo->path ) { $repo_name = 'NO REMOTE' }
    else { $repo_name = 'ERROR: No remote and no repo?!' }

    my $msg = sprintf "%-${max_len}s  %-4s  %s\n",
      $repo->name, $repo->type, $repo_name;

    printf "%3d) ", $repo->number;

    if ( $self->quiet ) { say $repo->name }
    elsif ( $self->verbose ) {
      printf "$msg    tags: %s\n" , $repo->tags;
    }
    else { print $msg}
  }
}

1;
