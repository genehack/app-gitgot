package App::GitGot::Command::version;

# ABSTRACT: display application version
use 5.014;
use feature 'unicode_strings';

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub _execute { say $App::GitGot::VERSION }

1;

## FIXME docs
