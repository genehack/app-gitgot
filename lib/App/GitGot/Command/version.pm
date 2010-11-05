package App::GitGot::Command::version;
# ABSTRACT: display application version

use Moose;
extends 'App::GitGot::BaseCommand';
use 5.010;

sub _execute {
  my( $self, $opt, $args ) = @_;

  say $App::GitGot::VERSION
}

1;
