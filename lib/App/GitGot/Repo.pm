package App::GitGot::Repo;

# ABSTRACT: Base repository objects
use 5.014;

use List::AllUtils qw/ uniq /;
use Types::Standard -types;

use App::GitGot::Types;

use Moo;
use namespace::autoclean;

=attr label

Optional label for the repo.

=cut

has label => (
  is  => 'ro' ,
  isa => Str ,
);

=attr name

The name of the repo.

=cut

has name => (
  is       => 'ro',
  isa      => Str,
  required => 1 ,
);

=attr number

The number of the repo.

=cut

has number => (
  is       => 'ro',
  isa      => Int,
  required => 1 ,
);

=attr path

The path to the repo.

=cut

has path => (
  is       => 'ro',
  isa      => Str,
  required => 1 ,
  coerce   => sub { $_[0]->isa('Path::Tiny') ? "$_[0]" : $_[0] } ,
);

=attr repo

=cut

has repo => (
  is  => 'ro',
  isa => Str,
);

=attr tags

Space-separated list of tags for the repo

=cut

has tags => (
  is  => 'rw',
  isa => Str,
);

=attr type

The type of the repo (git, svn, etc.).

=cut

has type => (
  is       => 'ro',
  isa      => Str,
  required => 1 ,
);

sub BUILDARGS {
  my( $class , $args ) = @_;

  my $count = $args->{count} || 0;

  die "Must provide entry" unless
    my $entry = $args->{entry};

  my $repo = $entry->{repo} //= '';

  if ( ! defined $entry->{name} ) {
    ### FIXME this is unnecessarily Git-specific
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

=method add_tags

Given a list of tags, add them to the current repo object.

=cut

sub add_tags {
  my( $self, @tags ) = @_;

  $self->tags( join ' ', uniq sort @tags, split ' ', $self->tags );
}

=method in_writable_format

Returns a serialized representation of the repository for writing out in a
config file.

=cut

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

=method remove_tags

Given a list of tags, remove them from the current repo object.

Passing a tag that is not on the current repo object will silently no-op.

=cut

sub remove_tags {
  my( $self, @tags ) = @_;

  my %verboten = map { $_ => 1 } @tags;

  $self->tags( join ' ', grep { !$verboten{$_} } split ' ', $self->tags );
}

=for Pod::Coverage BUILDARGS

=cut

1;
