package App::GitGot::Command;

# ABSTRACT: Base class for App::GitGot commands
use 5.014;

use App::Cmd::Setup -command;
use Cwd;
use File::HomeDir::Tiny ();
use List::Util              qw/ max first /;
use Path::Tiny;
use Try::Tiny;
use Types::Standard -types;
use YAML                    qw/ DumpFile LoadFile /;

use App::GitGot::Repo::Git;
use App::GitGot::Repositories;
use App::GitGot::Types -all;

use Moo;
use MooX::HandlesVia;
use namespace::autoclean;

sub opt_spec {
  my( $class , $app ) = @_;

  return (
    [ 'all|a'            => 'use all available repositories' ] ,
    [ 'by_path|p'        => 'if set, output will be sorted by repo path (default: sort by repo name)' ] ,
    [ 'color_scheme|c=s' => 'name of color scheme to use' => { default => 'dark' } ] ,
    [ 'configfile|f=s'   => 'path to config file' => { default => path( File::HomeDir::Tiny::home() , '.gitgot') , required => 1 } ] ,
    [ 'no_color|C'       => 'do not use colored output' => { default => 0 } ] ,
    [ 'quiet|q'          => 'keep it down' ] ,
    [ 'skip_tags|T=s@'   => 'select repositories not tagged with these words' ] ,
    [ 'tags|t=s@'        => 'select repositories tagged with these words' ] ,
    [ 'verbose|v'        => 'bring th\' noise'] ,
    $class->options($app)
  );
}

sub options {}

has active_repo_list => (
  is          => 'lazy',
  isa         => ArrayRef[GotRepo] ,
  handles_via => 'Array' ,
  handles     => {
    active_repos => 'elements' ,
  } ,
);

sub _build_active_repo_list {
  my ( $self ) = @_;

  return $self->full_repo_list
    if $self->all or ! $self->tags and ! $self->skip_tags and ! @{ $self->args };

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
    push @repos, $repo unless $self->tags or @$list;
  }

  return \@repos;
}

has args => (
  is     => 'rwp' ,
  isa    => ArrayRef ,
);

has full_repo_list => (
  is          => 'lazy',
  isa         => ArrayRef[GotRepo] ,
  writer      => 'set_full_repo_list' ,
  handles_via => 'Array' ,
  handles     => {
    add_repo  => 'push' ,
    all_repos => 'elements' ,
  } ,
);

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

    ### FIXME unnecessarily git specific
    push @parsed_config , App::GitGot::Repo::Git->new({
      label => ( $self->by_path ) ? $entry->{path} : $entry->{name} ,
      entry => $entry ,
      count => $repo_count++ ,
    });
  }

  return \@parsed_config;
}

has opt => (
  is      => 'rwp' ,
  isa     => Object ,
  handles => [ qw/
     all
     by_path
     color_scheme
     configfile
     no_color
     quiet
     skip_tags
     tags
     verbose
   / ]
);

has outputter => (
  is         => 'lazy' ,
  isa        => GotOutputter ,
  handles    => [
    'error' ,
    'warning' ,
    'major_change' ,
    'minor_change' ,
  ] ,
);

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

sub execute {
  my( $self , $opt , $args ) = @_;
  $self->_set_args( $args );
  $self->_set_opt( $opt  );

  # set up colored output if we page thru less
  # also exit pager immediately if <1 page of output
  $ENV{LESS} = 'RFX';

  # don't catch any errors here; if this fails we just output stuff like
  # normal and nobody is the wiser.
  eval 'use IO::Page' if $self->_use_io_page;

  $self->_execute($opt,$args);
}

=method local_repo

Checks to see if $CWD is inside a Git repo managed by Got, and returns the
corresponding L<App::GitGot::Repo> object if it is.

=cut

sub local_repo {
  my $self = shift;

  my $dir = $self->_find_repo_root( getcwd() );

  return first { $_->path eq $dir->absolute } $self->all_repos;
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

=method search_repos

Returns a L<App::GitGot::Repositories> object containing all repos managed by
Got.

=cut

sub search_repos {
  my $self = shift;

  return App::GitGot::Repositories->new(
    repos => [ $self->all_repos ]
  );
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

sub _fetch {
  my( $self , @repos ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( @repos ) {
    next REPO unless $repo->repo;

    my $name = $repo->name;

    my $msg = sprintf "%3d) %-${max_len}s  : ", $repo->number, $repo->label;

    my ( $status, $fxn );

    my $repo_type = $repo->type;

    if ( $repo_type eq 'git' ) { $fxn = '_git_fetch' }
    ### FIXME elsif( $repo_type eq 'svn' ) { $fxn = 'svn_update' }
    else { $status = $self->error("ERROR: repo type '$_' not supported") }

    $status = $self->$fxn($repo) if ($fxn);

    next REPO if $self->quiet and !$status;

    say "$msg$status";
  }
}

sub _find_repo_root {
  my( $self , $path ) = @_;

  my $dir = path( $path );

  # find repo root
  while ( ! grep { -d and $_->basename eq '.git' } $dir->children ) {
    die "$path doesn't seem to be in a git directory\n" if $dir eq $dir->parent;
    $dir = $dir->parent;
  }

  return $dir
}

sub _git_clone_or_callback {
  my( $self , $entry , $callback ) = @_
    or die "Need entry and callback";

  my $msg = '';

  my $path = $entry->path;

  if ( !-d $path ) {
    path($path)->mkpath;

    try {
      $entry->clone( $entry->repo , './' );
      $msg .= $self->major_change('Checked out');
    }
      catch { $msg .= $self->error('ERROR') . "\n$_" };
  }
  elsif ( -d "$path/.git" ) {
    try {
      $msg .= $callback->($msg , $entry);
    }
    catch { $msg .= $self->error('ERROR') . "\n$_" };
  }

  return $msg;

}

sub _git_fetch {
  my ( $self, $entry ) = @_
    or die "Need entry";

  $self->_git_clone_or_callback( $entry ,
    sub {
      my( $msg , $entry ) = @_;

      my @o = $entry->fetch;

      # "git fetch" doesn't output anything to STDOUT only STDERR
      my @err = @{ $entry->_wrapper->ERR };

      # If something was updated then STDERR should contain something
      # similar to:
      #
      #     From git://example.com/link-to-repo
      #         SHA1___..SHA1___  master     -> origin/master
      #
      # So search for /^From / in STDERR to see if anything was outputed
      if ( grep { /^From / } @err ) {
        $msg .= $self->major_change('Updated');
        $msg .= "\n" . join("\n",@err) unless $self->quiet;
      }
      elsif ( scalar @err == 0) {
        # No messages to STDERR means repo was already updated
        $msg .= $self->minor_change('Up to date') unless $self->quiet;
      }
      else {
        # Something else occured (possibly a warning)
        # Print STDERR and move on
        $msg .= $self->warning('Problem during fetch');
        $msg .= "\n" . join("\n",@err) unless $self->quiet;
      }

      return $msg;
    }
  );
}

sub _git_status {
  my ( $self, $entry ) = @_
    or die "Need entry";

  my( $msg , $verbose_msg ) = $self->_run_git_status( $entry );

  $msg .= $self->_run_git_cherry( $entry )
    if $entry->current_remote_branch;
  if ($self->opt->show_branch and defined $entry->current_branch) {
      $msg .= '[' . $entry->current_branch . ']';
  }

  return ( $self->verbose ) ? "$msg$verbose_msg" : $msg;
}

sub _git_update {
  my ( $self, $entry ) = @_
    or die "Need entry";

  $self->_git_clone_or_callback( $entry ,
    sub {
      my( $msg , $entry ) = @_;

      my @o = $entry->pull;
      if ( $o[0] =~ /^Already up.to.date\./ ) {
        $msg .= $self->minor_change('Up to date') unless $self->quiet;
      }
      else {
        $msg .= $self->major_change('Updated');
        $msg .= "\n" . join("\n",@o) unless $self->quiet;
      }

      return $msg;
    }
  );
}

sub _path_is_managed {
  my( $self , $path ) = @_;

  return unless $path;

  my $dir     = $self->_find_repo_root( $path );
  my $max_len = $self->max_length_of_an_active_repo_label;

  for my $repo ( $self->active_repos ) {
    next unless $repo->path eq $dir->absolute;

    my $repo_remote = ( $repo->repo and -d $repo->path ) ? $repo->repo
      : ( $repo->repo )    ? $repo->repo . ' (Not checked out)'
      : ( -d $repo->path ) ? 'NO REMOTE'
      : 'ERROR: No remote and no repo?!';

    printf "%3d) ", $repo->number;

    if ( $self->quiet ) { say $repo->label }
    else {
      printf "%-${max_len}s  %-4s  %s\n",
        $repo->label, $repo->type, $repo_remote;
      if ( $self->verbose ) {
        printf "    tags: %s\n" , $repo->tags if $repo->tags;
      }
    }

    return 1;
  }

  say "repository not in Got list";
  return;
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

=for Pod::Coverage args opt options

=cut

1;
