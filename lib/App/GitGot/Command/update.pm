package App::GitGot::Command::update;

# ABSTRACT: update managed repositories
use Mouse;
extends 'App::GitGot::Command';
use 5.010;
use namespace::autoclean;

sub command_names { qw/ update up / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_update( $self->active_repos );
}

__PACKAGE__->meta->make_immutable;
1;
