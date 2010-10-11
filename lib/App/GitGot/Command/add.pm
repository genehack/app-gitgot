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

  my $entry = {
    repo => $repo ,
    name => $name ,
    type => $type ,
    path => $path ,
  };

  $entry->{tags} = $tags if $tags;

  push @{ $self->config } , $entry;
  $self->write_config;
}

1;

__END__

=head1 NAME

App::GitGot::Command::add - add a new repo to your config
