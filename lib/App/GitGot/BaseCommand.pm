package App::GitGot::BaseCommand;
use Moose;
extends 'MooseX::App::Cmd::Command';
# ABSTRACT: Base class for App::GitGot commands
use 5.010;

use Storable qw/ dclone /;
use Try::Tiny;
use YAML qw/ DumpFile LoadFile /;
use namespace::autoclean;

has 'all' => (
  is            => 'rw',
  isa           => 'Bool',
  documentation => 'use all available repositories' ,
  cmd_aliases   => 'a',
  traits        => [qw/ Getopt /],
);

has 'config' => (
  is     => 'rw',
  isa    => 'ArrayRef[App::GitGot::Repo]' ,
  traits => [qw/ NoGetopt /],
);

has 'configfile' => (
  is            => 'rw',
  isa           => 'Str',
  documentation => 'path to config file',
  default       => "$ENV{HOME}/.gitgot",
  traits        => [qw/ Getopt /],
  required      => 1,
);

has 'quiet' => (
  is            => 'rw',
  isa           => 'Bool',
  documentation => 'keep it down',
  cmd_aliases   => 'q',
  traits        => [qw/ Getopt /],
);

has 'repos' => (
  is     => 'rw',
  isa    => 'ArrayRef[App::GitGot::Repo]',
  traits => [qw/ NoGetopt /],
);

has 'tags' => (
  is            => 'rw',
  isa           => 'ArrayRef[Str]',
  documentation => 'select repositories tagged with these words' ,
  cmd_aliases   => 't',
  traits        => [qw/ Getopt /],
);

has 'verbose' => (
  is            => 'rw',
  isa           => 'Bool',
  documentation => 'bring th\' noise',
  cmd_aliases   => 'v',
  traits        => [qw/ Getopt /],
);

sub build_repo_list_from_args {
  my ( $self, $args ) = @_;

  my $list = _expand_arg_list( $args );

  my @repos;
 REPO: foreach my $repo ( @{ $self->config } ) {
    my $number = $repo->number;
    my $name   = $repo->name;

    if ( grep { $_ eq $number or $_ eq $name } @$list ) {
      push @repos, $repo;
      next REPO;
    }

    if ( $self->tags ) {
      foreach my $tag ( @{ $self->tags } ) {
        if ( grep { $repo->tags =~ /\b$_\b/ } $tag ) {
          push @repos, $repo;
          next REPO;
        }
      }
    }
  }
  return \@repos;
}

sub load_config {
  my $self = shift;

  my $config = $self->read_config;
  $self->parse_config( $config );
}

sub parse_config {
  my( $self , $config ) = @_;

  my $repo_count = 1;

  my @parsed_config;

  foreach my $entry ( sort { $a->{name} cmp $b->{name} } @$config ) {

    # a completely empty entry is okay (this will happen when there's no
    # config at all...)
    keys %$entry or next;

    push @parsed_config , App::GitGot::Repo->new({
      entry => $entry ,
      count => $repo_count++ ,
    });
  }

  $self->config( \@parsed_config );
}

sub read_config {
  my $self = shift;

  my $config;

  if ( -e $self->configfile ) {
    try { $config = LoadFile( $self->configfile ) }
    catch { say "Failed to parse config..."; exit };
  }

  # if the config is completely empty, bootstrap _something_
  return $config // [ {} ];
}

sub validate_args {
  my ( $self, $opt, $args ) = @_;

  $self->load_config;

  return $self->repos( $self->config )
    if ( $self->all );

  my $repo_list =
    ( $self->tags || @$args )
    ? $self->build_repo_list_from_args($args)
    : $self->config;

  return $self->repos($repo_list);
}

sub write_config {
  my ($self) = @_;

  my $config_to_write = [];

  foreach my $repo_obj( @{ $self->config } ) {
    push @$config_to_write , $repo_obj->in_writable_format;
  }

  DumpFile( $self->configfile, $config_to_write );
}

sub _expand_arg_list {
  my $args = shift;

  return [
    map {
      s!/$!!;
      if (/^(\d+)-(\d+)?$/) {
        ( $1 .. $2 );
      } else {
        ($_);
      }
    } @$args
  ];
}



package App::GitGot::Repo;
use Moose;

use 5.010;
use namespace::autoclean;

has 'name' => (
  is          => 'ro',
  isa         => 'Str',
  required    => 1 ,
);

has 'number' => (
  is          => 'ro',
  isa         => 'Int',
  required    => 1 ,
);

has 'path' => (
  is          => 'ro',
  isa         => 'Str',
  required    => 1 ,
);

has 'repo' => (
  is          => 'ro',
  isa         => 'Str',
);

has 'tags' => (
  is          => 'ro',
  isa         => 'Str',
);

has 'type' => (
  is          => 'ro',
  isa         => 'Str',
  required    => 1 ,
);

sub BUILDARGS {
  my( $class , $args ) = @_;

  my $count = $args->{count} || 0;
  my $entry = $args->{entry};

  my $repo = $entry->{repo} //= '';

  $entry->{type} //= '';
  given( $repo ) {
    when( /\.git$/ ) { $entry->{type} = 'git' }
    when( /svn/    ) { $entry->{type} = 'svn' }
  }

  if ( ! defined $entry->{name} ) {
    $entry->{name} = ( $repo =~ m|([^/]+).git$| ) ? $1 : '';
  }

  $entry->{tags} //= '';

  return {
    number => $count ,
    name   => $entry->{name} ,
    path   => $entry->{path} ,
    repo   => $repo ,
    type   => $entry->{type} ,
    tags   => $entry->{tags} ,
  };
}

sub in_writable_format {
  my $self = shift;

  my $writeable = {
    name => $self->name ,
    path => $self->path ,
  };

  foreach ( qw/ repo tags type /) {
    $writeable->{$_} = $self->$_ if $self->$_;
  }

  return $writeable;
}

1;
