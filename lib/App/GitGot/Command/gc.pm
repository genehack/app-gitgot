package App::GitGot::Command::gc;

# ABSTRACT: Run the 'gc' command to garbage collect in git repos
use 5.014;

use Data::Dumper;
use Try::Tiny;

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
    try {
      printf "%3d) %-${max_len}s : ", $repo->number , $repo->label unless $self->quiet;
      # really wish this gave _some_ kind of output...
      $repo->gc;
      printf "%s\n", $self->major_change( 'COLLECTED' ) unless $self->quiet;
    }
    catch {
      say STDERR $self->error( 'ERROR: Problem with GC on repo ' , $repo->label );
      say STDERR "\n" , Dumper $_;
    };
  }
}

1;

## FIXME docs
