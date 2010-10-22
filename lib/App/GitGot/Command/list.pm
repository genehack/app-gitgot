package App::GitGot::Command::list;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

sub command_names { qw/ list ls / }

sub execute {
  my( $self , $opt , $args ) = @_;

  $self->load_config();

  for my $entry ( @{ $self->repos }) {
    my $msg = sprintf "%-25s %-4s %-50s\n" ,
      $entry->{name} , $entry->{type} , $entry->{repo};

    printf "%3d) " , $entry->{number};

    if ( $self->quiet) { say $entry->{name} }
    elsif ( $self->verbose ) {
      print "$msg    tags: $entry->{tags}\n";
    }
    else { print $msg}
  }
}

1;

__END__

=head1 NAME

App::GitGot::Command::list - list managed repositories
