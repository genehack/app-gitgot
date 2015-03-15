package App::GitGot::Command::that;

# ABSTRACT: check if a given repository is managed
use 5.014;
use feature 'unicode_strings';

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub _execute {
  my( $self, $opt, $args ) = @_;
  my $path = pop @$args;

  defined $path and -d $path
    or say STDERR 'ERROR: You must provide a path to a repo to check' and exit 1;

  $self->_path_is_managed( $path ) or exit 1;
}

1;

## FIXME docs
