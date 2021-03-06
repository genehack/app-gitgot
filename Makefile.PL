# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.015.
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A tool to make it easier to manage multiple git repositories.",
  "AUTHOR" => "John SJ Anderson <john\@genehack.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-GitGot",
  "EXE_FILES" => [
    "bin/git-got",
    "bin/got",
    "bin/got-complete"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.014",
  "NAME" => "App::GitGot",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => 0,
    "Capture::Tiny" => 0,
    "Class::Load" => 0,
    "Config::INI::Reader" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "File::Copy::Recursive" => 0,
    "File::HomeDir::Tiny" => 0,
    "File::chdir" => 0,
    "Git::Wrapper" => "0.042",
    "IO::Prompt::Simple" => 0,
    "List::Util" => "1.45",
    "Moo" => "2.000000",
    "MooX::HandlesVia" => "0.001008",
    "Path::Tiny" => "0.072",
    "PerlX::Maybe" => 0,
    "Term::ANSIColor" => 0,
    "Test::MockObject" => 0,
    "Try::Tiny" => 0,
    "Type::Library" => 0,
    "Type::Utils" => 0,
    "Types::Standard" => 0,
    "YAML" => 0,
    "autodie" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "App::Cmd::Tester" => 0,
    "Carp" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Class" => 0,
    "Test::Class::Load" => 0,
    "Test::Exception" => 0,
    "Test::File" => 0,
    "Test::More" => "0.94",
    "lib" => 0,
    "parent" => 0,
    "strict" => 0
  },
  "VERSION" => "1.339",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "App::Cmd::Setup" => 0,
  "App::Cmd::Tester" => 0,
  "Capture::Tiny" => 0,
  "Carp" => 0,
  "Class::Load" => 0,
  "Config::INI::Reader" => 0,
  "Cwd" => 0,
  "Data::Dumper" => 0,
  "File::Copy::Recursive" => 0,
  "File::HomeDir::Tiny" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "File::chdir" => 0,
  "Git::Wrapper" => "0.042",
  "IO::Handle" => 0,
  "IO::Prompt::Simple" => 0,
  "IPC::Open3" => 0,
  "List::Util" => "1.45",
  "Moo" => "2.000000",
  "MooX::HandlesVia" => "0.001008",
  "Path::Tiny" => "0.072",
  "PerlX::Maybe" => 0,
  "Term::ANSIColor" => 0,
  "Test::Class" => 0,
  "Test::Class::Load" => 0,
  "Test::Exception" => 0,
  "Test::File" => 0,
  "Test::MockObject" => 0,
  "Test::More" => "0.94",
  "Try::Tiny" => 0,
  "Type::Library" => 0,
  "Type::Utils" => 0,
  "Types::Standard" => 0,
  "YAML" => 0,
  "autodie" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "overload" => 0,
  "parent" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
