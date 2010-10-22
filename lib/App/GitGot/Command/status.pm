package App::GitGot::Command::status;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

use Capture::Tiny qw/ capture /;

sub execute {
  my( $self , $opt , $args ) = @_;

  $self->load_config();

 REPO: for my $entry ( @{ $self->repos }) {
    my( $name , $path ) = @{$entry}{qw/name path/};

    unless ( -d $path ) {
      say "Repo $name does not exist";
      next REPO;
    }

    if ( -d "$path/.git" ) {
      my( $o , $e ) = capture { system( "cd $path && git status" ) };

      my $msg = sprintf "%3d) %-25s : " , $entry->{number} , $entry->{name};

      if ( $o =~ /^nothing to commit/m and ! $e ) {
        if ( $o =~ /Your branch is ahead .*? by (\d+) / ) {
          $msg .= "Ahead by $1";
        }
        else { $msg .= 'OK' }
      }
      else { $msg .= 'Dirty' }

      say $msg;

      print "$o$e" if ( $self->verbose );
    }
  }
}

1;

__END__

=head1 NAME

App::GitGot::Command::status - print status info about repos
