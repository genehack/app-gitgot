package App::GitGot::Command::milk;

# ABSTRACT: just welcome a cow with milk!
use 5.014;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ milk / }

sub _execute {
	# Doesn't use 'cowsay' in case it's not installed
	print "__________\n< got milk? >\n ----------\n        \\  ^__^\n         \\ (oo)\\________\n           (__)\\        )/\n                ||----w-|\n                ||     ||\n";
}

1;

## FIXME docs