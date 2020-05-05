package App::GitGot::Command::list;

# ABSTRACT: list managed repositories
use 5.014;

use Class::Load       'try_load_class';

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ list ls / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'json|j' => 'stream output as JSON' ] ,
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  if ( $self->opt->json ) {
    try_load_class( 'JSON::MaybeXS' )
      or die "json serializing requires the module 'JSON::MaybeXS' to be installed\n";

    my @data = map { {%$_}  } $self->active_repos;

    say JSON::MaybeXS->new(pretty => 1)->encode( \@data );
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

1;

## FIXME docs
