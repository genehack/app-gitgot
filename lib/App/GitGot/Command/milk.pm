package App::GitGot::Command::milk;

use 5.014;

# ABSTRACT: well, do you?
use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ milk / }

sub _execute {
        # Doesn't use 'cowsay' in case it's not installed
  print " ___________\n";
  print "< got milk? >\n";
  print " -----------\n";
  print "        \\   ^__^\n";
  print "         \\  (oo)\\_______\n";
  print "            (__)\\       )\\/\\ \n";
  print "                ||----w |\n";
  print "                ||     ||\n";
  print "\n";
}



1;
