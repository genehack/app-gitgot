package App::GitGot::Command::add;

# ABSTRACT: add a new repo to your config
use 5.014;

use Class::Load              qw/ try_load_class /;
use Config::INI::Reader;
use Cwd;
use IO::Prompt::Simple;
use List::AllUtils           qw/ any pairmap /;
use Path::Tiny;
use PerlX::Maybe;
use Term::ReadLine;
use Types::Standard -types;

use App::GitGot -command;
use App::GitGot::Repo::Git;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'defaults|D' => 'FIXME' => { default => 0 } ] ,
    [ 'origin|o=s' => 'FIXME' => { default => 'origin' } ] ,
    [ 'recursive'  => 'search all sub-directories for repositories' => { default => 0 } ],
  );
}

sub _execute {
  my ( $self, $opt, $args ) = @_;

  my @dirs = @$args;
  push @dirs, '.' unless @dirs; # default dir is this one

  if( $self->opt->recursive ) {      # hunt for repos
    try_load_class( 'Path::Iterator::Rule' )
      or die "--recursive requires module 'Path::Iterator::Rule' to be installed\n";

    Path::Iterator::Rule->add_helper(
      is_git => sub {
        return sub {
          my $item = shift;
          return -d "$item/.git";
        }
      }
    );

    @dirs = Path::Iterator::Rule->new->dir->is_git->all(@dirs);
  }

  $self->_process_dir($_) for map { path($_)->absolute } @dirs;
}

sub _build_new_entry_from_user_input {
  my( $self, $path ) = @_;

  unless ( -e "$path/.git" ) {
    say STDERR "ERROR: Non-git repos not supported at this time.";
    exit(1);
  }

  my( $repo, $type ) = $self->_init_for_git( $path );

  # if 'defaults' option is true, tell IO::Prompt::Simple to use default choices
  $ENV{PERL_IOPS_USE_DEFAULT} = $self->opt->defaults;

  return unless prompt( "\nAdd repository at '$path'? ", { yn => 1, default => 'y' } );

  my $name = prompt( 'Name? ', lc path( $path )->basename );

  my $remote;
  if ( 1 == scalar keys %$repo ) { # one remote? No choice
    ($remote) = values %$repo;
  }
  else {
    $remote = prompt( 'Tracking remote? ', {
      anyone  => $repo,
      verbose => 1,
      maybe default => ( $repo->{$self->opt->origin} && $self->opt->origin ),
    });
  }

  return App::GitGot::Repo::Git->new({ entry => {
    type => $type,
    path => "$path",            # Path::Tiny to string coercion
    name => $name,
    repo => $remote,
    maybe tags => ( join ' ', prompt( 'Tags? ', join ' ', @{$self->tags||[]} )),
  }});
}

sub _init_for_git {
  my( $self, $path ) = @_;

  ### FIXME probably should have some error handling here...
  my $cfg = Config::INI::Reader->read_file("$path/.git/config");

  my %remotes = pairmap { $a =~ /remote "(.*?)"/ ? ( $1 => $b->{url} ) : () } %$cfg;

  return ( \%remotes, 'git' );
}

sub _process_dir {
  my( $self, $dir ) = @_;

  # first thing, do we already "got" it?
  return warn "Repository at '$dir' already registered with Got, skipping\n"
    if any { $_ eq $dir } map { $_->path } $self->all_repos;

  $self->add_repo(
    $self->_build_new_entry_from_user_input($dir)
  );

  $self->write_config;
}

1;

__END__

=head1 SYNOPSIS

    # add repository of current directory
    $ got add

    # add repository of multiple directories,
    # with default tags
    $ got add -t bar-things -t moosey Moo-bar Moose-bar

    # recursively find repositories,
    # auto-configure with the defaults
    # with given tag
    $ got add --recursive --tag mine .

=cut
