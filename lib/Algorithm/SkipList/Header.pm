package Algorithm::SkipList::Header;

use 5.006;
use strict;
use warnings::register __PACKAGE__;

use Carp qw( carp );

our $VERSION = '0.73_01';

$VERSION = eval $VERSION;

our @ISA = qw( Algorithm::SkipList::Node );

sub key_cmp {
  -1;
}

sub key {
  carp "this method should never be run", if (warnings::enabled);
  return;
}

sub value {
  carp "this method should never be run", if (warnings::enabled);
  return;
}

1;

__END__

=head1 NAME

Algorithm::SkipList::Header - header node class for Algorithm::SkipList

=head1 DESCRIPTION

This is a specialized subclass of L<Algorithm::SkipList::Node> for
header nodes.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2003-2004 Robert Rothenberg. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

  Algorithm::SkipList

=cut

