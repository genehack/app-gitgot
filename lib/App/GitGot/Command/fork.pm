package App::GitGot::Command::fork;
# ABSTRACT: fork a github repo

use Moose;
extends 'App::GitGot::Command';
use 5.010;

use autodie;
use App::GitGot::Repo::Git;
use Cwd;
use Net::GitHub::V2::Repositories;

sub _execute {
  my( $self, $opt, $args ) = @_;

  my $github_url = shift @$args
    or die "Need the URL of a repo to fork!";

  my( $user , $pass ) = _parse_github_identity();

  my( $owner , $repo_name ) = _parse_github_url( $github_url );

  my $repo = Net::GitHub::V2::Repositories->new(
    owner => $owner ,
    repo  => $repo_name ,
    login => $user ,
    token => $pass ,
  );

  $repo->fork; ## hardcore forking action!

  my $new_repo_url = $github_url;
  $new_repo_url =~ s/$owner/$user/;

  my $cwd = cwd();

  my $entry = {
    name => $repo_name ,
    path => "$cwd/$repo_name" ,
    repo => $new_repo_url ,
    type => 'git' ,
  };
  my $new_repo = App::GitGot::Repo::Git->new({ entry => $entry });
  $self->add_repo( $new_repo );
  $self->write_config;
}

sub _parse_github_identity {
  my $file = "$ENV{HOME}/.github-identity";
  die "Can't find ~/.github-identity"
    unless -e $file;

  open( my $IN , '<' , $file );
  my @lines = <$IN>;
  close( $IN );

  my %config;
  foreach ( @lines ) {
    my( $key , $value ) = split /\s/;
    $config{$key} = $value;
  }

  my $user = $config{login}
    or die "Couldn't parse login info from ~/.github_identity";

  my $pass = $config{token}
    or die "Couldn't parse token info from ~/.github_identity";

  return( $user , $pass );
}

sub _parse_github_url {
  my $url = shift;

  die "Can't parse that"
    unless $url =~ m|/github.com/([^/]+)/([^/]+).git$|;

  return( $1 , $2 );
}

__PACKAGE__->meta->make_immutable;
1;
