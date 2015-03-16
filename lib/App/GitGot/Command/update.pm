package App::GitGot::Command::update;

# ABSTRACT: update managed repositories
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ update up / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_update( $self->active_repos );
}

1;

## FIXME docs
