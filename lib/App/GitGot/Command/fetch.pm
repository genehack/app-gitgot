package App::GitGot::Command::fetch;
# ABSTRACT: fetch remotes for managed repositories

use Mouse;
extends 'App::GitGot::Command';
use 5.010;

sub command_names { qw/ fetch / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_fetch( $self->active_repos );
}

__PACKAGE__->meta->make_immutable;
1;
