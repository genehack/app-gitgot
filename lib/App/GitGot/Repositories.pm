package App::GitGot::Repositories;

# ABSTRACT: Object holding a collection of repositories
use 5.014;
use feature 'unicode_strings';

use Types::Standard -types;

use App::GitGot::Types qw/ GotRepo /;

use Moo;
use MooX::HandlesVia;
use namespace::autoclean;

use overload '@{}' => sub { $_[0]->all };

has repos => (
  is          => 'ro',
  isa         => ArrayRef[GotRepo],
  default     => sub { [] },
  required    => 1,
  handles_via => 'Array' ,
  handles     => {
    all => 'elements'
  }
);

=method name

Given a repo name, will return a L<App::GitGot::Repositories> object
containing the subset of repos from the current object that have that name.

=cut

sub name {
  my( $self, $name ) = @_;

  return App::GitGot::Repositories->new( repos => [
    grep { $_->{name} eq $name } $self->all
  ]);
}

=method tags

Given a list of tag names, returns a L<App::GitGot::Repositories> object
containing the subset of repos from the current object that have one or more
of those tags.

=cut

sub tags {
  my( $self, @tags ) = @_;

  my @repos = $self->all;

  for my $tag ( @tags ) {
    @repos = grep { $_->tags =~ /\b$tag\b/ } @repos;
  }

  return App::GitGot::Repositories->new( repos => \@repos );
}

1;
