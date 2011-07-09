package App::GitGot::Outputter::dark;
# ABSTRACT: Color scheme appropriate for dark terminal backgrounds

use Mouse;
extends 'App::GitGot::Outputter';
use 5.010;

has 'color_error' => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'bold white on_red'
);

has 'color_warning' => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'bold black on_yellow'
);

has 'color_major_change' => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'bold black on_green'
);

has 'color_minor_change' => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'green'
);

__PACKAGE__->meta->make_immutable;
1;
