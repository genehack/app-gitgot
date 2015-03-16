package App::GitGot::Command::lib;

# ABSTRACT: Generate a lib listing off a .gotlib file
use 5.014;

use List::AllUtils qw/ uniq /;
use Path::Tiny;
use Types::Standard -types;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub options {
  my( $class , $app ) = @_;
  return (
    [ 'gotlib=s'    => 'gotlib file' => { default => '.gotlib' } ] ,
    [ 'libvar=s'    => 'library environment variable' => { default => 'PERL5LIB' } ] ,
    [ 'separator=s' => 'library path separator' => { default => ':' } ] ,
  );
}

sub _execute {
  my( $self, $opt, $args ) = @_;

  my @libs = map { $self->_expand_lib($_) } $self->_raw_libs( $args );

  no warnings; # $ENV{$self->opt->libvar} can be undefined
  say join $self->opt->separator, uniq @libs, split ':', $ENV{$self->opt->libvar};

}

sub _expand_lib {
  my( $self, $lib ) = @_;

  return path($lib)->absolute if $lib =~ m#^(?:\.|/)#;

  if ( $lib =~ s/^\@(\w+)// ) {
    # it's a tag
    return map { $_->path . $lib } $self->search_repos->tags($1)->all;
  }

  # it's a repo name
  $lib =~ s#^([^/]+)## or return;
  return map { $_->path . $lib } $self->search_repos->name($1)->all;

}

sub _raw_libs {
  my( $self, $args ) = @_;

  my $file = path( $self->opt->gotlib );

  return @$args,
    # remove comments and clean whitespaces
    grep { $_ }
    map { s/^\s+|#.*|\s+$//gr }
    ( -f $file ) ? $file->lines({ chomp => 1 }) : ();
}

1;

__END__

=head1 SYNOPSIS

    $ echo '@dancer/lib' > .gotlib
    $ export PERL5LIB=`got lib yet_another_repo_name/lib`

    # PERL5LIB will now hold the path to the 'lib'
    # subdirectory of 'yet_another_repo_name', followed
    # by the 'lib' directories of all repos tagged with 'dancer',
    # followed by the original paths of PERL5LIB


=head1 DESCRIPTION

Got's C<lib> subcommand is a Got-aware answer to L<ylib> and L<Devel::Local>,
and provides an easy way to alter the I<PERL5LIB> environment variable (or
indeed any other env variable) with local libraries in got-managed repos.

The subcommand will merge any library passed on the command line and found in
the the I<gotlib> file (if present), and will generate a library listing
where those directories are prepended to I<PERL5LIB> (command-line entries
first, then the ones from the I<gotlib> file).

Libraries can be given in three different ways:

=over

=item absolute or relative path

If the value begins with a '/' or a '.', it is assumed to be a straight path.
It will be expanded to its absolute value, but otherwise left untouched.

For example './lib' will be expanded to '/path/to/current/directory/lib'


=item tag

If the value begins with I<@>, it is assumed to be a tag, and will be replaced
by the path to all repositories having that tag.

For example '@dancer/lib' will be expanded to
'/path/to/dancer/project1/lib:/path/to/dancer/project2/lib:...'

=item project name

If not a path nor a tag, the value is assumed to be a project name.

For example 'vim-x/lib' will be expanded to
'/path/to/vim-x/lib'

=back

=head1 OPTIONS

=head2 --separator

Separator printed between library directories in the output.
Defaults to ':' (colon).

=head2 --libvar

Environment variable containing the directories  to include at the end of
the library listing. Defaults to I<PERL5LIB>.

=head2 --gotlib

File containing the list of directories to include. Defaults to I<.gotlib>.

=head1 SEE ALSO

=over

=item L<ylib>

=item L<Devel::Local>

=back

=cut
