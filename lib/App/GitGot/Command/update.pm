package App::GitGot::Command::update;
# ABSTRACT: update managed repositories

use Moose;
extends 'App::GitGot::Command';
use 5.010;

use File::Path 2.08 qw/ make_path /;
use Git::Wrapper;
use Term::ANSIColor;
use Try::Tiny;

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
  my $repo = Git::Wrapper->new( $path );

  my $msg = '';

  if ( !-d $path ) {
    make_path $path;

    try {
      $repo->clone( $entry->repo , './' );
      $msg .= colored('Checked out','bold white on_green');
    }
    catch { $msg .= colored('ERROR','bold white on_red') . "\n$_" };
  }
  elsif ( -d "$path/.git" ) {
    try {
      my @o = $repo->pull;
      if ( $o[0] eq 'Already up-to-date.' ) {
        $msg .= colored('Up to date','green') unless $self->quiet;
      }
      else {
        $msg .= colored('Updated','bold black on_green');
        $msg .= "\n" . join("\n",@o) unless $self->quiet;
      }
    }
  }
  catch { $msg .= colored('ERROR','bold white on_red') . "\n$_" };

  return $msg;
}

1;
