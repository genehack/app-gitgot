package App::GitGot::Command::tag;

# ABSTRACT: list/add/remove tags for the current repository
use Mouse;
extends 'App::GitGot::Command';
use 5.010;
use namespace::autoclean;

sub command_names { qw/ tag / }

has add => (
  is          => 'ro',
  isa         => 'Bool',
  cmd_aliases => 'a',
  default => 0,
  documentation => 'assign tags to the current repository',
  traits      => [qw/ Getopt /],
);

has all => (
  is          => 'ro',
  isa         => 'Bool',
  cmd_aliases => 'A',
  default => 0,
  documentation => 'print out tags of all repositories',
  traits      => [qw/ Getopt /],
);

has remove => (
  is          => 'ro',
  isa         => 'Bool',
  cmd_aliases => 'rm',
  default => 0,
  documentation => 'remove tags from the current repository',
  traits      => [qw/ Getopt /],
);

sub _execute {
  my( $self, $opt, $args ) = @_;

  return say "not in a got-monitored repo" unless $self->local_repo;

  return say "can't --add and --remove at the same time"
    if $self->add and $self->remove;

  if( $self->add ) {
    return $self->_add_tags( @$args );
  }

  if( $self->remove ) {
    return $self->_remove_tags( @$args );
  }

  $self->_print_tags;
}

sub _add_tags {
  my( $self, @tags ) = @_;

  $self->local_repo->add_tags( @tags );

  $self->write_config;

  say "tags added";
}

sub _print_tags {
  my $self = shift;

  my %tags = map { $_ => 1 } split ' ', $self->local_repo->tags;

  if ( $self->all ) {
    $tags{$_} ||= 0 for map { split ' ', $_->tags } $self->all_repos
  }

  for my $t ( sort keys %tags ) {
    say $t, ' *' x ( $self->all and $tags{$t} );
  }

}

sub _remove_tags {
  my( $self, @tags ) = @_;

  $self->local_repo->remove_tags(@tags);

  $self->write_config;

  say "tags removed";
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

    $ got tag
    dancer
    perl
    private

    $ got tag --all
    dancer *
    perl *
    private *
    other

    $ got tag --add new_tag another_new_tag

    $ got tag --rm new_tag

=head1 DESCRIPTION

C<got tag> manages tags for the current repository.

=head1 OPTIONS

=head2 --all

Shows all tags. Tags that are associated with the current repository are
marked with an '*'.

=head2 --add tag1 tag2 ...

Adds tags to the current repository.

=head2 --remove tag1 tag2 ...

Removes tags from the current repository.
