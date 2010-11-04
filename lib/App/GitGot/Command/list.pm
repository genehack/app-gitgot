package App::GitGot::Command::list;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

sub command_names { qw/ list ls / }

sub _execute {
  my( $self, $opt, $args ) = @_;

  for my $repo ( $self->active_repos ) {
    my $msg = sprintf "%-25s %-4s %-50s\n",
      $repo->name, $repo->type, $repo->repo || 'NO REMOTE';

    printf "%3d) ", $repo->number;

    if ( $self->quiet ) { say $repo->name }
    elsif ( $self->verbose ) {
      printf "$msg    tags: %s\n" , $repo->tags;
    }
    else { print $msg}
  }
}

1;

__END__

=head1 NAME

App::GitGot::Command::list - list managed repositories
