package App::GitGot::Command::list;
# ABSTRACT: list managed repositories

use Mouse;
extends 'App::GitGot::Command';
use 5.010;

use Class::Load       'try_load_class';

sub command_names { qw/ list ls / }

has 'json' => (
  is            => 'ro',
  isa           => 'Bool',
  cmd_aliases   => 'j',
  traits        => [qw/ Getopt /],
  documentation => 'stream output as json',
);

sub _execute {
  my( $self, $opt, $args ) = @_;

  if ( $self->json ) {
    try_load_class( 'JSON' )
      or die "json serializing requires the module 'JSON' to be installed\n";

    my @data = map { {%$_}  } $self->active_repos;

    say JSON::to_json( \@data, { pretty => 1 } );
    return;
  }

  for my $repo ( $self->active_repos ) {
    my $repo_remote = ( $repo->repo and -d $repo->path ) ? $repo->repo
      : ( $repo->repo )    ? $repo->repo . ' (Not checked out)'
      : ( -d $repo->path ) ? 'NO REMOTE'
      : 'ERROR: No remote and no repo?!';

    printf "%3d) ", $repo->number;

    if ( $self->quiet ) { say $repo->label }
    else {
      my $max_len = $self->max_length_of_an_active_repo_label;

      printf "%-${max_len}s  %-4s  %s\n", $repo->label, $repo->type, $repo_remote;

      if ( $self->verbose and $repo->tags ) {
        printf "    tags: %s\n" , $repo->tags
      }
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;
