package App::GitGot::Command::this;

# ABSTRACT: check if the current repository is managed
use Mouse;
extends 'App::GitGot::Command';
use 5.010;
use namespace::autoclean;

use Cwd;

sub command_names { qw/ this / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  $self->_path_is_managed( getcwd() ) or exit 1;
}

__PACKAGE__->meta->make_immutable;
1;
