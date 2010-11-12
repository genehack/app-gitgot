package App::GitGot::Command::status;
# ABSTRACT: print status info about repos

use Moose;
extends 'App::GitGot::Command';
use 5.010;

use Git::Wrapper;
use Term::ANSIColor;
use Try::Tiny;

sub command_names { qw/ status st / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( $self->active_repos ) {
    my $label = $repo->label;

    my $msg = sprintf "%3d) %-${max_len}s  : ", $repo->number, $label;

    my ( $status, $fxn );

    if ( -d $repo->path ) {
      given ( $repo->type ) {
        when ('git') { $fxn = '_git_status' }
        ### FIXME      when( 'svn' ) { $fxn = 'svn_status' }
        default {
          $status = colored("ERROR: repo type '$_' not supported", 'bold white on_red' );
        }
      }

      $status = $self->$fxn($repo) if ($fxn);

      next REPO if $self->quiet and !$status;
    }
    elsif ( $repo->repo ) {
      $status = 'Not checked out';
    }
    else {
      $status = colored("ERROR: repo '$label' does not exist",'bold white on_red' );
    }

    say "$msg$status";
  }
}

sub _git_status {
  my ( $self, $entry ) = @_
    or die "Need entry";

  my( $msg , $verbose_msg ) = $self->_run_git_status( $entry );

  $msg .= $self->_run_git_cherry( $entry );

  return ( $self->verbose ) ? "$msg$verbose_msg" : $msg;
}

sub _run_git_cherry {
  my( $self , $entry ) = @_;

  my $repo = Git::Wrapper->new( $entry->path );

  my $msg = '';

  try {
    if ( $repo->remote ) {
      my $cherry = $repo->cherry;
      if ( $cherry > 0 ) {
        $msg = colored("Ahead by $cherry",'bold black on_green');
      }
    }
  }
  catch { $msg = colored('ERROR','bold white on_red') . "\n$_" };

  return $msg
}

sub _run_git_status {
  my( $self , $entry ) = @_;

  my $repo = Git::Wrapper->new( $entry->path );

  my %types = (
    indexed  => 'Changes to be committed' ,
    changed  => 'Changed but not updated' ,
    unknown  => 'Untracked files' ,
    conflict => 'Files with conflicts' ,
  );

  my( $msg , $verbose_msg ) = ('','');

  try {
    my $status = $repo->status;
    if ( keys %$status ) { $msg .= colored('Dirty','bold black on_bright_yellow') . ' ' }
    else                 { $msg .= colored('OK ','green' ) unless $self->quiet }

    if ( $self->verbose ) {
    TYPE: for my $type ( keys %types ) {
        my @states = $status->get( $type ) or next TYPE;
        $verbose_msg .= "\n** $types{$type}:\n";
        for ( @states ) {
          $verbose_msg .= sprintf '  %-12s %s' , $_->mode , $_->from;
          $verbose_msg .= sprintf ' -> %s' , $_->to if $_->mode eq 'renamed';
          $verbose_msg .= "\n";
        }
      }
      $verbose_msg = "\n$verbose_msg" if $verbose_msg;
    }
  }
  catch { $msg .= colored('ERROR','bold white on_red') . "\n$_" };

  return( $msg , $verbose_msg );
}

1;
