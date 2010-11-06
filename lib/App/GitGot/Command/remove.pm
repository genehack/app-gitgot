package App::GitGot::Command::remove;
# ABSTRACT: remove a managed repository from your config

use Moose;
extends 'App::GitGot::BaseCommand';
use 5.010;

use List::MoreUtils qw/ any /;

has 'force' => (
  is          => 'rw',
  isa         => 'Bool',
  cmd_aliases => 'f',
  traits      => [qw/ Getopt /],
);

sub command_names { qw/ remove rm / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  unless ( @$args and $self->active_repos ) {
    say "You need to select one or more repos to remove";
    exit;
  }

  my @new_repo_list;

 REPO: for my $repo ( $self->all_repos ) {
    my $number = $repo->number;

    if ( any { $number == $_->number } $self->active_repos ) {
      my $name = $repo->name;

      if ( $self->force or $self->prompt_yn( "got rm: remove '$name'?" )) {
        say "Removed repo '$name'" if $self->verbose;
        next REPO;
      }
    }
    push @new_repo_list , $repo;
  }

  $self->full_repo_list( \@new_repo_list );
  $self->write_config();
}

1;
