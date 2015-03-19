#! /usr/bin/env perl
use 5.014;                      # strict, unicode_strings
use warnings;
use Test::Class::Load qw<t/lib>;
use Test::More;

use File::Temp qw/ tempdir /;
use Git::Wrapper;

my $dir = tempdir(CLEANUP => 1);
my $git = Git::Wrapper->new($dir);

my $version = $git->version;
diag( "Testing with git version: " . $version );
