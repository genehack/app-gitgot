package App::GitGot::Command::update;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

use Capture::Tiny qw/ capture /;

sub command_names { qw/ update up / }

sub execute {
  my ( $self, $opt, $args ) = @_;

  $self->load_config();

REPO: for my $entry ( @{ $self->repos } ) {
    next REPO unless $entry->repo;

    my $name   = $entry->name;
    my $number = $entry->number;
    my $path   = $entry->path;

    my $msg = sprintf "%3d) %-25s : ", $number, $name;

    unless ( -d $path ) {
      say "${msg}ERROR: repo '$name' does not exist"
        unless $self->quiet;
      next REPO;
    }

    my ( $status, $fxn );

    given ( $entry->type ) {
      when ('git') { $fxn = 'git_update' }
      ### FIXME      when( 'svn' ) { $fxn = 'svn_update' }
      default { $status = "ERROR: repo type '$_' not supported" }
    }

    $status = $self->$fxn($entry) if ($fxn);

    next REPO if $self->quiet and !$status;

    say "$msg$status";
  }
}

sub git_update {
  my ( $self, $entry ) = @_
    or die "Need entry";

  my $path = $entry->{path};

  my $msg = '';

  if ( !-d $path ) {
    my $repo = $entry->{repo};

    my ( $o, $e ) = capture { system("git clone $repo $path") };

    if ( $e =~ /\S/ ) {
      $msg .= 'ERROR';
    }
    else {
      $msg .= 'Checked out';
    }
  }
  elsif ( -d "$path/.git" ) {
    my ( $o, $e ) = capture { system("cd $path && git pull") };

    if ( $o =~ /^Already up-to-date/m and !$e ) {
      $msg .= 'Up to date' unless $self->quiet;
    }
    elsif ( $e =~ /\S/ ) {
      $msg .= 'ERROR';
    }
    else {
      $msg .= 'Updated';
    }

    return ( $self->verbose ) ? "$msg\n$o$e" : $msg;
  }

}

1;

__END__

=head1 NAME

App::GitGot::Command::update - update managed repositories
