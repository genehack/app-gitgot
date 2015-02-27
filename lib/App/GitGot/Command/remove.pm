package App::GitGot::Command::remove;

# ABSTRACT: remove a managed repository from your config
use Mouse;
extends 'App::GitGot::Command';
use strict;
use warnings;
use 5.010;
use namespace::autoclean;

use List::MoreUtils qw/ any /;

has force => (
  is     => 'rw',
  isa    => 'Bool',
  traits => [qw/ Getopt /],
);

sub command_names { qw/ remove rm / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  unless ( $self->active_repos and @$args or $self->tags) {
    say STDERR "ERROR: You need to select one or more repos to remove";
    exit(1);
  }

  my @new_repo_list;

 REPO: for my $repo ( $self->all_repos ) {
    my $number = $repo->number;

    if ( any { $number == $_->number } $self->active_repos ) {
      my $name = $repo->label;

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

__PACKAGE__->meta->make_immutable;
1;
