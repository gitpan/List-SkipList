package List::SkipList::Node;

use 5.006;
use strict;
use warnings;

use Carp qw(carp croak);
no Carp::Assert;

our $VERSION
 = '1.00_1';

use constant NODEARGLIST => {
  key    => 1,
  value  => 1,
  header => 1,
};

use constant HEADER => 0;
use constant LEVEL  => 1;
use constant KEY    => 2;
use constant VALUE  => 3;

sub new {
  my $class = shift;
  my $self  = [ ];
     $self->[HEADER] = [ ];
     $self->[LEVEL]  = 0;
     $self->[KEY]    = undef;
     $self->[VALUE]  = undef;

  bless $self, $class;

  {
    my %args = @_;

    if (DEBUG) {
      foreach my $arg_name (CORE::keys %args) {
	if (NODEARGLIST->{$arg_name}) {
	  $self->$arg_name( $args{ $arg_name } );
	} else {
	  croak "Invalid parameter name: ``$arg_name\'\'";
	}
      }
    } else {

      # It's better to hard-code these in here and ignore invalid
      # arguments for the speed improvement!

      $self->key(    $args{key}    );
      $self->value(  $args{value}  );
      $self->header( $args{header} );
    }
  }

  return $self;
}

sub header {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  if (@_) {
    if (ref($_[0]) eq "ARRAY") {
      $self->[HEADER] = shift;
#      carp "Extra arguments ignored", if (@_);
    } else {
      $self->[HEADER] = \ @_;
    }
    $self->[LEVEL] = scalar @{ $self->[HEADER] };
  } else {
    return wantarray ? @{$self->[HEADER]} : $self->[HEADER];
  }
}

sub level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#  return scalar @{$self->[HEADER]};
  return $self->[LEVEL];
}

sub forward
  {
    my $self = shift;
    assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

    my $level = shift;
    assert (($level >= 0) ), if DEBUG;

    if (@_) {
      my $next = shift;

      assert( (!defined $next) || UNIVERSAL::isa($next, __PACKAGE__) ),
	if DEBUG;

      $self->[HEADER]->[$level] = $next;
      if ($level >= $self->[LEVEL]) {
	$self->[LEVEL] = 1+$level;
      }
    } else {
      return $self->[HEADER]->[$level];
    }

  }

sub validate_key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  return 1;
}

sub key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  if (@_) {
    my $key = shift;
    assert( $self->validate_key( $key ) ), if DEBUG;
    $self->[KEY] = $key;
#    carp "Extra arguments ignored", if (@_);
  } else {
    return $self->[KEY];
  }
}

sub key_cmp {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $left  = $self->key;
  my $right = shift;

  assert( $self->validate_key( $right ) ), if DEBUG;
#  unless (defined $left) { return -1; } # we don't need this

  return ($left cmp $right);
}

sub validate_value {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  return 1;
}

sub value {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  if (@_) {
    my $value = shift;
    assert( $self->validate_value( $value ) ), if DEBUG;
    $self->[VALUE] = $value;
#    carp "Extra arguments ignored", if (@_);
  } else {
    return $self->[VALUE];
  }
}

package List::SkipList;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.41';

use AutoLoader qw( AUTOLOAD );
use Carp qw( carp croak );
no Carp::Assert;

use constant MAX_LEVEL       => 32;
use constant DEF_P           => 0.5;

use constant BASE_NODE_CLASS => 'List::SkipList::Node';

use constant ARGLIST => {
  max_level  => 1,
  p          => 1,
  node_class => 1,
};

# Caching the "finger" for the last insert allows sequential (sorted)
# inserts to be sped up.  It does not seem to affect the performance
# of non-sequential inserts.

use constant CACHE_INSERT_FINGERS => 1;

sub new {
  no integer;

  my $class = shift;

  my $self = {
    NODECLASS => BASE_NODE_CLASS,
    LIST      => undef,
    SIZE      => undef,
    MAXLEVEL  => MAX_LEVEL,
    P         => 0,
    P_LEVELS  => [ ],
    LASTNODE  => undef,                 # node with greatest key
    LASTKEY   => undef,                 # last key used by next_key
    LASTINSRT => undef,                 # used by CACHE_INSERTION_FINGERS
  };

  bless $self, $class;

  $self->_set_p( DEF_P ); # initializes P_LEVELS

  {
    my %args = @_;
    foreach my $arg_name (CORE::keys %args) {
      if (ARGLIST->{$arg_name}) {
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
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  my $node_class = shift;
  $self->{NODECLASS} = $node_class;
}

sub _node_class
  {
    my $self = shift;
    assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
    return $self->{NODECLASS};
  }

sub reset {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $self->{LASTKEY}  = undef;
}

sub clear {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  $self->{LIST} = undef;

  my $list = $self->_node_class->new ( header => [
     map { undef } (1..$self->_random_level)] );

  assert( UNIVERSAL::isa($list, BASE_NODE_CLASS) ), if DEBUG;

  $self->{LIST}     = $list;
  $self->{SIZE}     = 0;
  $self->{LASTNODE} = undef;

  $self->reset;
}

sub _set_max_level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  my $level = shift;
  assert( ($level>1) ), if DEBUG;
  $self->{MAXLEVEL} = $level;
}

sub max_level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  return $self->{MAXLEVEL};
}

sub _set_p {
  no integer;

  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $p = shift;
  assert( ($p>0) && ($p<1) ), if DEBUG;

  $self->{P} = $p;

  # Because configuration is via hash, we may not set a new max_level
  # before setting P, so we set to the standard MAX_LEVEL if it is
  # greater.  Possible bug is if max_level is greater than MAX_LEVEL
  # but is set after P.

  my $n     = 1;
  my $level = 0;
  my $max   = (MAX_LEVEL > $self->max_level) ? MAX_LEVEL : $self->max_level;

  $self->{P_LEVELS} = [ ]; 

  while ($level <= $max) {
    assert( $self->{P_LEVELS}->[$level-1] > $self->{P_LEVELS}->[$level] ),
      if DEBUG;
    $self->{P_LEVELS}->[$level++] = $n;
    $n *= $p;
  }
}

sub p {
  no integer;

  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  return $self->{P};
}

sub size {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  return $self->{SIZE};
}

sub list {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  return $self->{LIST};
}

sub level {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  return $self->list->level;
}


sub _random_level {
  no integer;

  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $n     = rand();
  my $max   = $self->max_level;
  my $level = 1;

  while ( ($level < $max) && ($n < $self->{P_LEVELS}->[$level]) ) {
    $level++;
  }

  assert( ($level >= 1) && ($level <= $max) ), if DEBUG;
  return $level;
}

sub _search {
  my $self   = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list   = $self->list;
  my $level  = $list->level-1;

  my $key    = shift;

  my $finger = shift || [map { $list } (0..$level)];
  assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;

  my $x      = $finger->[ $level ] || $list;

  # Iteresting Perl syntax quirk:
  #   do { my $x = ... } while ($x)
  # doesn't work because it considers $x out of scope.

  my $cmp = 0;

  do {
    my $fwd = $x->forward($level);
       $cmp = (defined $fwd) ? $fwd->key_cmp($key) : 1; 
    if ($cmp > 0) {
      if ($level >= 0) {
	$finger->[$level] = $x;
	$level--;
      }
    } else {
      $finger->[$level] = $x;
      $x = $fwd;
    }
  } while (($level>=0) && ($cmp != 0));

  assert( UNIVERSAL::isa($x, BASE_NODE_CLASS) ), if DEBUG;

  return ($x, $finger, $cmp);
}

sub insert {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list   = $self->list;

  my ($key, $value, $finger) = @_;

  # We save the node and finger of the last insertion. If the next key
  # is larger, then we can use the "finger" to speed up insertions.

  if (defined $finger) {
    assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
  } elsif (defined $self->{LASTINSRT}) {
    if (CACHE_INSERT_FINGERS) {
      my ($node, $ref) = @{ $self->{LASTINSRT} };
    
      if ($node->key_cmp($key) < 0) {
	$finger = $ref;
      }
    }
  }

  my ($x, $update_ref, $cmp) = $self->_search($key, $finger);    

  if ($cmp == 0) {
    $x->value($value);
    $self->{LASTINSRT} = [$x, $update_ref],
      if (CACHE_INSERT_FINGERS);
  } else {

    my $new_level = $self->_random_level;

    # We limit $new_level to no more than 1+$list-level. The speed
    # improvement is quite noticeable.

    if ($new_level > $list->level) {
      $new_level  = 1 + $list->level;
      $update_ref->[ $list->level ] = $list;
    }

    my $node = $self->_node_class->new( key => $key, value => $value );

    for (my $i=$new_level-1;$i>=0;$i--) {
      $node->forward($i, $update_ref->[$i]->forward($i) );	  
      $update_ref->[$i]->forward($i,$node);
    }

    $self->{LASTNODE} = $node,
      unless (defined $node->forward(0));

    $self->{LASTINSRT} = [$node, $update_ref],
      if (CACHE_INSERT_FINGERS);

    $self->{SIZE}++;
  }
  return $update_ref;
}

sub delete {

  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $key  = shift;
  assert( defined $key ), if DEBUG;

  my $finger = shift;

  if (defined $finger) {
    assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
  }

  my ($x, $update_ref, $cmp) = $self->_search($key, $finger);

  if ($cmp == 0) {
    my $value = $x->value;

    my $level = $x->level; 
    assert($level <= @{$update_ref}), if DEBUG;

    for (my $i=$level-1; $i>=0; $i--) {

      my $y   = $update_ref->[$i];

      # The top level of the finger points to the current node. The
      # lower levels should be set to that node if they point to the
      # start of the list.

      if ($y == $self->list) { $y = $update_ref->[$level-1]; }

      while ((my $fwd=$y->forward($i)) != $x) {
	$y = $fwd;
	assert( UNIVERSAL::isa($y, BASE_NODE_CLASS) ), if DEBUG;
      }
      $y->forward($i, $x->forward($i)); 

    }

    # There's probably a smarter way to handle this, but this is the
    # safest way.

    $self->{LASTINSRT} = undef,
      if (CACHE_INSERT_FINGERS);

    $self->{SIZE} --;

    undef $x;

    # it doesn't seem to be a wise idea to return a search finger for
    # deletions without further analysis

    return $value;

  } else {
    return;
  }
}

sub exists {

  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $key    = shift;
  my $finger = shift;

  if (defined $finger) {
    assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
  }

  my ($x, $new_finger, $cmp) =  $self->_search($key, $finger);
  return ($cmp == 0);
}

sub find {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $key    = shift;
  my $finger = shift;

  if (defined $finger) {
    assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
  }

  my ($x, $update_ref, $cmp) = $self->_search($key, $finger);

  if ($cmp == 0) {
    return (wantarray)? ($x->value, $update_ref) : $x->value;
  } else {
    return;
  }
}

sub last_key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  if (defined $self->{LASTKEY}) {
    return (wantarray) ?
      @{$self->{LASTKEY}} : $self->{LASTKEY}->[0];
  } else {
    return;
  }
}

sub first_key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list = $self->list;
  my $fwd  = $list->forward(0);
  if (defined $fwd) {
    $self->{LASTKEY} =
      [$fwd->key, [map { $list } (1..$list->level)] ];
    return $self->last_key;
  } else {
    return;
  }
}

sub next_key {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $last_key = shift;
  my $finger   = shift;

  unless (defined $last_key) {
    ($last_key, $finger) = @{$self->{LASTKEY}};
  }

  if (defined $finger) {
    assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
  }

  if (defined $last_key) {
    my ($list, $update_ref, $cmp) = $self->_search($last_key, $finger);

    my $fwd  = $list->forward(0);
 
    if ($cmp == 0) {
      if (defined $fwd) {
	$self->{LASTKEY} = [$fwd->key, $update_ref];
	$self->last_key;
      } else {
	return;
      }
    } else {
      return;
    }
  } else {
    return $self->first_key;
  }
}

# We could add the ability to tie hashes to skip lists, but it would
# complicate how the autoloading features are set up.  So this might
# be implemented in another module.

BEGIN
  {
    # make aliases to methods...
    no strict;
    *TIEHASH = \&new;
    *STORE   = \&insert;
    *FETCH   = \&find;
    *EXISTS  = \&exists;
    *CLEAR   = \&clear;
    *DELETE  = \&delete;
    *FIRSTKEY = \&first_key;
    *NEXTKEY = \&next_key;

    *search  = \&find;
  }

1;

__END__

sub _first_node { # actually this is the second node
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list = $self->list;
  my $fwd  = $list->forward(0);
  if (defined $fwd) {
    return ($fwd, scalar $list->header);
  } else {
    return;
  }
}

sub least {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my ($node, $finger) = $self->_first_node;

  if (defined $node) {
    return ($node->key, $node->value);
  } else {
    return;
  }
}

sub greatest {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $node = $self->{LASTNODE};
  if (defined $node) {
    return ($node->key, $node->value);
  } else {
    return;
  }
}

sub next {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  die "unimplemented method";
}

sub keys {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my @keys = ();

  my ($key, $finger) = $self->first_key;

  while (defined $key) {
    push @keys, $key;
    $key = $self->next_key($key, $finger);
  }

  return @keys;
}

sub values {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my @values = ();

  my ($key, $finger) = $self->first_key;

  while (defined $key) {
    push @values, scalar $self->find($key, $finger);
    ($key, $finger) = $self->next_key($key, $finger);
  }

  return @values;
}

sub copy {
  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list = new List::SkipList(
    max_level  => $self->max_level,
    p          => $self->p,
    node_class => $self->_node_class,
  );

  my ($key, $finger_or) = $self->first_key();
  my $value;
  my $finger_cp = undef;

  do {
    ($value, $finger_or) = $self->find($key, $finger_or);
    my $finger_cp        = $list->insert($key, $value, $finger_cp);
    ($key, $finger_or)   = $self->next_key($key, $finger_or);
  } while (defined $key);

  return $list;
}

sub merge {

  my $list1 = shift;
  assert( UNIVERSAL::isa($list1, __PACKAGE__) ), if DEBUG;

  my $list2 = shift;
  assert( UNIVERSAL::isa($list2, __PACKAGE__) ), if DEBUG;

  my ($node1, $finger1) = $list1->_first_node;
  my ($node2, $finger2) = $list2->_first_node;

  assert( ref($node1) eq ref($node2) ), if DEBUG;
  assert( ref($finger1) eq "ARRAY" ), if DEBUG;

  while ((defined $node1) || (defined $node2)) {

    my $cmp = (defined $node1) ? (
     (defined $node2) ? $node1->key_cmp( $node2->key ) : 1 ) : -1;
    
    if ($cmp < 0) {                     # key1 < key2
      if (defined $node1) {
	$finger1 = $list1->insert( $node1->key, $node1->value, );
	$node1 = $node1->forward(0);
      } else {
	$finger1 = $list1->insert( $node2->key, $node2->value, );
	$node2 = $node2->forward(0);
      }
    } elsif ($cmp > 0) {                # key1 > key2
      if (defined $node2) {
	$finger1 = $list1->insert( $node2->key, $node2->value, );
	$node2 = $node2->forward(0);
      } else {
	$finger1 = $list1->insert( $node1->key, $node1->value, );
	$node1 = $node1->forward(0);
      }
    } else {                            # key1 = key2
      $node1 = $node1->forward(0), if defined $node1;
      $node2 = $node2->forward(0), if defined $node2;
    }
  }
}

sub append {
  my $list1 = shift;
  assert( UNIVERSAL::isa($list1, __PACKAGE__) ), if DEBUG;

  my $list2 = shift;

  unless (defined $list2) { return; }
  assert( UNIVERSAL::isa($list2, __PACKAGE__) ), if DEBUG;

  my $node = $list1->{LASTNODE};
  if (defined $node) {

    my ($next, $finger) = $list2->_first_node;

    assert( $node->key_cmp( $next->key ) < 0 ), if DEBUG;

    if ($list1->level > $list2->level) {

      if ($list1->level < $list1->max_level) {

	my $i = $list1->level;
	while (!defined $list1->list->forward($i)) { $i--; }
	$list1->list->forward($i+1, $next);
      } else {
	my $i = $list1->level-1;
	my $x = $list1->list->forward($i);
	while (defined $x->forward($i)) {
	  $x = $x->forward($i);
	}
	$x->forward($i, $next);
      }
      $node->forward(0, $next);

    } else {
      for (my $i=0; $i<$node->level; $i++) {
	$node->forward($i, $next );
      }
      for (my $i=$list1->level; $i<$list2->level; $i++) {
	$list1->list->forward($i, $next);
      }
    }

    $list1->{SIZE}    += $list2->size;
    $list1->{LASTNODE} = $list2->{LASTNODE};

  } else {
    $list1->{LIST}     = $list2->list;
    $list1->{SIZE}     = $list2->size;
    $list1->{LASTNODE} = $list2->{LASTNODE};
  }

}

sub _debug {

  my $self = shift;
  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list   = $self->list;

  while (defined $list) {
    print STDERR
      $list->key||'undef', "=", $list->value||'undef'," ", $list,"\n";

    for(my $i=0; $i<$list->level; $i++) {
      print STDERR " ", $i," ", $list->forward($i) || 'undef', "\n";
    }
    print STDERR "\n";

    $list = $list->forward(0);
  }

}

=head1 NAME

List::SkipList - Perl implementation of skip lists

=head1 REQUIREMENTS

C<Carp::Assert> is used for validation and debugging. (The assertions
can be commented out if the module cannot be installed.)  Otherwise
standard modules are used.

=head1 SYNOPSIS

  my $list = new List::SkipList();

  $list->insert( 'key1', 'value' );
  $list->insert( 'key2', 'another value' );

  $value = $list->find('key2');

  $list->delete('key1');

=head1 DESCRIPTION

This is an implementation of I<skip lists> in Perl.

Skip lists are similar to linked lists, except that they have random
links at various I<levels> that allow searches to skip over sections
of the list, like so:

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
but do not have the overhead with respect to inserting new items.  See
the included file C<Benchmark.txt> for a comparison of performance
with other Perl modules.

For more information on skip lists, see the L</"SEE ALSO"> section below.

Only alphanumeric keys are supported "out of the box".  To use numeric
or other types of keys, see L</"Customizing the Node Class"> below.

=head2 Methods

A detailed description of the methods used is below.

=over

=item new

  $list = new SkipList();

Creates a new skip list.

If you need to use a different L<node class|/"Node Methods"> for using
customized L<comparison|/"key_cmp"> routines, you will need to specify a
different class:

  $list = new SkipList( node_class => 'MyNodeClass' );

See the L</"Customizing the Node Class"> section below.

Specialized internal parameters may be configured:

  $list = new SkipList( max_level => 32 );

Defines a different maximum list level, or C<max_level>.  (The default
is 32.) It is generally a good idea to leave this value alone unless
you are using small lists.

The initial list (see the L</"list"> method) will be a
L<random|/"_random_level"> number of levels, and will increase over time
if inserted nodes have higher levels.

You can also control the probability used to determine level sizes for
each node by setting the L<P|/"p"> value:

  $list = new SkipList( p => 0.5 );

The value defaults to C<0.5>.

For more information on what these values mean, consult the references
below in the L</"SEE ALSO"> section.

=item insert

  $list->insert( $key, $value );

Inserts a new node into the list.

You may also use a L<search finger|/"About Search Fingers"> with insert,
provided that the finger is for a key that occurs earlier in the list:

  $list->insert( $key, $value, $finger );

Using fingers for inserts is I<not> recommended since there is a risk
of producing corrupted lists.

=item exists

  if ($list->exists( $key )) { ... }

Returns true if there exists a node associated with the key, false
otherwise.

This may also be used with  L<search fingers|/"About Search Fingers">:

  if ($list->exists( $key, $finger )) { ... }

=item find

  $value = $list->find( $key );

Searches for the node associated with the key, and returns the value. If
the key cannot be found, returns C<undef>.

L<Search fingers|/"About Search Fingers"> may also be used:

  $value = $list->find( $key, $finger );

To obtain the search finger for a key, call C<find> in a list context:

  ($value, $finger) = $list->find( $key );

=item search

Search is an alias to L</find>.

=item first_key

  $key = $list->first_key;

Returns the first key in the list.

If called in a list context, will return a
L<search finger|/"About Search Fingers">:

  ($key, $finger) = $list->first_key;

A call to C<first_key> implicitly calls C<reset>.

=item next_key

  $key = $list->next_key( $last_key );

Returns the key following the previous key.  List nodes are always
maintained in sorted order.

Search fingers may also be used to improve performance:

  $key = $list->next_key( $last_key, $finger );

If called in a list context, will return a
L<search finger|/"About Search Fingers">:

  ($key, $finger) = $list->next_key( $last_key, $finger );

If no arguments are called,

  $key = $list->next_key;

then the value of C<last_key> is assumed:

  $key = $list->next_key( $list->last_key );

=item last_key

  $key = $list->last_key;

  ($key, $finger) = $list->last_key;

Returns the last key or the last key and finger returned by a call to
C<first_key> or C<next_key>.

Deletions and inserts will invalidate the C<last_key> value, although
they may not reset the last key.

=item reset

  $list->reset;

Resets the C<last_key> to C<undef>. 

=item delete

  $value = $list->delete( $key );

Deletes the node associated with the key, and returns the value.  If
the key cannot be found, returns C<undef>.

L<Search fingers|/"About Search Fingers"> may also be used:

  $value = $list->delete( $key, $finger );

Calling C<delete> in a list context I<will not> return a search
finger.

=item clear

  $list->clear;

Erases existing nodes and resets the list.

=item size

  $size = $list->size;

Returns the number of nodes in the list.

=item copy

  $list2 = $list1->copy;

Makes a copy of a list.  The L</"p">, L</"max_level"> and
L<node class|/"_node_class"> are copied, although the exact structure of node
levels is not copied.

This is an autoloading method.

=item merge

  $list1->merge( $list2 );

Merges two lists.  If both lists share the same key, then the valie
from C<$list1> will be used.

Both lists should have the same L<node class|/"_node_class">.

This is an autoloading method.

=item append

  $list1->append( $list2 );

Appends C<$list2> after C<$list1>.  The last key of C<$list1> must be less
than the first key of C<$list2>.

Both lists should have the same L<node class|/"_node_class">.

This method affects both lists.  The L</"header"> of the last node of
C<$list1> points to the first node of C<$list2>, so changes to one
list may affect the other list.

If you do not want this entanglement, use the C<merge> or C<copy>
methods instead:

  $list1->merge( $list2 );
  
or

  $list1->append( $list2->copy );

This is an autoloading method.

=item least

  ($key, $value) = $list->least;

Returns the least key and value in the list, or C<undef> if the list
is empty.

This is an autoloading method.

=item greatest

  ($key, $value) = $list->greatest;

Returns the greatest key and value in the list, or C<undef> if the list
is empty.

This is an autoloading method.

=item keys

  @keys = $list->keys;

Returns a list of keys (in sorted order).

This is an autoloading method.

=item values

  @values = $list->values;

Returns a list of values (corresponding to the keys returned by the
C<keys> method).

This is an autoloading method.

=back

=head2 Internal Methods

Internal methods are documented below. These are intended for
developer use only.  These may change in future versions.

=over

=item _search

  ($node, $finger, $cmp) = $list->_search( $key );

Searches for the node with a key.  If the key is found, that node is
returned along with a L</"header">.  If the key is not found, the previous
node from where the node would be if it existed is returned.

Note that the value of C<$cmp>

  $cmp = $node->key_cmp( $key )

is returned because it is already determined by C<_search>.

Search fingers may also be specified:

  ($node, $finger, $cmp) = $list->_search( $key, $finger );

Note that the L</"header"> is actually a
L<search finger|/"About Search Fingers">.

=item p

  $plevel = $list->p;

Returns the I<P> value.  Intended for internal use only.

=item max_level

  $max = $list->max_level;

Returns the maximum level that C<_random_level> can generate.

=item _random_level

  $level = $list->_random_level;

This is an internal function for generating a random level for new nodes.

Levels are determined by the L<P|/"p"> value.  The probability that a
node will have 1 level is I<P>; the probability that a node will have
2 levels is I<P^2>; the probability that a node will have 3 levels is
I<P^3>, et cetera.

The value will never be greater than C<max_level>.

=item list

  $node = $list->list;

Returns the initial node in the list, which is a
C<List::SkipList::Node> (See L<below|/"Node Methods">.)

The key and value for this node are undefined.

=item _first_node

  ($node, $finger) = _first_node;

Returns the first node with a key (the second node) in a list and the
finger.  This is used by the C<merge> method.

This is an autoloading method.

=item _node_class

  $node_class_name = $list->_node_class;

Returns the name of the node class used.  By default this is the
C<List::SkipList::Node>, which is discussed below.

=item _set_node_class

=item _set_max_level

=item _set_p

These methods are used only during initialization of the object.
I<Do not call these methods after the object has been created!>

=item _debug

  $list->_debug;

Used for debugging skip lists by developer.  The output of this
function is subject to change.

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
L<custom node class|/"Customizing the Node Class">.

=item validate_key

  if ($node->validate_key( $key )) { ... }

Used by L</"value"> to validate that a key is valid.  Returns true if it
is ok, false otherwise.

By default this is a dummy routine.  Redefine it to validate keys if
you need it when L</"Customizing the Node Class">.

=item value

  $value = $node->value;

Returns the node's value.

  $node->value( $value );

When used with an argument, sets the node's value.

=item validate_value

  if ($node->validate_value( $value )) { ... }

Used by L</"value"> to validate that value is valid.  Returns true if it
is ok, false otherwise.

By default this is a dummy routine.  Redefine it to validate values if
you need it when L</"Customizing the Node Class">.

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

=head1 SPECIAL FEATURES

=head2 Tied Hashes

Hashes can be tied to C<List::SkipList> objects:

  tie %hash, 'List::SkipList';
  $hash{'foo'} = 'bar';

  $list = tied %hash;
  print $list->find('foo'); # returns bar

See the L<perltie> manpage for more information.

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
    assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

    my $left  = $self->key;  # node key
    my $right = shift;       # value to compare the node key with

    # We should gracefully handle $left being undefined
    unless (defined $left) { return -1; }

    return ($left <=> $right);
  }

  sub validate_key {
    my $self = shift;
    assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

    my $key = shift;
    return ($key =~ s/\-?\d+(\.\d+)?$/); # test if key is numeric
  }

To use this, we say simply

  $number_list = new List::SkipList( node_class => 'NumericNode' );

This skip list should work normally, except that the keys must be
numbers.

For another example of customized nodes, see L<Tie::RangeHash> version
1.00_b1 or later.

=head2 About Search Fingers

A side effect of the search function is that it returns a I<finger> to
where the key is or should be in the list.

We can use this finger for future searches if the key that we are
searching for occurs I<after> the key that produced the finger. For
example,

  ($value, $finger) = $list->find('Turing');

If we are searching for a key that occurs after 'Turing' in the above
example, then we can use this finger:

  $value = $list->find('VonNeuman', $finger);

If we use this finger to search for a key that occurs before 'Turing'
however, it may fail:

  $value = $list->find('Goedel', $finger); # this may not work

Therefore, use search fingers with caution.

Search fingers are specific to particular instances of a skip list.
The following should not work:

  ($value1, $finger) = $list1->find('bar');
  $value2            = $list2->find('foo', $finger);

One useful feature of fingers is with enumerating all keys using the
C<first_key> and C<next_key> methods:

  ($key, $finger) = $list->first_key;

  while (defined $key) {
    ...
    ($key, $finger) = $list->next_key($key, $finger);
  }

See also the C<keys> method for generating a list of keys.

=head2 Similarities to Tree Classes

This module intentionally has a subset of the interface in the
L<Tree::Base> and other tree-type data structure modules, since skip
lists can be used in place of trees.

Because pointers only point forward, there is no C<prev> method to
point to the previous key.

Some of these methods (least, greatest) are autoloading because they
are not commonly used.

One thing that differentiates this module from other modules is the
flexibility in defining a custom node class.

See the included C<Benchmark.txt> file for performance comparisons.

=head1 TODO

The following features may be added in future versions:

=over

=item Accessing list nodes by index number as well as key

The ability to tie a list to an array as well as a hash, probably as a
subclass since to implement it efficiently would require some extra
bookkeeping.

=item Splitting lists

The ability to split a list into multiple segments.

=item Deterministic Skip Lists

An additional module (probably a subclass of List::SkipList) to
implement deterministic skip lists (DSLs), probably as a 1-2-3 skip
list.

=back

=head1 CAVEATS

Skip lists are non-deterministic.  Because of this, bugs in programs
that use this module may be subtle and difficult to reproduce without
many repeated attempts.  This is especially true if there are bugs in
a L<custom node|/"Customizing the Node Class">.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Acknowledgements

Carl Shapiro <cshapiro at panix.com> for introduction to skip lists.

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2003-2004 Robert Rothenberg. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

See the article "A Skip List Cookbook" (William Pugh, 1989), or
similar ones by the author at L<http://www.cs.umd.edu/~pugh/> which
discuss skip lists.

If you need a keyed list that preserves the order of insertion rather
than sorting keys, see L<List::Indexed>.

=cut
