package App::GitGot::Command::move;

# ABSTRACT: move repo to new location
use 5.014;

use Cwd;
use File::Copy::Recursive qw/ dirmove /;
use Path::Tiny;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ move mv / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'destination=s' => 'FIXME' => { required => 1 } ] ,
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  my @repos = $self->active_repos;

  my $dest = $self->opt->destination;

  path($dest)->mkpath if @repos > 1;

  for my $repo ( @repos ) {
    my $target_dir = -d $dest
      ? path($dest)->child( path($repo->path)->basename )
      : $dest;

    dirmove( $repo->path => $target_dir )
      or die "couldn't move ", $repo->name, " to '$target_dir': $!";

    $repo->{path} = "$target_dir";
    $self->write_config;

    say sprintf '%s moved to %s', $repo->name, $target_dir;
  }
}

1;

## FIXME docs
