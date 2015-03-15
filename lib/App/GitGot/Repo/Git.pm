package App::GitGot::Repo::Git;

# ABSTRACT: Git repo objects
use 5.014;
use feature 'unicode_strings';

use Git::Wrapper;
use Test::MockObject;
use Try::Tiny;
use Types::Standard -types;

use App::GitGot::Types qw/ GitWrapper /;

use Moo;
extends 'App::GitGot::Repo';
use namespace::autoclean;

has '+type' => ( default => 'git' );

has '_wrapper' => (
  is         => 'lazy' ,
  isa        => GitWrapper ,
  handles    => [ qw/
                      cherry
                      clone
                      config
                      fetch
                      gc
                      pull
                      push
                      remote
                      status
                      symbolic_ref
                    / ] ,
);

sub _build__wrapper {
  my $self = shift;

  # for testing...
  if ( $ENV{GITGOT_FAKE_GIT_WRAPPER} ) {
    my $mock = Test::MockObject->new;
    $mock->set_isa( 'Git::Wrapper' );
    foreach my $method ( qw/ cherry clone fetch gc pull
                             remote symbolic_ref / ) {
      $mock->mock( $method => sub { return( '1' )});
    }
    $mock->mock( 'status' => sub { package
                                     MyFake; sub get { return () }; return bless {} , 'MyFake' } );
    $mock->mock( 'config' => sub { 0 });
    $mock->mock( 'ERR'    => sub { [ ] });

    return $mock
  }
  else {
    return Git::Wrapper->new( $self->path )
      || die "Can't make Git::Wrapper";
  }
}


=method current_branch

Returns the current branch checked out by this repository object.

=cut

sub current_branch {
  my $self = shift;

  my $branch;

  try {
    ( $branch ) = $self->symbolic_ref( 'HEAD' );
    $branch =~ s|^refs/heads/|| if $branch;
  }
  catch {
    die $_ unless $_ && $_->isa('Git::Wrapper::Exception')
      && $_->error eq "fatal: ref HEAD is not a symbolic ref\n"
  };

  return $branch;
}

=method current_remote_branch

Returns the remote branch for the branch currently checked out by this repo
object, or 0 if that information can't be extracted (if, for example, the
branch doesn't have a remote.)

=cut

sub current_remote_branch {
  my( $self ) = shift;

  my $remote = 0;

  if ( my $branch = $self->current_branch ) {
    try {
      ( $remote ) = $self->config( "branch.$branch.remote" );
    }
    catch {
      ## not the most informative return....
      return 0 if $_ && $_->isa('Git::Wrapper::Exception') && $_->{status} eq '1';
    };
  }

  return $remote;
}

1;
