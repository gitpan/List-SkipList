package List::SkipList::Node;

use strict;
use warnings;

use Carp;
use Carp::Assert;

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
  assert( ref($self) eq "List::SkipList::Node" ), if DEBUG;

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
  assert( ref($self) eq "List::SkipList::Node" ), if DEBUG;
  return scalar @{$self->header()};
}

sub forward
  {
    my $self = shift;
    assert( ref($self) eq "List::SkipList::Node" ), if DEBUG;

    my $level = shift;
    assert (($level >= 0) ), if DEBUG;

    my $hdr = $self->header;

    if (@_) {
      my $next = shift;
      assert( !defined($next) || (ref($next) eq "List::SkipList::Node") ), if DEBUG;

      $hdr->[$level] = $next;
      $self->header( $hdr );

    } else {
      return $hdr->[$level];
    }

  }

sub key {
  my $self = shift;
  assert( ref($self) eq "List::SkipList::Node" ), if DEBUG;

  if (@_) {
    $self->{KEY} = shift;
    carp "Extra arguments ignored", if (@_);
  } else {
    return $self->{KEY};
  }
}

sub key_cmp {
  my $self = shift;
  assert( ref($self) eq "List::SkipList::Node" ), if DEBUG;

  my $left  = $self->key;
  my $right = shift;

  unless (defined $left) { return -1; }

  return ($left cmp $right);
}

sub value {
  my $self = shift;
  assert( ref($self) eq "List::SkipList::Node" ), if DEBUG;

  if (@_) {
    $self->{VALUE} = shift;
    carp "Extra arguments ignored", if (@_);
  } else {
    return $self->{VALUE};
  }
}

# Note: We no longer need the is_nil() method, which has a dubious
#       purpose anyway.

# sub is_nil {
#   my $self = shift;
#   assert( ref($self) eq "List::SkipList::Node" ), if DEBUG;
# 
#   my $level = $self->level;
#   my $hdr   = $self->header;
# 
#   while ($level--) {
#     if (defined $hdr->[$level]) {
#       return; }
#   }
# 
#   return -1;
# }

package List::SkipList;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp;
use Carp::Assert;

use constant MAX_LEVEL => 32;
use constant DEF_P     => 0.5;

sub new {
  no integer;

  my $class = shift;


  my $self = {
    LIST     => undef,
    SIZE     => undef,
    MAXLEVEL => MAX_LEVEL,
    P        => DEF_P,
  };

  bless $self, $class;

  {
    my %ARGLIST = ( map { $_ => 1 } qw( max_level p ) );
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

sub clear {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

  $self->{LIST} = undef;

  my $list = new List::SkipList::Node( header => [
     map { undef } (1..$self->random_level)] );

  assert( ref($list) eq "List::SkipList::Node" ), if DEBUG;

  $self->{LIST} = $list;
  $self->{SIZE} = 0;
}

sub _set_max_level {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;
  my $level = shift;
  assert( ($level>1) ), if DEBUG;
  $self->{MAXLEVEL} = $level;
}

sub max_level {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;
  return $self->{MAXLEVEL};
}

sub _set_p {
  no integer;

  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

  my $p = shift;
  assert( ($p>0) && ($p<1) ), if DEBUG;

  $self->{P} = $p;
}

sub p {
  no integer;

  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;
  return $self->{P};
}

sub size {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;
  return $self->{SIZE};
}

sub list {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;
  return $self->{LIST};
}

sub level {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;
  return $self->list->level;
}


sub random_level {
  no integer;

  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

  my $level = 1;

  while ( (rand() < $self->p) && ($level < $self->max_level) ) {
    $level ++; }

  assert( ($level >= 1) && ($level <= $self->max_level) ), if DEBUG;

  return $level;
}


sub _search {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

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

  assert( ref($x) eq "List::SkipList::Node" ), if DEBUG;

  return ($x, \@update);
}

sub insert {
  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

  my $list   = $self->list;

  my $key    = shift;
  my $value  = shift;

  {

    my ($x, $update_ref) = $self->_search($key);

    if ($x->key_cmp($key) == 0) {
      $x->value($value);
    } else {

      my $new_level = $self->random_level;

      if ($new_level > $list->level) {

	for (my $i=$list->level; $i<$new_level; $i++) {
	  $update_ref->[$i] = $list;
	}
      }

      my $node = new List::SkipList::Node( key => $key, value => $value );

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
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

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
	assert( ref($y) eq "List::SkipList::Node" ), if DEBUG;
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
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

  my $key  = shift;

  my ($x, $update_ref) = $self->_search($key);

  return ($x->key_cmp($key) == 0);
}

sub find {

  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

  my $key  = shift;

  my ($x, $update_ref) = $self->_search($key);

  if ($x->key_cmp($key) == 0) {
    return $x->value;
  } else {
    return;
  }
}


sub debug {

  my $self = shift;
  assert( ref($self) eq "List::SkipList" ), if DEBUG;

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


1;
__END__

=head1 NAME

List::SkipList - Perl implementation of skip lists

=head1 SYNOPSIS

  my $list = new List::SkipList();

  $list->insert( 'key1', 'value' );
  $list->insert( 'key2', 'another value' );

  $value = $list->find('key2');

  $list->delete('key1');

=head1 DESCRIPTION

This is a prototype implementation of skip lists in Perl.  Skip lists are
similar to linked lists, except that they have random links at various
levels that allow searches to skip over sections of the list.  They
generally perform as well as balanced trees for searching but do not
have the overhead with respect to inserting new items.

For more information on skip lists, see the L<SEE ALSO> section below.

=head2 Methods

A detailed description of the methods used is below.

=over

=item new

  $list = new SkipList( max_level => 32 );

Creates a new skip list.  C<max_level> will default to C<32> if it is
not specified.  It is generally a good idea to leave this value alone
unless you are using small lists.

The initial list (see the L<list> method) will be a L<random|random_level>
number of levels, and will increase over time if inserted nodes have higher
levels.

You can also control the probability used to determine level sizes by
setting the L<P|p> value:

  $list = new SkipList( p => 0.5 );

The value defaults to C<0.5>.

For more information on what these values mean, consult the references
below in the L<SEE ALSO> section.

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

Internal methods are documented below.  These may change.

=over

=item p

  $plevel = $list->p;

Returns the I<P> value.  Intended for internal use only.

=item max_level

  $max = $list->max_level;

Returns the maximum level that C<random_level> can generate.

=item random_level

  $level = $list->random_level;

This is an internal function for generating a random level for new nodes.

Levels are determined by the L<P|p> value.  The probability that a
node will have 1 level is I<P>; the probability that a node will have
2 levels is I<P^2>; the probability that a node will have 3 levels is
I<P^3>, et cetera.

The value will never be greater than C<max_level>.

=item list

  $node = $list->list;

Returns the initial node in the list, which is a L<List::SkipList::Node|Internal Methods>.

The key and value for this node are undefined.

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

=item value

  $value = $node->value;

Returns the node's value.

  $node->value( $value );

When used with an argument, sets the node's value.

=item header

  @header = $node->header;

  $header_ref = $node->header;

Returns the forward list (see C<forward>) array of the node.

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
