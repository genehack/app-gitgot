package App::GitGot::Types;

# ABSTRACT: GitGot type library
use strict;
use warnings;
use 5.014;
use feature 'unicode_strings';

use Type::Library
  -base ,
  -declare => qw/
                  GitWrapper
                  GotOutputter
                  GotRepo
                /;
use Type::Utils -all;
use Types::Standard -types;

class_type GitWrapper   , { class => "Git::Wrapper" };
class_type GotOutputter , { class => "App::GitGot::Outputter" };
class_type GotRepo      , { class => "App::GitGot::Repo" };

1;
