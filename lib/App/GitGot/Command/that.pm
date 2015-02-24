package App::GitGot::Command::that;

# ABSTRACT: check if a given repository is managed
use Mouse;
extends 'App::GitGot::Command';
use 5.010;
use namespace::autoclean;

sub command_names { qw/ that / }

sub _execute {
  my( $self, $opt, $args ) = @_;
  my $path = pop @$args;

  defined $path and -d $path
    or say STDERR 'ERROR: You must provide a path to a repo to check' and exit 1;

  $self->_path_is_managed( $path ) or exit 1;
}

__PACKAGE__->meta->make_immutable;
1;
