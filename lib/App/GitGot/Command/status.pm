package App::GitGot::Command::status;

# ABSTRACT: print status info about repos
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ status st / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_status( $self->active_repos );
}

1;

## FIXME docs
