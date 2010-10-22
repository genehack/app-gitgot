package App::GitGot::Command::status;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

use Capture::Tiny qw/ capture /;

sub command_names { qw/ status st / }

sub execute {
  my( $self , $opt , $args ) = @_;

  $self->load_config();

 REPO: for my $entry ( @{ $self->repos }) {
    my( $name , $path ) = @{$entry}{qw/name path/};

    my $msg = sprintf "%3d) %-25s : " , $entry->{number} , $entry->{name};

    unless ( -d $path ) {
      say "${msg}ERROR: repo '$name' does not exist"
        if $self->verbose;
      next REPO;
    }

    print $msg;

    my $fxn = undef;

    given( $entry->{type} ) {
      when( 'git' ) { $fxn = 'git_status' }
      ### FIXME      when( 'svn' ) { $fxn = 'svn_status' }
      default { say "ERROR: repo type '$_' not supported" }
    }

    say $self->$fxn( $entry ) if ( $fxn );
  }
}

sub git_status {
  my( $self , $entry ) = @_
    or die "Need entry";

  my $path = $entry->{path};

  my $msg;

  if ( -d "$path/.git" ) {
    my( $o , $e ) = capture { system( "cd $path && git status" ) };

    if ( $o =~ /^nothing to commit/m and ! $e ) {
      if ( $o =~ /Your branch is ahead .*? by (\d+) / ) {
        $msg .= "Ahead by $1";
      }
      else {$msg .= 'OK' }
    }
    elsif ( $e ) { $msg .= 'ERROR' }
    else { $msg .= 'Dirty' }

    return ( $self->verbose ) ? "$msg\n$o$e" : $msg;
  }
}

1;

__END__

=head1 NAME

App::GitGot::Command::status - print status info about repos
