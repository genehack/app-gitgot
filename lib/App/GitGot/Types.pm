package App::GitGot::Types;

# ABSTRACT: GitGot type library
use 5.014;    ## strict, unicode_strings
use warnings;

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
