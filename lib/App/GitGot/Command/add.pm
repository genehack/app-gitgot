package App::GitGot::Command::add;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

use Config::INI::Reader;
use Cwd;
use Term::ReadLine;

sub execute {
  my( $self , $opt , $args ) = @_;

  $self->load_config();

  my( $repo , $name , $type , $path , $tags );

  $path = getcwd;

  if ( -e '.git' ) {
    my $cfg = Config::INI::Reader->read_file( '.git/config' );

    if ( $cfg->{'remote "origin"'}{url} ) {
      $repo = $cfg->{'remote "origin"'}{url};
    }

    if ($repo =~ m|([^/]+).git$|) {
      $name = $1;
    }

    $type = 'git';
  }

  my $term = Term::ReadLine->new( 'gitgot' );
  $name = $term->readline( 'Name: ' , $name );
  $repo = $term->readline( ' URL: ' , $repo );
  $path = $term->readline( 'Path: ' , $path );
  $tags = $term->readline( 'Tags: ' , $tags );

  my $new_entry = {
    repo => $repo ,
    name => $name ,
    type => $type ,
    path => $path ,
  };

  $new_entry->{tags} = $tags if $tags;

 REPO: foreach my $entry ( @{ $self->config } ) {
    foreach ( qw/ name repo type path / ) {
      next REPO unless $entry->{$_} eq $new_entry->{$_}
    };
    say "ERROR: Not adding entry for '$name'; exact duplicate already exists.";
    exit;
  }

  push @{ $self->config } , $new_entry;
  $self->write_config;
}

1;

__END__

=head1 NAME

App::GitGot::Command::add - add a new repo to your config
