package App::GitGot::Command::status;

# ABSTRACT: print status info about repos
use Mouse;
extends 'App::GitGot::Command';
use 5.010;
use namespace::autoclean;

sub command_names { qw/ status st / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_status( $self->active_repos );
}

__PACKAGE__->meta->make_immutable;
1;
