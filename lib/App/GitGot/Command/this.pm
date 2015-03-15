package App::GitGot::Command::this;

# ABSTRACT: check if the current repository is managed
use 5.014;
use feature 'unicode_strings';

use Cwd;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub _execute {
  my( $self, $opt, $args ) = @_;

  $self->_path_is_managed( getcwd() ) or exit 1;
}

1;

## FIXME docs
