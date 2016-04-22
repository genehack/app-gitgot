package App::GitGot::Command::update_status;

# ABSTRACT: update managed repositories then display their status
use 5.014;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ update_status upst / }

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'show-branch' => 'show which branch' => { default => 0 } ] ,
  );
}

sub _execute {
  my ( $self, $opt, $args ) = @_;

  say "UPDATE";
  $self->_update( $self->active_repos );

  say "\nSTATUS";
  $self->_status( $self->active_repos );
}

1;

## FIXME docs
