package App::GitGot::Command::fork;

# ABSTRACT: fork a github repo
use 5.014;

use autodie;
use Class::Load       'try_load_class';
use Cwd;
use File::HomeDir;
use Path::Tiny;
use Types::Standard -types;

use App::GitGot -command;
use App::GitGot::Repo::Git;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'noclone|n'     => 'If set, do not check out a local working copy of the forked repo' ] ,
    [ 'noremoteadd|N' => 'If set, do not add the forked repo as the "upstream" repo in the new working copy' ] ,
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  try_load_class('Net::GitHub') or
    say "Sorry, Net::GitHub is required for 'got fork'. Please install it."
    and exit(1);

  my $github_url = shift @$args
    or say STDERR "ERROR: Need the URL of a repo to fork!" and exit(1);

  my( $owner , $repo_name ) = _parse_github_url( $github_url );

  my %gh_args = _parse_github_identity();

  say "Forking '$owner/$repo_name'..." unless $self->quiet;

  my $resp = Net::GitHub->new( %gh_args )->repos->create_fork( $owner , $repo_name );

  my $path = cwd() . "/$repo_name";

  my $new_repo = App::GitGot::Repo::Git->new({ entry => {
    name => $repo_name ,
    path => $path ,
    repo => $resp->{ssh_url} ,
    type => 'git' ,
  }});

  if ( ! $self->opt->noclone ) {
    say "Cloning into $path" unless $self->quiet;
    $new_repo->clone( $resp->{ssh_url} );

    if ( ! $self->opt->noremoteadd ) {
      say "Adding '$github_url' as remote 'upstream'..."
        unless $self->quiet;
      $new_repo->remote( add => upstream => $github_url );
    }
  }

  $self->add_repo( $new_repo );
  $self->write_config;
}

sub _parse_github_identity {
  my $file = path( File::HomeDir->my_home() , '.github-identity' );

  $file->exists or
    say STDERR "ERROR: Can't find $file" and exit(1);

  my @lines = $file->lines;

  my %config;
  foreach ( @lines ) {
    chomp;
    next unless $_;
    my( $k , $v ) = split /\s/;
    $config{$k} = $v;
  }

  if ( defined $config{access_token} ) {
    return ( access_token => $config{access_token} )
  }
  elsif ( defined $config{pass} and defined $config{user} ) {
    return ( login => $config{user} , pass => $config{pass} )
  }
  else {
    say STDERR "Couldn't parse password or access_token info from ~/.github-identity"
      and exit(1);
  }
}

sub _parse_github_url {
  my $url = shift;

  my( $owner , $repo ) = $url =~ m|/github.com/([^/]+)/([^/]+?)(?:\.git)?$|
    or say STDERR "ERROR: Can't parse '$url'.\nURL needs to be of the form 'github.com/OWNER/REPO'.\n"
    and exit(1);

  return( $owner , $repo );
}

1;

__END__

=head1 SYNOPSIS

    # fork repo on GitHub, then clone repository and add to got config
    $ got fork github.com/owner/repo

    # fork repo on GitHub, add to got config, but do _not_ clone locally
    $ got fork -n github.com/owner/repo
    $ got fork --noclone github.com/owner/repo

=cut
