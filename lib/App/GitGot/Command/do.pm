package App::GitGot::Command::do;

# ABSTRACT: run command in many repositories
use 5.010;
use Mouse;
extends 'App::GitGot::Command';
use namespace::autoclean;

use Capture::Tiny qw/ capture_stdout /;
use File::chdir;

has command => (
  is            => 'ro',
  isa           => 'Str',
  required      => 1,
  traits        => [qw/ Getopt /],
  documentation => 'command to execute in the different repos',
  cmd_aliases   => 'e',
);

has with_repo => (
  is            => 'ro',
  isa           => 'Bool',
  default       => 0,
  traits        => [qw/ Getopt /],
  documentation => 'prepend all output lines with the repo name',
);

sub command_names { qw/ do / }

sub _execute {
  my $self = shift;

  for my $repo ( $self->active_repos ) {
    $self->_run_in_repo( $repo => $self->command );
  }
}

sub _run_in_repo {
  my( $self, $repo, $cmd ) = @_;

  if ( not -d $repo->path ) {
    printf "repo %s: no repository found at path '%s'\n",
      $repo->label, $repo->path;
    return;
  }

  say "\n## repo ", $repo->label, "\n" unless $self->with_repo;

  my $prefix = $self->with_repo ? $repo->label . ': ' : '';

  say $prefix, $_ for split "\n", capture_stdout {
    $CWD = $repo->path;
    system $cmd;
  };
}

__PACKAGE__->meta->make_immutable;
1;
