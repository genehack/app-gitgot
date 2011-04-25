package Test::BASE;
use parent 'Test::Class';

use strict;
use warnings;
use 5.010;

use Carp;

INIT { Test::Class->runtests }

1;
