package App::GitGot::Command::fork;
# ABSTRACT: fork a github repo

use Mouse;
extends 'App::GitGot::Command';
use 5.010;

use autodie;
use App::GitGot::Repo::Git;
use Cwd;
use File::Slurp::Tiny 'read_lines';
use Net::GitHub;

has 'noclone' => (
  is          => 'rw',
  isa         => 'Bool',
  cmd_aliases => 'n',
  traits      => [qw/ Getopt /],
);

sub _execute {
  my( $self, $opt, $args ) = @_;

  my $github_url = shift @$args
    or say STDERR "ERROR: Need the URL of a repo to fork!" and exit(1);

  my( $owner , $repo_name ) = _parse_github_url( $github_url );

  my %gh_args = _parse_github_identity();

  my $resp = Net::GitHub->new( %gh_args )->repos->create_fork( $owner , $repo_name );

  my $new_repo = App::GitGot::Repo::Git->new({ entry => {
    name => $repo_name ,
    path => cwd() . "/$repo_name" ,
    repo => $resp->{ssh_url} ,
    type => 'git' ,
  }});

  $new_repo->clone( $resp->{ssh_url} )
    unless $self->noclone;

  $self->add_repo( $new_repo );
  $self->write_config;
}

sub _parse_github_identity {
  my $file = "$ENV{HOME}/.github-identity";

  -e $file or
    say STDERR "ERROR: Can't find $ENV{HOME}/.github-identity" and exit(1);

  my @lines = read_lines( $file );

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

  my( $owner , $repo ) = $url =~ m|/github.com/([^/]+)/([^/]+).git$|
    or say STDERR "ERROR: Can't parse '$url'" and exit(1);

  return( $owner , $repo );
}

__PACKAGE__->meta->make_immutable;
1;
