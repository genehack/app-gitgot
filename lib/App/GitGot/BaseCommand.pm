package App::GitGot::BaseCommand;
use Moose;
extends 'MooseX::App::Cmd::Command';

use 5.010;

use Storable   qw/ dclone /;
use Try::Tiny;
use YAML       qw/ DumpFile LoadFile /;

has 'all' => (
  is     => 'rw' ,
  isa    => 'Bool' ,
  traits => [ qw/ Getopt / ],
);

has 'config' => (
  is     => 'rw' ,
  isa    => 'ArrayRef[HashRef]' ,
  traits => [ qw/ NoGetopt / ] ,
);

has 'configfile' => (
  is            => 'rw' ,
  isa           => 'Str' ,
  documentation => 'path to config file' ,
  default       => "$ENV{HOME}/.gitgot" ,
  traits        => [ qw/ Getopt /] ,
  required      => 1 ,
);

has 'quiet' => (
  is            => 'rw' ,
  isa           => 'Bool' ,
  documentation => 'keep it down' ,
  traits        => [ qw/ Getopt / ] ,
);

has 'repos' => (
  is     => 'rw' ,
  isa    => 'ArrayRef[HashRef]' ,
  traits => [ qw/ NoGetopt / ] ,
);

has 'tags' => (
  is     => 'rw' ,
  isa    => 'ArrayRef[Str]' ,
  traits => [ qw/ Getopt / ] ,
);

has 'verbose' => (
  is            => 'rw' ,
  isa           => 'Bool' ,
  documentation => 'bring th\' noise' ,
  traits        => [ qw/ Getopt / ] ,
);


sub build_repo_list_from_args {
  my( $self , $args ) = @_;

  my $list = $self->expand_arg_list( $args );

  my @repos;
 REPO: foreach my $repo ( @{ $self->config }) {
    my( $number , $name ) = @{ $repo }{qw/ number name /};

    if ( grep { $_ eq $number or $_ eq $name } @$list ) {
      push @repos , $repo;
      next REPO;
    }

    if ( $self->tags ) {
      foreach my $tag ( @{ $self->tags }) {
        if ( grep { $repo->{tags} =~ /\b$_\b/ } $tag ) {
          push @repos , $repo;
          next REPO;
        }
      }
    }
  }
  return \@repos;
}

sub expand_arg_list {
  my( $self , $args ) = @_;

  return [
    map {
      s!/$!!;
      if (/^(\d+)-(\d+)?$/) {
        ($1..$2);
      } else {
        ($_);
      }
    } @$args
  ];

}

sub load_config {
  my $self = shift;

  $self->read_config;
  $self->parse_config;
}

sub parse_config {
  my $self = shift;

  my $repo_count = 1;

  foreach my $entry ( @{ $self->config } ) {
    my $repo = $entry->{repo}
      or die "No 'repo' field for entry $repo_count";

    defined $entry->{path}
      or die "No 'path' field for repo $repo";

    $entry->{number} = $repo_count++;

    unless ( defined $entry->{name} ) {
      if ($repo =~ m|([^/]+).git$|) {
        $entry->{name} = $1;
      } else {
        $entry->{name} = '';
      }
    }

    $entry->{tags} //= '';

    $entry->{type} //= '';
    if ($repo =~ /\.git$/) {
      $entry->{type} = 'git';
    } elsif ($repo =~ /svn/) {
      $entry->{type} = 'svn';
    }
  }
}

sub read_config {
  my $self = shift;

  my $config;

  try   { $config = LoadFile( $self->configfile ) }
  catch { say "Failed to parse config..." ; exit  };

  try   { $self->config($config) }
  catch {
    if ( /Attribute \(config\) does not pass the type constraint/ ) {
      say "Config file must be a list of hashrefs.";
      exit;
    }
    else {
      die $_;
    }
  };
}

sub validate_args {
  my( $self , $opt , $args ) = @_;

  $self->load_config;

  return $self->repos( $self->config )
    if ( $self->all );

  my $repo_list = ( $self->tags || @$args ) ?
    $self->build_repo_list_from_args( $args )
      : $self->config;

  return $self->repos( $repo_list );
}

sub write_config {
  my( $self ) = @_;

  my $config_copy = dclone $self->config;
  foreach my $entry ( @{ $config_copy }) {
    delete $entry->{number};
    foreach ( qw/ name type tags /) {
      delete $entry->{$_} unless $entry->{$_};
    }
  }

  DumpFile( $self->configfile , $config_copy );
}

1;
