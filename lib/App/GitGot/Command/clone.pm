package App::GitGot::Command::clone;
# ABSTRACT: clone a remote repo and add it to your config

use Moose;
extends 'App::GitGot::Command';
use 5.010;

use Cwd;
use File::Basename;
use File::Spec;
use Term::ReadLine;

has 'defaults' => (
  is          => 'rw',
  isa         => 'Bool',
  cmd_aliases => 'D',
  traits      => [qw/ Getopt /],
);

sub _execute {
  my ( $self, $opt, $args ) = @_;
  my ( $repo , $path ) = @$args;

  $repo // die "Need the URL to clone!";

  my $cwd = getcwd
    or die "ERROR: Couldn't determine path";

  my $name = basename $repo;
  $name =~ s/.git$//;

  $path //= "$cwd/$name";
  $path = File::Spec->rel2abs( $path );

  my $tags;

  unless ( $self->defaults ) {
    my $term = Term::ReadLine->new('gitgot');
    $name = $term->readline( 'Name: ', $name );
    $path = $term->readline( 'Path: ', $path );
    $tags = $term->readline( 'Tags: ', $tags );
  }

  my $new_entry = App::GitGot::Repo->new({ entry => {
    repo => $repo,
    name => $name,
    type => 'git',
    path => $path,
  }});
  $new_entry->{tags} = $tags if $tags;

  $new_entry->clone( $repo , $path );

  $self->add_repo( $new_entry );
  $self->write_config;
}

1;
