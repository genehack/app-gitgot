package App::GitGot::Command::list;
# ABSTRACT: list managed repositories

use Moose;
extends 'App::GitGot::Command';
use 5.010;

has 'by_path' => (
  is          => 'rw' ,
  isa         => 'Bool' ,
  cmd_aliases => 'p',
  traits      => [qw/ Getopt /],
);

sub command_names { qw/ list ls / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  my $max_len = $self->by_path ? $self->max_length_of_an_active_repo_path
    : $self->max_length_of_an_active_repo_name;

  $self->resort_repos_by_path if ( $self->by_path );

  for my $repo ( $self->active_repos ) {
    my $repo_label = $self->by_path ? $repo->path : $repo->name;

    my $repo_remote = ( $repo->repo and -d $repo->path ) ? $repo->repo
      : ( $repo->repo ) ? $repo->repo . ' (Not checked out)'
        : ( -d $repo->path ) ? 'NO REMOTE'
          : 'ERROR: No remote and no repo?!';

    my $msg = sprintf "%-${max_len}s  %-4s  %s\n",
      $repo_label, $repo->type, $repo_remote;

    printf "%3d) ", $repo->number;

    if ( $self->quiet ) { say $repo_label }
    elsif ( $self->verbose ) {
      printf "$msg    tags: %s\n" , $repo->tags;
    }
    else { print $msg}
  }
}

1;
