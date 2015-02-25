package App::GitGot::Command::move;

# ABSTRACT: move a repo in a new directory
use Mouse;
extends 'App::GitGot::Command';
use strict;
use warnings;
use 5.010;
use namespace::autoclean;

use Cwd;
use File::Copy::Recursive qw/ dirmove /;
use Path::Class;

sub command_names { qw/ move mv / }

has destination => (
  is          => 'ro',
  isa         => 'Str',
  required    => 1,
  traits      => [qw/ Getopt /],
);

sub _execute {
  my( $self, $opt, $args ) = @_;

  my @repos = $self->active_repos;

  dir($self->destination)->mkpath if @repos > 1;

  for my $repo ( @repos ) {
    my $target_dir = -d $self->destination
      ? dir($self->destination)->subdir( dir($repo->path)->basename )
      : $self->destination;

    dirmove( $repo->path => $target_dir )
      or die "couldn't move ", $repo->name, " to '$target_dir': $!";

    $repo->{path} = "$target_dir";
    $self->write_config;

    say sprintf '%s moved to %s', $repo->name, $target_dir;
  }

}

__PACKAGE__->meta->make_immutable;
1;
