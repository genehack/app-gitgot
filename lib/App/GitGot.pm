package App::GitGot;

use Mouse;
extends 'MouseX::App::Cmd';
# ABSTRACT: A tool to make it easier to manage multiple git repositories.

=head1 SYNOPSIS

See C<perldoc got> for usage information.

=cut

__PACKAGE__->meta->make_immutable;
1;
