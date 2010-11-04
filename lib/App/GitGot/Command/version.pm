package App::GitGot::Command::version;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;
use App::GitGot;
sub _execute {
  my( $self, $opt, $args ) = @_;

  say $App::GitGot::VERSION
}

1;

__END__

=head1 NAME

App::GitGot::Command::version - display application version
