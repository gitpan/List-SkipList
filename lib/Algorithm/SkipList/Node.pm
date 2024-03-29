package Algorithm::SkipList::Node;

use 5.006;
use strict;
use warnings;

# use Carp qw(carp croak);
# no Carp::Assert qw(assert DEBUG);

our $VERSION = '0.73_01';

$VERSION = eval $VERSION;

use enum qw( HEADER=0 KEY VALUE );

sub new {
  my ($class, $key, $value, $hdr) = @_;
  my $self  = [ ($hdr || [ ]), $key, $value ];

  bless $self, $class;
}

sub header {
  my ($self, $hdr) = @_;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( (!$hdr) || ref($hdr) eq 'ARRAY' ), if DEBUG;

  $self->[HEADER];
}

# sub prev {
#   my ($self, $prev) = @_;
# #   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
# #   assert( UNIVERSAL::isa($prev, __PACKAGE__) ), if DEBUG;
#   return (@_ > 1) ? ( $self->[PREV] = $prev ) : $self->[PREV];
# }

sub level {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  scalar( @{$self->[HEADER]} );
}

sub validate_key {
#   my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  1;
}

sub key {
  my ($self, $key) = @_;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( (@_==1) || $self->validate_key( $key ) ), if DEBUG;

  $self->[KEY];
}

sub key_cmp {
  my ($self, $right) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

#   assert( $self->validate_key( $right ) ), if DEBUG;

  # OPT: It would be nice to use $self->key instead of $self->[KEY],
  # but we gain a nearly 25% speed improvement!

  ($self->[KEY] cmp $right);
}

sub validate_value {
#   my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  1;
}

sub value {
  my ($self, $value) = @_;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( (@_==1) || $self->validate_value( $value ) ), if DEBUG;

  (@_ > 1) ? ( $self->[VALUE] = $value ) : $self->[VALUE];
}


1;

__END__

=head1 NAME

Algorithm::SkipList::Node - node class for Algorithm::SkipList

=head1 REQUIREMENTS

The following non-standard modules are used:

  enum

Carp::Assert is no longer required.  However, the assertions can be
uncommented for debugging.

=head1 DESCRIPTION

Methods are documented below.

=over

=item new

  $node = new Algorithm::SkipList::Node( $key, $value, $header );

Creates a new node for the list.  The parameters are optional.

Note that the versions 0.42 and earlier used a different calling
convention.

=item key

  $key = $node->key;

Returns the key.

Note that as of version 0.70, this method is read-only.  We should not
change the key once a node has been added to the list.

=item key_cmp

  if ($node->key_cmp( $key ) != 0) { ... }

Compares the node key with the parameter. Equivalent to using

  if (($node->key cmp $key) != 0)) { ... }

without the need to deal with the node key being C<undef>.

By default the comparison is a string comparison.  If you need a
different form of comparison, use a
L<custom node class|/"Customizing the Node Class">.

=item validate_key

  if ($node->validate_key( $key )) { ... }

Deprecated method used to determine is a key is valid.

By default this is a dummy routine that is only called when assertions
are enabled.

=item value

  $value = $node->value;

Returns the value of a node.

  $node->value( $value );

When used with an argument, sets the value.

=item validate_value

  if ($node->validate_value( $value )) { ... }

Deprecated method used to determine is a value is valid.

By default this is a dummy routine that is only called when assertions
are enabled.

=item header

  $header_ref = $node->header;

Returns the forward list array of the node. This is an array of nodes
which point to the node returned, where each index in the array refers
to the level.

Note that as of L<List::SkipList> version 0.70, this method is
read-only.  Since it only returns header references (as of version
0.50), that reference can be used to modify forward pointers.

=item level

  $levels = $node->level;

Returns the number of levels in the node.

=back

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
