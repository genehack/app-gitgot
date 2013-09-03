package App::GitGot::Command;
# ABSTRACT: Base class for App::GitGot commands

use Mouse;
extends 'MouseX::App::Cmd::Command';
use 5.010;

use App::GitGot::Repo::Git;
use File::Path 2.08         qw/ make_path /;
use List::Util              qw/ max /;
use Try::Tiny;
use YAML                    qw/ DumpFile LoadFile /;
use namespace::autoclean;

# option attrs
has 'all' => (
  is            => 'rw',
  isa           => 'Bool',
  documentation => 'use all available repositories' ,
  cmd_aliases   => 'a',
  traits        => [qw/ Getopt /],
);

has 'by_path' => (
  is          => 'rw' ,
  isa         => 'Bool' ,
  cmd_aliases => 'p',
  traits      => [qw/ Getopt /],
);

has 'color_scheme' => (
  is            => 'rw',
  isa           => 'Str',
  documentation => 'name of color scheme to use',
  default       => 'dark',
  cmd_aliases   => 'c' ,
  traits        => [qw/ Getopt /],
);

has 'configfile' => (
  is            => 'rw',
  isa           => 'Str',
  documentation => 'path to config file',
  default       => "$ENV{HOME}/.gitgot",
  cmd_aliases   => 'f' ,
  traits        => [qw/ Getopt /],
  required      => 1,
);

has 'no_color' => (
  is            => 'rw',
  isa           => 'Bool',
  documentation => 'do not use colored output',
  default       => 0,
  cmd_aliases   => 'C',
  traits        => [qw/ Getopt /],
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

has 'skip_tags' => (
  is            => 'rw',
  isa           => 'ArrayRef[Str]',
  documentation => 'select repositories not tagged with these words' ,
  cmd_aliases   => 'T',
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
  isa        => 'ArrayRef[App::GitGot::Repo::Git]' ,
  traits     => [qw/ NoGetopt Array /],
  lazy_build => 1 ,
  handles    => {
    active_repos => 'elements' ,
  } ,
);

has 'args' => (
  is     => 'rw' ,
  isa    => 'ArrayRef' ,
  traits => [ qw/ NoGetopt / ] ,
);

has 'full_repo_list' => (
  is         => 'rw',
  isa        => 'ArrayRef[App::GitGot::Repo::Git]' ,
  traits     => [qw/ NoGetopt Array /],
  lazy_build => 1 ,
  handles    => {
    add_repo  => 'push' ,
    all_repos => 'elements' ,
  } ,
);

has 'outputter' => (
  is         => 'ro' ,
  isa        => 'App::GitGot::Outputter' ,
  traits     => [ qw/ NoGetopt / ] ,
  lazy_build => 1 ,
  handles    => [
    'error' ,
    'warning' ,
    'major_change' ,
    'minor_change' ,
  ] ,
);

sub execute {
  my( $self , $opt , $args ) = @_;
  $self->args( $args );

  # set up colored output if we page thru less
  # also exit pager immediately if <1 page of output
  $ENV{LESS} = 'RFX';

  # don't catch any errors here; if this fails we just output stuff like
  # normal and nobody is the wiser.
  eval 'use IO::Page' if $self->_use_io_page;

  $self->_execute($opt,$args);
}

=method max_length_of_an_active_repo_label

Returns the length of the longest name in the active repo list.

=cut

sub max_length_of_an_active_repo_label {
  my( $self ) = @_;

  my $sort_key = $self->by_path ? 'path' : 'name';

  return max ( map { length $_->$sort_key } $self->active_repos);
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
    if $self->all or ! $self->tags and ! $self->no_tags and ! @{ $self->args };

  my $list = _expand_arg_list( $self->args );

  my @repos;
 REPO: foreach my $repo ( $self->all_repos ) {
    if ( grep { $_ eq $repo->number or $_ eq $repo->name } @$list ) {
      push @repos, $repo;
      next REPO;
    }

    if ( $self->skip_tags ) {
      foreach my $tag ( @{ $self->skip_tags } ) {
        next REPO if grep { $repo->tags =~ /\b$_\b/ } $tag;
      }
    }

    if ( $self->tags ) {
      foreach my $tag ( @{ $self->tags } ) {
        if ( grep { $repo->tags =~ /\b$_\b/ } $tag ) {
          push @repos, $repo;
          next REPO;
        }
      }
    }
    push @repos, $repo unless $self->tags;
  }

  return \@repos;
}

sub _build_full_repo_list {
  my $self = shift;

  my $config = _read_config( $self->configfile );

  my $repo_count = 1;

  my $sort_key = $self->by_path ? 'path' : 'name';

  my @parsed_config;

  foreach my $entry ( sort { $a->{$sort_key} cmp $b->{$sort_key} } @$config ) {

    # a completely empty entry is okay (this will happen when there's no
    # config at all...)
    keys %$entry or next;

    push @parsed_config , App::GitGot::Repo::Git->new({
      label => ( $self->by_path ) ? $entry->{path} : $entry->{name} ,
      entry => $entry ,
      count => $repo_count++ ,
    });
  }

  return \@parsed_config;
}

sub _build_outputter {
  my $self = shift;

  my $scheme = $self->color_scheme;

  if ( $scheme =~ /^\+/ ) {
    $scheme =~ s/^\+//;
  }
  else {
    $scheme = "App::GitGot::Outputter::$scheme"
  }

  try {
    eval "use $scheme";
    die $@ if $@;
  }
  catch {
    say "Failed to load color scheme '$scheme'.\nExitting now.\n";
    exit(5);
  };

  return $scheme->new({ no_color => $self->no_color });
}

sub _expand_arg_list {
  my $args = shift;

  ## no critic

  return [
    map {
      s!/$!!;
      if (/^(\d+)-(\d+)?$/) { ( $1 .. $2 ) }
      else { ($_) }
    } @$args
  ];

  ## use critic
}

sub _git_status {
  my ( $self, $entry ) = @_
    or die "Need entry";

  my( $msg , $verbose_msg ) = $self->_run_git_status( $entry );

  $msg .= $self->_run_git_cherry( $entry )
    if $entry->current_remote_branch;

  return ( $self->verbose ) ? "$msg$verbose_msg" : $msg;
}

sub _git_update {
  my ( $self, $entry ) = @_
    or die "Need entry";

  my $msg = '';

  my $path = $entry->path;

  if ( !-d $path ) {
    make_path $path;

    try {
      $entry->clone( $entry->repo , './' );
      $msg .= $self->major_change('Checked out');
    }
    catch { $msg .= $self->error('ERROR') . "\n$_" };
  }
  elsif ( -d "$path/.git" ) {
    try {
      my @o = $entry->pull;
      if ( $o[0] eq 'Already up-to-date.' ) {
        $msg .= $self->minor_change('Up to date') unless $self->quiet;
      }
      else {
        $msg .= $self->major_change('Updated');
        $msg .= "\n" . join("\n",@o) unless $self->quiet;
      }
    }
    catch { $msg .= $self->error('ERROR') . "\n$_" };
  }

  return $msg;
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

sub _run_git_cherry {
  my( $self , $entry ) = @_;

  my $msg = '';

  try {
    if ( $entry->remote ) {
      my $cherry = $entry->cherry;
      if ( $cherry > 0 ) {
        $msg = $self->major_change("Ahead by $cherry");
      }
    }
  }
    catch { $msg = $self->error('ERROR') . "\n$_" };

  return $msg
}

sub _run_git_status {
  my( $self , $entry ) = @_;

  my %types = (
    indexed  => 'Changes to be committed' ,
    changed  => 'Changed but not updated' ,
    unknown  => 'Untracked files' ,
    conflict => 'Files with conflicts' ,
  );

  my( $msg , $verbose_msg ) = ('','');

  try {
    my $status = $entry->status;
    if ( keys %$status ) {
      $msg .= $self->warning('Dirty') . ' ';
    } else {
      $msg .= $self->minor_change('OK ') unless $self->quiet;
    }

    if ( $self->verbose ) {
    TYPE: for my $type ( keys %types ) {
        my @states = $status->get( $type ) or next TYPE;
        $verbose_msg .= "\n** $types{$type}:\n";
        for ( @states ) {
          $verbose_msg .= sprintf '  %-12s %s' , $_->mode , $_->from;
          $verbose_msg .= sprintf ' -> %s' , $_->to if $_->mode eq 'renamed';
          $verbose_msg .= "\n";
        }
      }
      $verbose_msg = "\n$verbose_msg" if $verbose_msg;
    }
  }
    catch { $msg .= $self->error('ERROR') . "\n$_" };

  return( $msg , $verbose_msg );
}

sub _status {
  my( $self , @repos ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( @repos ) {
    my $label = $repo->label;

    my $msg = sprintf "%3d) %-${max_len}s  : ", $repo->number, $label;

    my ( $status, $fxn );

    if ( -d $repo->path ) {
      my $repo_type = $repo->type;
      if ( $repo_type eq 'git' ) { $fxn = '_git_status' }
      ### FIXME elsif( $repo_type eq 'svn' ) { $fxn = 'svn_status' }
      else {  $status = $self->error("ERROR: repo type '$repo_type' not supported") }

      $status = $self->$fxn($repo) if ($fxn);

      next REPO if $self->quiet and !$status;
    }
    elsif ( $repo->repo ) { $status = 'Not checked out' }
    else { $status = $self->error("ERROR: repo '$label' does not exist") }

    say "$msg$status";
  }
}

sub _update {
  my( $self , @repos ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( @repos ) {
    next REPO unless $repo->repo;

    my $name = $repo->name;

    my $msg = sprintf "%3d) %-${max_len}s  : ", $repo->number, $repo->label;

    my ( $status, $fxn );

    my $repo_type = $repo->type;

    if ( $repo_type eq 'git' ) { $fxn = '_git_update' }
    ### FIXME elsif( $repo_type eq 'svn' ) { $fxn = 'svn_update' }
    else { $status = $self->error("ERROR: repo type '$_' not supported") }

    $status = $self->$fxn($repo) if ($fxn);

    next REPO if $self->quiet and !$status;

    say "$msg$status";
  }
}

# override this in commands that shouldn't use IO::Page -- i.e., ones that
# need to do incremental output
sub _use_io_page { 1 }

__PACKAGE__->meta->make_immutable;
1;
