package Test::App::GitGot::Repo::Git;
use parent 'Test::App::GitGot::Repo';

use strict;
use warnings;

use App::GitGot::Repo::Git;
use Test::Exception;
use Test::More;

sub fixtures :Test(startup) {
  my $test = shift;

  $test->{lib} = 'App::GitGot::Repo::Git';

  $test->make_base_fixtures;
}

sub test_current_branch :Tests(3) {
  my $test = shift;

  dies_ok { $test->{full}->current_branch } 'will die';
  like( $@ , qr/Can't locate directory/ , 'expected error message' );

  is( $test->{min}->current_branch , 'master' , 'expected answer' );
}

sub test_current_remote_branch :Tests(3) {
  my $test = shift;

  dies_ok { $test->{full}->current_branch } 'will die';
  like( $@ , qr/Can't locate directory/ , 'expected error message' );

  is( $test->{min}->current_remote_branch , 0 , 'get 0 without real remote' );
}

sub cleanup :Test(shutdown) { chdir('/') }

1;
