package App::GitGot::Command::status;
# ABSTRACT: print status info about repos

use Moose;
extends 'App::GitGot::Command';
use 5.010;

use Capture::Tiny qw/ capture /;
use Term::ANSIColor;

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

  my $path = $entry->path;

  my $msg = '';

  if ( -d "$path/.git" ) {
    my ( $o, $e ) = capture { system("cd $path && git status") };

    if ( $o =~ /^nothing to commit/m and !$e ) {
      if ( $o =~ /Your branch is ahead .*? by (\d+) / ) {
        $msg .= colored("Ahead by $1",'bold black on_green');
      }
      else { $msg .= colored('OK','green' ) unless $self->quiet }
    }
    elsif ($e) { $msg .= colored('ERROR','bold white on_red') }
    else       { $msg .= colored('Dirty','bold black on_bright_yellow') }

    return ( $self->verbose ) ? "$msg\n$o$e" : $msg;
  }
}

1;
