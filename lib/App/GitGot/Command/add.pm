package App::GitGot::Command::add;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

use Config::INI::Reader;
use Cwd;
use Term::ReadLine;
use Term::ReadLine::Perl;    # this is listed so we pull it in as a dep

has 'defaults' => (
  is          => 'rw',
  isa         => 'Bool',
  cmd_aliases => 'D',
  traits      => [qw/ Getopt /],
);

sub execute {
  my ( $self, $opt, $args ) = @_;

  my $new_entry = $self->build_new_entry_from_user_input();

  # this will exit if the new_entry duplicates an existing repo in the config
  $self->check_for_dupe_entries($new_entry);

  push @{ $self->parsed_config }, $new_entry;
  $self->write_config;
}

sub build_new_entry_from_user_input {
  my ($self) = @_;

  my ( $repo, $name, $type, $tags, $path );

  if ( -e '.git' ) {
    ( $repo, $name, $type ) = _init_for_git();
  }
  else {
    say "ERROR: Non-git repos not supported at this time.";
    exit;
  }

  if ( $self->defaults ) {
    die "ERROR: Couldn't determine name"      unless $name;
    die "ERROR: Couldn't determine repo path" unless $repo;
    die "ERROR: Couldn't determine repo type" unless $type;
    $path = getcwd or die "ERROR: Couldn't determine path";
  }
  else {
    my $term = Term::ReadLine->new('gitgot');
    $name = $term->readline( 'Name: ', $name );
    $repo = $term->readline( ' URL: ', $repo );
    $path = $term->readline( 'Path: ', getcwd );
    $tags = $term->readline( 'Tags: ', $tags );
  }

  my $new_entry = {
    repo => $repo,
    name => $name,
    type => $type,
    path => $path,
  };

  $new_entry->{tags} = $tags if $tags;

  return App::GitGot::Repo->new({ entry => $new_entry });
}

sub check_for_dupe_entries {
  my ( $self, $new_entry ) = @_;

  $self->load_config();
REPO: foreach my $entry ( @{ $self->parsed_config } ) {
    foreach (qw/ name repo type path /) {
      next REPO unless $entry->$_ and $entry->$_ eq $new_entry->$_;
    }
    say
"ERROR: Not adding entry for '$entry->{name}'; exact duplicate already exists.";
    exit;
  }
}

sub _init_for_git {
  my ( $repo, $name, $type );

  my $cfg = Config::INI::Reader->read_file('.git/config');

  if ( $cfg->{'remote "origin"'}{url} ) {
    $repo = $cfg->{'remote "origin"'}{url};
    if ( $repo =~ m|([^/]+).git$| ) {
      $name = $1;
    }
  }

  $type = 'git';

  return ( $repo, $name, $type );
}

1;

__END__

=head1 NAME

App::GitGot::Command::add - add a new repo to your config
