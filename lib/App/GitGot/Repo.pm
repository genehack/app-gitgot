package App::GitGot::Repo;

# ABSTRACT: Base repository objects
use Mouse;
use 5.010;

use List::AllUtils qw/ uniq /;

use namespace::autoclean;

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
  is          => 'rw',
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

  die "Must provide entry" unless
    my $entry = $args->{entry};

  my $repo = $entry->{repo} //= '';

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

sub add_tags {
    my( $self, @tags ) = @_;

    $self->tags( join ' ', uniq sort @tags, split ' ', $self->tags );
}

sub remove_tags {
    my( $self, @tags ) = @_;

    %verboten = map { $_ => 1 } @tags;

    $self->tags( join ' ', grep { !$verboten{$_} } split ' ', $self->tags );
}


__PACKAGE__->meta->make_immutable;
1;
