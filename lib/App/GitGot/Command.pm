package App::GitGot::Command;
# ABSTRACT: Base class for App::GitGot commands

use Moose;
extends 'MooseX::App::Cmd::Command';
use 5.010;

use List::Util qw/ max /;
use Storable qw/ dclone /;
use Try::Tiny;
use YAML qw/ DumpFile LoadFile /;
use namespace::autoclean;

# option attrs
has 'all' => (
  is            => 'rw',
  isa           => 'Bool',
  documentation => 'use all available repositories' ,
  cmd_aliases   => 'a',
  traits        => [qw/ Getopt /],
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

# non-option attrs
has 'active_repo_list' => (
  is         => 'rw',
  isa        => 'ArrayRef[App::GitGot::Repo]' ,
  traits     => [qw/ NoGetopt Array /],
  lazy_build => 1 ,
  handles    => {
    active_repos => 'elements' ,
  } ,
);

has 'args' => (
  is => 'rw' ,
  isa => 'ArrayRef' ,
  traits => [ qw/ NoGetopt / ] ,
);

has 'full_repo_list' => (
  is         => 'rw',
  isa        => 'ArrayRef[App::GitGot::Repo]' ,
  traits     => [qw/ NoGetopt Array /],
  lazy_build => 1 ,
  handles    => {
    add_repo  => 'push' ,
    all_repos => 'elements' ,
  } ,
);

sub execute {
  my( $self , $opt , $args ) = @_;
  $self->args( $args );
  $self->_execute($opt,$args);
}

=method max_length_of_an_active_repo_name

Returns the length of the longest name in the active repo list.

=cut

sub max_length_of_an_active_repo_name {
  my $self = shift;

  return max ( map { length $_->name } $self->active_repos);
}

=method prompt_yn

Takes a message argument and uses it to prompt for a yes/no response.

Response defaults to 'no'.

=cut

sub prompt_yn {
  my( $self , $message ) = @_;
  printf '%s [y/N]: ' , $message;
  chomp( my $response = <STDIN> );
  return lc($response) eq 'y';
}

=method write_config

Dumps configuration out to disk.

=cut

sub write_config {
  my ($self) = @_;

  DumpFile(
    $self->configfile,
    [
      sort { $a->{name} cmp $b->{name} }
      map { $_->in_writable_format } $self->all_repos
    ] ,
  );
}

sub _build_active_repo_list {
  my ( $self ) = @_;

  return $self->full_repo_list
    if $self->all or ! $self->tags and ! @{ $self->args };

  my $list = _expand_arg_list( $self->args );

  my @repos;
 REPO: foreach my $repo ( $self->all_repos ) {
    if ( grep { $_ eq $repo->number or $_ eq $repo->name } @$list ) {
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

sub _build_full_repo_list {
  my $self = shift;

  my $config = _read_config( $self->configfile );

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

  return \@parsed_config;
}

sub _expand_arg_list {
  my $args = shift;

  ## no critic

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

  ## use critic
}

sub _read_config {
  my $file = shift;

  my $config;

  if ( -e $file ) {
    try { $config = LoadFile( $file ) }
      catch { say "Failed to parse config..."; exit };
  }

  # if the config is completely empty, bootstrap _something_
  return $config // [ {} ];
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
