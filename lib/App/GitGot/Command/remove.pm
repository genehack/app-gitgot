package App::GitGot::Command::remove;
# ABSTRACT: remove a managed repository from your config

use Moose;
extends 'App::GitGot::BaseCommand';
use 5.010;

has 'force' => (
  is          => 'rw',
  isa         => 'Bool',
  cmd_aliases => 'f',
  traits      => [qw/ Getopt /],
);

sub command_names { qw/ remove rm / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  say "NOT IMPLEMENTED YET";

}

1;
