package App::GitGot::Command::milk;

use 5.014;

use App::GitGot -command;

use Moo;
extends 'App::GitGot::Command';
use namespace::autoclean;

sub command_names { qw/ milk / }

sub _execute {
	# Doesn't use 'cowsay' in case it's not installed
	my $msg <<EOT;
 __________
< got milk? >
 ----------
		\   ^__^
		 \  (oo)\_______
			(__)\       )\/\
				||----w |
				||	   ||
EOT
	print $msg;
}

1;

