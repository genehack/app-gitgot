package App::GitGot::Command::add;
# ABSTRACT: add a new repo to your config

use Mouse;
extends 'App::GitGot::Command';
use 5.010;

use App::GitGot::Repo::Git;
use Config::INI::Reader;
use Cwd;
use File::Basename;
use File::chdir;
use Term::ReadLine;
use IO::Prompt::Simple;
use PerlX::Maybe;
use Path::Tiny;
use List::AllUtils qw/any pairmap/;
use Class::Load qw/ try_load_class /;

has 'defaults' => (
  is          => 'rw',
  isa         => 'Bool',
  cmd_aliases => 'D',
  traits      => [qw/ Getopt /],
);

has 'origin' => (
  is          => 'rw',
  isa         => 'Str',
  cmd_aliases => 'o',
  default     => 'origin',
  traits      => [qw/ Getopt /],
);

has recursive => (
  traits => [qw/ Getopt /],
   is => 'ro',
   isa => 'Bool',
   default => 0,
   documentation => 'search all sub-directories for repositories',
);

sub _execute {
  my ( $self, $opt, $args ) = @_;

  my @dirs = @$args;
  push @dirs, '.' unless @dirs;  # default dir is this one

  if( $self->recursive ) {
      # hunt for repos

      try_load_class( 'Path::Iterator::Rule' )
        or die "feature requires module 'Path::Iterator::Rule' to be installed\n";

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

  $self->process_dir($_) for map { path($_)->absolute } @dirs;
}

sub process_dir {
    my( $self, $dir ) = @_;

    # first thing, do we already "got" it?
    return warn "Repository at '$dir' already registered with Got, skipping\n"
        if any { $_ eq $dir }  map { $_->path } $self->all_repos;

    local $CWD = $dir;

    $self->add_repo( 
        $self->_build_new_entry_from_user_input
    );

    $self->write_config;
}

sub _build_new_entry_from_user_input {
  my ($self) = @_;

  my ( $repo, $type );

  if ( -e '.git' ) {
    ( $repo, $type ) = $self->_init_for_git;
  }
  else {
    say STDERR "ERROR: Non-git repos not supported at this time.";
    exit(1);
  }

  my $name = lc basename getcwd;

  $ENV{PERL_IOPS_USE_DEFAULT} = $self->defaults;

  my $path = getcwd;

  return unless prompt "\nadd repository at '$path'?", { yn => 1, default => 'y' };

  $name = prompt( 'Name', $name );

  my $remote;

  if ( 1 == keys %$repo ) {
    # one remote? No choice
    ($remote) = values %$repo;
  }
  else {
    $remote = prompt( 'tracking remote', { 
            anyone => $repo, 
            verbose => 1,
            maybe default => $repo->{$self->origin} && $self->origin,
        });
  }

  return App::GitGot::Repo::Git->new({ entry => {
    type => $type,
    path => $path,
    name => $name,
    repo => $remote,
    maybe tags => join ' ', prompt( 'Tags', join ' ', @{$self->tags||[]} ),
  }});
}

sub _check_for_dupe_entries {
  my ( $self, $new_entry ) = @_;

REPO: foreach my $entry ( $self->all_repos ) {
    foreach (qw/ name repo type path /) {
      if ( $new_entry->$_ ) {
        next REPO unless $entry->$_ and $entry->$_ eq $new_entry->$_;
      }
    }
    say STDERR
"ERROR: Not adding entry for '$entry->{name}'; exact duplicate already exists.";
    exit(1);
  }
}

sub _init_for_git {
  my $self = shift;

  my $cfg = Config::INI::Reader->read_file('.git/config');

  my %remotes = pairmap { $a =~ /remote "(.*?)"/ ? ( $1 => $b->{url} ) : () } %$cfg;

  return ( \%remotes, 'git' );
}

__PACKAGE__->meta->make_immutable;
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
