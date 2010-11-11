package App::GitGot::Command::update;
# ABSTRACT: update managed repositories

use Moose;
extends 'App::GitGot::Command';
use 5.010;

use Capture::Tiny qw/ capture /;
use Term::ANSIColor;

sub command_names { qw/ update up / }

sub _execute {
  my ( $self, $opt, $args ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( $self->active_repos ) {
    next REPO unless $repo->repo;

    my $name = $repo->name;

    my $msg = sprintf "%3d) %-${max_len}s  : ", $repo->number, $repo->label;

    my ( $status, $fxn );

    given ( $repo->type ) {
      when ('git') { $fxn = '_git_update' }
      ### FIXME      when( 'svn' ) { $fxn = 'svn_update' }
      default {
        $status = colored("ERROR: repo type '$_' not supported",'bold white on_red');
      }
    }

    $status = $self->$fxn($repo) if ($fxn);

    next REPO if $self->quiet and !$status;

    say "$msg$status";
  }
}

sub _git_update {
  my ( $self, $entry ) = @_
    or die "Need entry";

  my $path = $entry->path;

  my $msg = '';

  if ( !-d $path ) {
    my $repo = $entry->repo;

    my ( $o, $e ) = capture { system("git clone $repo $path") };

    if ( $e =~ /\S/ ) {
      $msg .= colored("ERROR: ",'bold white on_red').$e;
    }
    else {
      $msg .= colored('Checked out','bold white on_green');
    }
  }
  elsif ( -d "$path/.git" ) {
    my ( $o, $e ) = capture { system("cd $path && git pull") };

    if ( $o =~ /^Already up-to-date/ ) {
      $msg .= colored('Up to date','green') unless $self->quiet;
    }
    else {
      $msg .= "\n$o$e";
    }

    return ( $self->verbose ) ? "$msg\n$o$e" : $msg;
  }

}

1;
