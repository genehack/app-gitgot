package App::GitGot::Outputter::light;

# ABSTRACT: Color scheme appropriate for dark terminal backgrounds
use Mouse;
extends 'App::GitGot::Outputter';
use 5.010;
use namespace::autoclean;

has color_error => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'bold red'
);

# Color choices by drdrang based on a conversation that started with
# <http://www.leancrew.com/all-this/2010/12/batch-comparison-of-git-repositories/>

has color_major_change => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'blue'
);

has color_minor_change => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'uncolored'
);

has color_warning => (
  is      => 'ro' ,
  isa     => 'Str' ,
  default => 'bold magenta'
);

__PACKAGE__->meta->make_immutable;
1;
