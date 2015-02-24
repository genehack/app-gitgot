package App::GitGot::Repositories;

use Mouse;

use 5.010;

use strict;
use warnings;

use overload '@{}' => sub { $_[0]->all };

has repos => (
    traits => [ qw/ Array / ],
    is => 'ro',
    isa => 'ArrayRef[App::GitGot::Repo::Git]',
    default => sub { [] },
    required => 1,
    handles => { all => 'elements' },
);

sub tags {
    my( $self, @tags ) = @_;

    my @repos = $self->all;

    for my $tag ( @tags ) {
        @repos = grep { $_->tags =~ /\b$tag\b/ } @repos;
    }

    return App::GitGot::Repositories->new( repos => \@repos );
}

sub name {
    my( $self, $name ) = @_;

    return App::GitGot::Repositories->new( repos => [
        grep { $_->{name} eq $name } $self->all
    ]);
}




1;



