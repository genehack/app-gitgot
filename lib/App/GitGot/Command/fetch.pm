package App::GitGot::Command::fetch;

# ABSTRACT: fetch remotes for managed repositories
use 5.014;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub _execute {
  my ( $self, $opt, $args ) = @_;

  $self->_fetch( $self->active_repos );
}

1;

### FIXME docs
