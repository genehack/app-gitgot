package Test::App::GitGot::Repo::Git;
use parent 'Test::App::GitGot::Repo';

use 5.014;                      # strict, unicode_strings
use warnings;

use Test::Exception;
use Test::More;

use App::GitGot::Repo::Git;

sub fixtures :Test(startup) {
  my $test = shift;

  $test->{lib} = 'App::GitGot::Repo::Git';

  $test->make_base_fixtures;
}

sub test_current_branch :Tests(3) {
  my $test = shift;

  dies_ok { $test->{full}->current_branch } 'will die';
  like( $@ , qr/(?:Can't locate|Failed to change) directory/ , 'expected error message' );

  is( $test->{min}->current_branch , 'main' , 'expected answer' );
}

sub test_current_remote_branch :Tests(3) {
  my $test = shift;

  dies_ok { $test->{full}->current_branch } 'will die';
  like( $@ , qr/(?:Can't locate|Failed to change) directory/ , 'expected error message' );

  is( $test->{min}->current_remote_branch , 0 , 'get 0 without real remote' );
}

sub cleanup :Test(shutdown) { chdir('/') }

1;
