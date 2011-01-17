package App::GitGot::Repo;
use Moose;
use 5.010;

use namespace::autoclean;
use Git::Wrapper;
use Try::Tiny;

has 'label' => (
  is       => 'ro' ,
  isa      => 'Str' ,
);

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

has '_wrapper' => (
  is         => 'ro' ,
  isa        => 'Git::Wrapper' ,
  lazy_build => 1 ,
  handles    => [ qw/
                      cherry
                      clone
                      config
                      pull
                      remote
                      status
                      symbolic_ref
                    / ] ,
);

sub _build__wrapper {
  my $self = shift;

  return Git::Wrapper->new( $self->path )
    or die "Can't make Git::Wrapper";
}

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

  my $return = {
    number => $count ,
    name   => $entry->{name} ,
    path   => $entry->{path} ,
    repo   => $repo ,
    type   => $entry->{type} ,
    tags   => $entry->{tags} ,
  };

  $return->{label} = $args->{label} if $args->{label};

  return $return;
}

sub current_branch {
  my $self = shift;

  my $branch;

  try {
    my( $branch ) = $self->symbolic_ref( 'HEAD' );
    $branch =~ s|^refs/heads/||;
  }
    catch {
      die $_ unless $_ && $_->isa('Git::Wrapper::Exception')
        && $_->error eq "fatal: ref HEAD is not a symbolic ref\n"
      };

  return $branch;
}

sub current_remote_branch {
  my( $self ) = shift;

  my $remote;

  if ( my $branch = $self->current_branch ) {
    try {
      ( $remote ) = $self->config( "branch.$branch.remote" );
    }
      catch {
        ## not the most informative return....
        return 0 if $_ && $_->isa('Git::Wrapper::Exception') && $_->{status} eq '1';
      };
  }

  return $remote;
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
