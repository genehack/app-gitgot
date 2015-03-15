package App::GitGot::Command::push;

# ABSTRACT: Push local changes to the default remote in git repos
use 5.014;
use feature 'unicode_strings';

use Data::Dumper;
use Try::Tiny;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

# incremental output looks nicer for this command...
STDOUT->autoflush(1);
sub _use_io_page { 0 }

sub _execute {
  my( $self, $opt, $args ) = @_;

  my $max_len = $self->max_length_of_an_active_repo_label;

 REPO: for my $repo ( $self->active_repos ) {
    next REPO unless $repo->type eq 'git';

    unless ( $repo->current_remote_branch and $repo->cherry ) {
      printf "%3d) %-${max_len}s : Nothing to push\n",
        $repo->number , $repo->label unless $self->quiet;
      next REPO;
    }

    try {
      printf "%3d) %-${max_len}s : ", $repo->number , $repo->label;
      # really wish this gave _some_ kind of output...
      my @output = $repo->push;
      printf "%s\n", $self->major_change( 'PUSHED' );
    }
    catch {
      say STDERR $self->error( 'ERROR: Problem with push on repo ' , $repo->label );
      say STDERR "\n" , Dumper $_;
    };
  }
}

1;

## FIXME docs
