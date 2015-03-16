package App::GitGot::Command::tag;

# ABSTRACT: list/add/remove tags for the current repository
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'add|a' => 'assign tags to the current repository' => { default => 0 } ] ,
    [ 'all|A' => 'print out tags of all repositories' => { default => 0 } ] ,
    [ 'remove|rm' => 'remove tags from the current repository' => { default => 0 } ] ,
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  return say "not in a got-monitored repo" unless $self->local_repo;

  return say "can't --add and --remove at the same time"
    if $self->opt->add and $self->opt->remove;

  if( $self->opt->add ) {
    return $self->_add_tags( @$args );
  }

  if( $self->opt->remove ) {
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

  if ( $self->opt->all ) {
    $tags{$_} ||= 0 for map { split ' ', $_->tags } $self->all_repos
  }

  for my $t ( sort keys %tags ) {
    say $t, ' *' x ( $self->opt->all and $tags{$t} );
  }

}

sub _remove_tags {
  my( $self, @tags ) = @_;

  $self->local_repo->remove_tags(@tags);

  $self->write_config;

  say "tags removed";
}

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
