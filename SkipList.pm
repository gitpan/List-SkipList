package List::SkipList::Node;

use strict;
use warnings;

use Carp;
use Carp::Assert;

# List::SkipList::Node version is 0.03 - we cannot define it here
# because MakeMaker gets confused and pulls the first version
# definition string it sees

sub new {
  my $class = shift;
  my $self  = {
    HEADER => [ ],
    KEY    => undef,
    VALUE  => undef,
  };
  bless $self, $class;

  {
    my %ARGLIST = ( map { $_ => 1 } qw( key value header ) );
    my %args = @_;
    foreach my $arg_name (keys %args) {
      if ($ARGLIST{$arg_name}) {
	$self->$arg_name( $args{ $arg_name } );
      } else {
	croak "Invalid parameter name: ``$arg_name\'\'";
      }
    }
  }

  return $self;
}

sub header {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  if (@_) {
    if (ref($_[0]) eq "ARRAY") {
      $self->{HEADER} = shift;
      carp "Extra arguments ignored", if (@_);
    } else {
      my @new_hdr = @_;
      $self->{HEADER} = \@new_hdr;
    }
  } else {
    return wantarray ? @{$self->{HEADER}} : $self->{HEADER};
  }
}

sub level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;
  return scalar @{$self->header()};
}

sub forward
  {
    my $self = shift;
    assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

    my $level = shift;
    assert (($level >= 0) ), if DEBUG;

    my $hdr = $self->header;

    if (@_) {
      my $next = shift;
      assert( !defined($next) ||
	      UNIVERSAL::isa($next, "List::SkipList::Node") ), if DEBUG;

      $hdr->[$level] = $next;
      $self->header( $hdr );

    } else {
      return $hdr->[$level];
    }

  }

sub validate_key {
#    my $self = shift;
#    assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;
  return 1;
}

sub key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  if (@_) {
    my $key = shift;
    assert( $self->validate_key( $key ) ), if DEBUG;
    $self->{KEY} = $key;
    carp "Extra arguments ignored", if (@_);
  } else {
    return $self->{KEY};
  }
}

sub key_cmp {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  my $left  = $self->key;
  my $right = shift;

  assert( $self->validate_key( $right ) ), if DEBUG;
  unless (defined $left) { return -1; }

  return ($left cmp $right);
}

sub validate_value {
#    my $self = shift;
#    assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;
  return 1;
}

sub value {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

  if (@_) {
    my $value = shift;
    assert( $self->validate_value( $value ) ), if DEBUG;
    $self->{VALUE} = $value;
    carp "Extra arguments ignored", if (@_);
  } else {
    return $self->{VALUE};
  }
}

package List::SkipList;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.13';

use Carp;
use Carp::Assert;

use constant MAX_LEVEL => 32;
use constant DEF_P     => 0.5;

sub new {
  no integer;

  my $class = shift;


  my $self = {
    NODECLASS => 'List::SkipList::Node',
    LIST      => undef,
    SIZE      => undef,
    MAXLEVEL  => MAX_LEVEL,
    P         => DEF_P,
  };

  bless $self, $class;

  {
    my %ARGLIST = ( map { $_ => 1 } qw( max_level p node_class ) );
    my %args = @_;
    foreach my $arg_name (keys %args) {
      if ($ARGLIST{$arg_name}) {
	my $method = "_set_" . $arg_name;
	$self->$method( $args{ $arg_name } );
      } else {
	croak "Invalid parameter name: ``$arg_name\'\'";
      }
    }
  }

  $self->clear;

  return $self;
}

sub _set_node_class {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
  my $node_class = shift;
  $self->{NODECLASS} = $node_class;
}

sub _node_class
  {
    my $self = shift;
    assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
    return $self->{NODECLASS};
  }

sub clear {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  $self->{LIST} = undef;

  my $list = $self->_node_class->new ( header => [
     map { undef } (1..$self->_random_level)] );

  assert( UNIVERSAL::isa($list, "List::SkipList::Node") ), if DEBUG;

  $self->{LIST} = $list;
  $self->{SIZE} = 0;
}

sub _set_max_level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
  my $level = shift;
  assert( ($level>1) ), if DEBUG;
  $self->{MAXLEVEL} = $level;
}

sub max_level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
  return $self->{MAXLEVEL};
}

sub _set_p {
  no integer;

  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $p = shift;
  assert( ($p>0) && ($p<1) ), if DEBUG;

  $self->{P} = $p;
}

sub p {
  no integer;

  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
  return $self->{P};
}

sub size {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
  return $self->{SIZE};
}

sub list {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
  return $self->{LIST};
}

sub level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;
  return $self->list->level;
}


sub _random_level {
  no integer;

  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $level = 1;

  while ( (rand() < $self->p) && ($level < $self->max_level) ) {
    $level ++; }

  assert( ($level >= 1) && ($level <= $self->max_level) ), if DEBUG;

  return $level;
}


sub _search {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $list = $self->list;

  my $key  = shift;

  my $x = $list;
  my @update = map { $list } (1..$list->level);

  my $level     = $list->level-1;

  do {

    $update[$level] = $x;

    if ((!defined $x->forward($level)) ||
	($x->forward($level)->key_cmp($key) > 0)) {

      if ($level >= 0) { $level--; }

    } else {
      if ($x->forward($level)->key_cmp($key) <= 0) {
	$x = $x->forward($level);	
      }
    }

  } while (($level>=0) && ($x->key_cmp($key) != 0));

  assert( UNIVERSAL::isa($x, "List::SkipList::Node") ), if DEBUG;

  return ($x, \@update);
}

sub insert {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $list   = $self->list;

  my $key    = shift;
  my $value  = shift;

  {

    my ($x, $update_ref) = $self->_search($key);

    if ($x->key_cmp($key) == 0) {
      $x->value($value);
    } else {

      my $new_level = $self->_random_level;

      if ($new_level > $list->level) {

	for (my $i=$list->level; $i<$new_level; $i++) {
	  $update_ref->[$i] = $list;
	}
      }

      my $node = $self->_node_class->new( key => $key, value => $value );

      for (my $i=0;$i<$new_level;$i++) {

	if (defined $update_ref->[$i]->forward($i)) {
	  $node->forward($i, $update_ref->[$i]->forward($i) );
	} else {
	  $node->forward($i, undef);
	}
	  
	$update_ref->[$i]->forward($i,$node);
      }

      $self->{SIZE}++;
    }

  }

}

sub delete {

  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $key  = shift;
  assert( defined $key ), if DEBUG;

  my ($x, $update_ref) = $self->_search($key);

  if ($x->key_cmp($key) == 0) {
    my $value = $x->value;

    my $level = $x->level; 
    assert($level <= @{$update_ref}), if DEBUG;

    for (my $i=0; $i<$level; $i++) {

      my $y = $update_ref->[$i];
      while ($y->forward($i) != $x) {
	$y = $y->forward($i);
	assert( UNIVERSAL::isa($y, "List::SkipList::Node") ), if DEBUG;
      }
      $y->forward($i, $x->forward($i));
 
    }

    $self->{SIZE} --;

    undef $x;
    return $value;

  } else {
    return;
  }
}

sub exists {

  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $key  = shift;

  my ($x, $update_ref) = $self->_search($key);

  return ($x->key_cmp($key) == 0);
}

sub find {

  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $key  = shift;

  my ($x, $update_ref) = $self->_search($key);

  if ($x->key_cmp($key) == 0) {
    return $x->value;
  } else {
    return;
  }
}

sub first_key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $list = $self->list;
  if (defined $list->forward(0)) {
    return $list->forward(0)->key;
  } else {
    return;
  }
}

sub next_key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $last_key = shift;
  if (defined $last_key) {
    my ($list, $update_ref) = $self->_search($last_key);
    if ($list->key_cmp($last_key) == 0) {
      if (defined $list->forward(0)) {
	return $list->forward(0)->key;
      } else {
	return;
      }
    } else {
      return;
    }
  } else {
    return;
  }
}

1;

__END__


sub debug {

  my $self = shift;
  assert( UNIVERSAL::isa($self, "List::SkipList") ), if DEBUG;

  my $list   = $self->list;

  while (defined $list) {
    print $list->key||'undef', "=", $list->value||'undef'," ", $list,"\n";

    for(my $i=0; $i<$list->level; $i++) {
      print " ", $i," ", $list->forward($i) || 'undef', "\n";
    }
    print "\n";

    $list = $list->forward(0);
  }

}

=head1 NAME

List::SkipList - Perl implementation of skip lists

=head1 REQUIREMENTS

C<Carp::Assert> is used for validation and debugging. (The assertions
can be commented out if the module cannot be installed.)  Otherwise
standard modules are used.

=head2 Installation

Installation is pretty standard:

  perl Makefile.PL
  make
  make test
  make install

=head1 SYNOPSIS

  my $list = new List::SkipList();

  $list->insert( 'key1', 'value' );
  $list->insert( 'key2', 'another value' );

  $value = $list->find('key2');

  $list->delete('key1');

=head1 DESCRIPTION

This is a prototype implementation of I<skip lists> in Perl.  Skip
lists are similar to linked lists, except that they have random links
at various I<levels> that allow searches to skip over sections of the
list, like so:

  4 +---------------------------> +----------------------> +
    |                             |                        |
  3 +------------> +------------> +-------> +-------> +--> +
    |              |              |         |         |    |
  2 +-------> +--> +-------> +--> +--> +--> +-------> +--> +
    |         |    |         |    |    |    |         |    |
  1 +--> +--> +--> +--> +--> +--> +--> +--> +--> +--> +--> +
         A    B    C    D    E    F    G    H    I    J   NIL

A search would start at the top level: if the link to the right
exceeds the target key, then it descends a level.

Skip lists generally perform as well as balanced trees for searching
but do not have the overhead with respect to inserting new items.

For more information on skip lists, see the L<SEE ALSO> section below.

=head2 Methods

A detailed description of the methods used is below.

=over

=item new

  $list = new SkipList( max_level => 32 );

Creates a new skip list.  C<max_level> will default to C<32> if it is
not specified.  It is generally a good idea to leave this value alone
unless you are using small lists.

The initial list (see the L<list> method) will be a L<random|_random_level>
number of levels, and will increase over time if inserted nodes have higher
levels.

You can also control the probability used to determine level sizes by
setting the L<P|p> value:

  $list = new SkipList( p => 0.5 );

The value defaults to C<0.5>.

For more information on what these values mean, consult the references
below in the L<SEE ALSO> section.

If you need to use a different L<node class|Node Methods> for using
customized L<comparison|key_cmp> routines, you will need to specify a
different class:

  $list = new SkipList( node_class => 'MyNodeClass' );

See the L<Customizing the Node Class> section below.

=item insert

  $list->insert( $key, $value );

Inserts a new node into the list.

=item exists

  if ($list->exists( $key )) { ... }

Returns true if there exists a node associated with the key, false
otherwise.

=item find

  $value = $list->find( $key );

Searches for the node associated with the key, and returns the value. If
the key cannot be found, returns C<undef>.

=item first_key

  $key = $list->first_key;

Returns the first key in the list.

=item next_key

  $key = $list->next_key( $last_key );

Returns the key following the previous key.

=item delete

  $value = $list->delete( $key );

Deletes the node associated with the key, and returns the value.  If
the key cannot be found, returns C<undef>.

=item clear

  $list->clear;

Erases existing nodes and resets the list.

=item size

  $size = $list->size;

Returns the number of nodes in the list.

=back


=head2 Internal Methods

Internal methods are documented below. These are intended for
developer use only.  These may change in future versions.

=over

=item _search

  ($node, $header_ref) = $list->_search( $key );

Searches for the node with a key.  If the key is found, that node is
returned along with a L<header>.  If the key is not found, the previous
node from where the node would be if it existed is returned.

=item p

  $plevel = $list->p;

Returns the I<P> value.  Intended for internal use only.

=item max_level

  $max = $list->max_level;

Returns the maximum level that C<_random_level> can generate.

=item _random_level

  $level = $list->_random_level;

This is an internal function for generating a random level for new nodes.

Levels are determined by the L<P|p> value.  The probability that a
node will have 1 level is I<P>; the probability that a node will have
2 levels is I<P^2>; the probability that a node will have 3 levels is
I<P^3>, et cetera.

The value will never be greater than C<max_level>.

=item list

  $node = $list->list;

Returns the initial node in the list, which is a
L<List::SkipList::Node> (See L<below|Node Methods>.)

The key and value for this node are undefined.

=item _node_class

  $node_class_name = $list->_node_class;

Returns the name of the node class used.  By default this is the
C<List::SkipList::Node>, which is discussed below.

=item _set_node_class

=item _set_max_level

=item _set_p

These methods are used only during initialization of the object.
I<Do not call these methods after the object has been created!>

=back

=head2 Node Methods

Methods for the C<List::SkipList::Node> object are listed below.  They
are for internal use by the main C<Lists::SkipList> module.

=over

=item new

  $node = new List::SkipList::Node( key => $key, value => $value,
                                    header => \@header );

Creates a new node for the list.  The parameters are optional.

=item key

  $key = $node->key;

Returns the node's key.

  $node->key( $key );

When used with an argument, sets the node's key.

=item key_cmp

  if ($node->key_cmp( $key ) != 0) { ... }

Compares the node key with the parameter. Equivalent to using

  if (($node->key cmp $key) != 0)) { ... }

without the need to deal with the node key being C<undef>.

By default the comparison is a string comparison.  If you need a
different form of comparison, use a
L<custom node class|Customizing the Node Class>.

=item validate_key

  if ($node->validate_key( $key )) { ... }

Used by L<value> to validate that a key is valid.  Returns true if it
is ok, false otherwise.

By default this is a dummy routine.  Redefine it to validate keys if
you need it when L<Customizing the Node Class>.

=item value

  $value = $node->value;

Returns the node's value.

  $node->value( $value );

When used with an argument, sets the node's value.

=item validate_value

  if ($node->validate_value( $value )) { ... }

Used by L<value> to validate that value is valid.  Returns true if it
is ok, false otherwise.

By default this is a dummy routine.  Redefine it to validate values if
you need it when L<Customizing the Node Class>.

=item header

  @header = $node->header;

  $header_ref = $node->header;

Returns the forward list (see C<forward>) array of the node. This is
an array of nodes which point to the node returned, where each index
in the array refers to the level.  That is,

  $header[$i] == $list->forward($i)

Where C<$i> is between 0 and C<level>.

  $node->header( @header );

  $node->header( $header_ref );

When used with an argument, sets the forward list.  Unlike the
C<forward> method, it does not check if list elements are of the
correct type.

=item forward

  $next = $node->forward( $level );

Returns the next node associated with the level.

  $node->forward( $level, $next );

Sets the next node associated with the level.

=item level

  $levels = $node->level;

Returns the number of levels in the node.

=back

=head2 Customizing the Node Class

The default node may not handle specialized data types.  To define
your own custom class, you need to derive a child class from
C<List::SkipList::Node>.

Below is an example of a node which redefines the default type to use
numeric instead of string comparisons:

  package NumericNode;

  use Carp::Assert; # this is required since the parent uses this

  our @ISA = qw( List::SkipList::Node );

  sub key_cmp {
    my $self = shift;
    assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

    my $left  = $self->key;  # node key
    my $right = shift;       # value to compare the node key with

    # We should gracefully handle $left being undefined
    unless (defined $left) { return -1; }

    return ($left <=> $right);
  }

  sub validate_key {
    my $self = shift;
    assert( UNIVERSAL::isa($self, "List::SkipList::Node") ), if DEBUG;

    my $key = shift;
    return ($key =~ s/\-?\d+(\.\d+)?$/); # test if key is numeric
  }

To use this, we say simply

  $number_list = new List::SkipList( node_class => 'NumericNode' );

The skip list should work normally, except that the keys must be
numbers.

=head1 TODO

The following features may be added in future versions:

=over

=item Searching with "Fingers"

=item Merging Lists

=item Splitting Lists

=item Cloning

=back

=head1 CAVEATS

This is a prototype module and may contain bugs.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head2 Acknowledgements

Carl Shapiro <cshapiro@panix.com> for introduction to skip lists.

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2003 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See the article I<A Skip List Cookbook> (William Pugh, 1989), or
similar ones by the author at L<http://www.cs.umd.edu/~pugh/> which
discuss skip lists.

This module intentionally has a superficial subset of the interface in
the L<Tree:Base> module, since skip lists can be used instead of
trees.

=cut
