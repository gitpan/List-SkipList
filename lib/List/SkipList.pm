package List::SkipList::Node;

use 5.006;
use strict;
use warnings;

# use Carp qw(carp croak);
# no Carp::Assert qw(assert DEBUG);

our $VERSION
 = '1.33';

use enum qw( HEADER KEY VALUE );

sub new {
  my $class = shift;
  my $self  = [ ];

  $self->[KEY]    = shift;
  $self->[VALUE]  = shift;
  $self->[HEADER] = shift || [ ];

  bless $self, $class;
}

sub header {
  my ($self, $hdr) = @_;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( (!$hdr) || ref($hdr) eq "ARRAY" ), if DEBUG;

  ($hdr) ? ( $self->[HEADER] = $hdr ) : $self->[HEADER];
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

  (@_ > 1) ? ( $self->[KEY] = $key ) : $self->[KEY];
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

package List::SkipList::Header;

use 5.006;
use strict;
use warnings;

our $VERSION
 = '0.01';

our @ISA = qw( List::SkipList::Node );

sub key_cmp {
  -1;   # Note that the header returns "1" instead of "-1"!
}

sub key {
  return;
}

sub value {
  return;
}

package List::SkipList::Null;

use 5.006;
use strict;
use warnings;

our $VERSION
 = '0.01';

our @ISA = qw( List::SkipList::Header );

sub key_cmp {
  1;   # Note that the header returns "1" instead of "-1"!
}

package List::SkipList;

use 5.006;
use strict;
use warnings; # should we register warnings?

our $VERSION = '0.62';

use AutoLoader qw( AUTOLOAD );
use Carp qw( carp croak );
# no Carp::Assert qw(assert DEBUG);

use constant MAX_LEVEL       => 32;
use constant DEF_P           => 0.5;

use constant BASE_NODE_CLASS => 'List::SkipList::Node';

my $NULL; INIT { $NULL = new List::SkipList::Null(); }

# Caching the "finger" for the last insert allows sequential (sorted)
# inserts to be sped up.  It does not seem to affect the performance
# of non-sequential inserts. [Present]

sub new {
  no integer;

  my $class = shift;

  my $self = {
    NODECLASS => BASE_NODE_CLASS,       # node class used by list
    LIST      => undef,                 # pointer to the header node
    SIZE      => undef,                 # size of list
    SIZE_THRESHOLD => undef,            # size at which SIZE_LEVEL increased
    SIZE_LEVEL     => undef,            # maximum level random_level
    MAXLEVEL  => MAX_LEVEL,             # absolute maximum level
    P         => 0,                     # probability for each level
    P_LEVELS  => [ ],                   # array used by random_level
    LASTNODE  => undef,                 # node with greatest key
    LASTKEY   => undef,                 # last key used by next_key
    LASTINSRT => undef,                 # cached insertion fingers
  };

  bless $self, $class;

  $self->_set_p( DEF_P ); # initializes P_LEVELS

  if (@_) {
    my %args = @_;
    foreach my $arg_name (CORE::keys %args) {
      my $method = "_set_" . $arg_name;
      if ($self->can($method)) {
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
  my ($self, $node_class) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( UNIVERSAL::isa($node_class, BASE_NODE_CLASS) ), if DEBUG;
  $self->{NODECLASS} = $node_class;
}

sub _node_class {
    my ($self) = @_;
#     assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
    $self->{NODECLASS};
  }

sub reset {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $self->{LASTKEY}  = undef;
}

sub clear {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  $self->{SIZE}     = 0;
  $self->{SIZE_THRESHOLD} = 2;
  $self->{SIZE_LEVEL}     = 2;

  my @header = ( undef ) x $self->_random_level;

  $self->{LIST} = new List::SkipList::Header( undef, undef, \@header );

#   assert( $self->list->level > 0 ), if DEBUG;
#   assert( UNIVERSAL::isa($self->{LIST}, BASE_NODE_CLASS) ), if DEBUG;

  $self->{LASTNODE}  = undef;
  $self->{LASTINSRT} = undef;

  $self->reset;
}

sub _set_max_level {
  my ($self, $level) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( ($level>1) ), if DEBUG;
  $self->{MAXLEVEL} = $level;
}

sub max_level {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $self->{MAXLEVEL};
}

sub _set_p {
  no integer;

  my ($self, $p) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  
#   assert( ($p>0) && ($p<1) ), if DEBUG;

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
    # TODO: add assertion that [level]<[level-1]
    $self->{P_LEVELS}->[$level++] = $n;
    $n *= $p;
  }
}

sub p {
  no integer;

  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $self->{P};
}

sub size {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $self->{SIZE};
}

sub list {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $self->{LIST};
}

sub level {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $self->{LIST}->level;
}

sub null {
#   my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  $NULL;
}

sub _random_level {
  no integer;

  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  # we call $self->{MAXLEVEL} instead of $self->max_level for very
  # minor speed improvement

  if ($self->{SIZE} >= $self->{SIZE_THRESHOLD}) {
    $self->{SIZE_THRESHOLD} += $self->{SIZE_THRESHOLD};
    $self->{SIZE_LEVEL}++, if ($self->{SIZE_LEVEL} < $self->{MAXLEVEL});
  }

  my $n     = rand();
  my $level = 1;

  while (($n < $self->{P_LEVELS}->[$level]) && ($level < $self->{SIZE_LEVEL}))
    {
      $level++;
    }

#   assert( ($level >= 1) && ($level <= $self->{SIZE_LEVEL}) ), if DEBUG;
  $level;
}

sub _search_with_finger {
  my ($self, $key, $finger) = @_;

  use integer;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( (!defined $finger) || UNIVERSAL::isa($finger, "ARRAY") ),
#     if DEBUG;

  my $list   = $self->list;
  my $level  = $list->level-1;

#   assert( UNIVERSAL::isa( $list, BASE_NODE_CLASS ) ), if DEBUG;
#   assert( $level >= 0 ), if DEBUG;

#  $finger_ref ||= [ ];

  my $x = $finger->[ $level ] || $list;

#   assert( defined $x ), if DEBUG;

  # Iteresting Perl syntax quirk:
  #   do { my $x = ... } while ($x)
  # doesn't work because it considers $x out of scope.

  my ($fwd, $cmp);

  do {
    $fwd = $x->header()->[$level] || $NULL;
    $cmp = $fwd->key_cmp($key);

    if ($cmp >= 0) {
      $finger->[$level--] = $x;
    }
    if ($cmp <= 0) {
      $x = $fwd;
    }

  } while (($cmp) && ($level>=0));

  #   assert( UNIVERSAL::isa($x, BASE_NODE_CLASS) ), if DEBUG;

  ($x, $finger, $cmp);
}

sub _search {
  my ($self, $key, $finger) = @_;

  use integer;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( (!defined $finger) || UNIVERSAL::isa($finger, "ARRAY") ),
#     if DEBUG;

  my $list   = $self->list;
  my $level  = $list->level-1;

#   assert( UNIVERSAL::isa( $list, BASE_NODE_CLASS ) ), if DEBUG;
#   assert( $level >= 0 ), if DEBUG;

#  $finger ||= [ ];

  my $x = $finger->[ $level ] || $list;

#   assert( defined $x ), if DEBUG;

  my ($fwd, $cmp);

  do {
    $fwd = $x->header()->[$level] || $NULL;
    $cmp = $fwd->key_cmp($key);

    if ($cmp <= 0) {
      $x = $fwd;
    } else {
      $level--;
    }

  } while (($cmp) && ($level>=0));

  #   assert( UNIVERSAL::isa($x, BASE_NODE_CLASS) ), if DEBUG;

  ($x, $finger, $cmp);
}

sub insert {
  my ($self, $key, $value, $finger) = @_;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  use integer;

  my $list   = $self->list;

  # We save the node and finger of the last insertion. If the next key
  # is larger, then we can use the "finger" to speed up insertions.

  my ($node, $cmp);

  unless ($finger) {
    $node   = $self->{LASTINSRT}->[0] || $NULL;
    $finger = $self->{LASTINSRT}->[1],
      if ($node->key_cmp($key) <= 0);
  }

#   assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;

  ($node, $finger, $cmp) = $self->_search_with_finger($key, $finger);

  if ($cmp) {

    my $new_level = $self->_random_level;

    my $node_hdr = [ ];
    my $fing_hdr;

    $node = $self->_node_class->new( $key, $value, $node_hdr );

    for (my $i=0;$i<$new_level;$i++) {
      $fing_hdr = ($finger->[$i]||$list)->header();
      $node_hdr->[$i] = $fing_hdr->[$i];
      $fing_hdr->[$i] = $node;
    }

#     my $next = $node_hdr->[0];
#     if ($next) {
#       $node->prev( $next->prev );
#       $next->prev( $node );
#     } else {
#       $self->{LASTNODE} = $node;
#     }

    $self->{LASTNODE} = $node, unless ($node_hdr->[0]);

    $self->{SIZE}++;
  } else {
    $node->value($value);
  }
  $self->{LASTINSRT}->[0] = $node;
  $self->{LASTINSRT}->[1] = $finger;
}

sub delete {

  my ($self, $key, $finger) = @_;

  use integer;

#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
#   assert( defined $key ), if DEBUG;
# 
#   if (defined $finger) {
#     assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
#   }

  my $list = $self->list;

  my ($x, $update_ref, $cmp) = $self->_search_with_finger($key, $finger);

  if ($cmp == 0) {
    my $value = $x->value;

    my $level = $x->level-1; 
#     assert($level < @{$update_ref}), if DEBUG;

    for (my $i=$level; $i>=0; $i--) {

      my $y   = $update_ref->[$i] || $list;

      # The top level of the finger points to the current node. The
      # lower levels should be set to that node if they point to the
      # start of the list.

      if ($y == $list) { $y = $update_ref->[$level]; }

      while ((my $fwd=$y->header()->[$i]) != $x) {
	$y = $fwd;
# 	assert( UNIVERSAL::isa($y, BASE_NODE_CLASS) ), if DEBUG;
      }
      $y->header()->[$i] = $x->header()->[$i];

    }

#     my $next = $x->header()->[0];
#     if ($next) { $next->prev( $x->prev ); }

    # There's probably a smarter way to handle this, but this is the
    # safest way.

    $self->{LASTINSRT} = undef;

    $self->{SIZE} --;

    # We shouldn't need to "undef $x" here. The Garbage Collector
    # should hanldle that.

    # Note: It doesn't seem to be a wise idea to return a search
    # finger for deletions without further analysis

    $value;

  } else {
    return;
  }
}

sub exists {

  my ($self, $key, $finger) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

#   if (defined $finger) {
#     assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
#   }

  ( ($self->_search($key, $finger))[2] == 0 );
}

sub find_with_finger {
  my ($self, $key, $finger) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

#   if (defined $finger) {
#     assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
#   }

  my ($x, $update_ref, $cmp) = $self->_search_with_finger($key, $finger);

  ($cmp == 0) ? (
    (wantarray) ? ($x->value, $update_ref) : $x->value
  ) : undef;

}

sub find {
  my ($self, $key, $finger) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

#   if (defined $finger) {
#     assert( UNIVERSAL::isa($finger, "ARRAY") ), if DEBUG;
#   }

  my ($x, $update_ref, $cmp) = $self->_search($key, $finger);

  ($cmp == 0) ? $x->value : undef;
}

sub last_key {
  my ($self, $key, $finger, $value) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  if (defined $key) {
    $self->{LASTKEY} = [ $key, $finger || [ ], $value ];
  }

  if (defined $self->{LASTKEY}) {
    return (wantarray) ?
      @{$self->{LASTKEY}} : $self->{LASTKEY}->[0];
  } else {
    return;
  }

}

sub first_key {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list = $self->list;
  my $fwd  = $list->header()->[0];
  if ($fwd) {
    return $self->last_key( $fwd->key, [( $list ) x $list->level],
			    $fwd->value );
  } else {
    return;
  }
}


sub next_key {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $last_key = shift;
  my $finger   = shift;

  unless (defined $last_key) {
    ($last_key, $finger) = $self->last_key;
  }

#   if ($finger) {
#     assert( ref($finger) eq "ARRAY" ), if DEBUG;
#   }

  if (defined $last_key) {
    my ($list, $update_ref, $cmp) =
      $self->_search_with_finger($last_key, $finger);

    my $fwd  = $list->header()->[0];
 
    if ($cmp == 0) {
      if (defined $fwd) {
	$self->last_key($fwd->key, $update_ref, $fwd->value);
      } else {
	return;
      }
    } else {
      return;
    }
  } else {
    $self->first_key;
  }
}


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
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list = $self->list;
  my $fwd  = $list->header()->[0];
  if (defined $fwd) {
    return ($fwd, scalar $list->header);
  } else {
    return;
  }
}

sub least {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my ($node, $finger) = $self->_first_node;

  if (defined $node) {
    return ($node->key, $node->value);
  } else {
    return;
  }
}

sub greatest {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $node = $self->{LASTNODE};
  if (defined $node) {
    return ($node->key, $node->value);
  } else {
    return;
  }
}

sub next {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my ($key, $finger, $value) = $self->next_key;

  if (defined $key) {
    return ($key, $value)
  } else {
    return;
  }
}

sub prev_key {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  croak "unimplemented method";
}

sub prev {
  my ($self) = @_;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;
  croak "unimplemented method";
}


sub keys {
  my $self = shift;
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

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
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

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
#   assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list = new List::SkipList(
    max_level  => $self->max_level,
    p          => $self->p,
    node_class => $self->_node_class,
  );

  my ($key, $finger_or) = $self->first_key();
  my $value;
  my $finger_cp = undef;

  $self->reset();

  do {
    ($value, $finger_or) = $self->find_with_finger($key, $finger_or);
    my $finger_cp        = $list->insert($key, $value, $finger_cp);
    ($key, $finger_or)   = $self->next_key($key, $finger_or);
  } while (defined $key);

  $self->reset();

  return $list;
}

sub merge {

  my $list1 = shift;
#   assert( UNIVERSAL::isa($list1, __PACKAGE__) ), if DEBUG;

  my $list2 = shift;
#   assert( UNIVERSAL::isa($list2, __PACKAGE__) ), if DEBUG;

  my ($node1, $finger1) = $list1->_first_node;
  my ($node2, $finger2) = $list2->_first_node;

#   assert( ref($node1) eq ref($node2) ), if DEBUG;
#   assert( ref($finger1) eq "ARRAY" ), if DEBUG;

  while ((defined $node1) || (defined $node2)) {

    my $cmp = (defined $node1) ? (
     (defined $node2) ? $node1->key_cmp( $node2->key ) : 1 ) : -1;
    
    if ($cmp < 0) {                     # key1 < key2
      if (defined $node1) {
	$finger1 = $list1->insert( $node1->key, $node1->value, );
	$node1 = $node1->header()->[0];
      } else {
	$finger1 = $list1->insert( $node2->key, $node2->value, );
	$node2 = $node2->header()->[0];
      }
    } elsif ($cmp > 0) {                # key1 > key2
      if (defined $node2) {
	$finger1 = $list1->insert( $node2->key, $node2->value, );
	$node2 = $node2->header()->[0];
      } else {
	$finger1 = $list1->insert( $node1->key, $node1->value, );
	$node1 = $node1->header()->[0];
      }
    } else {                            # key1 = key2
      $node1 = $node1->header()->[0],
	if defined $node1;
      $node2 = $node2->header()->[0],
	if defined $node2;
    }
  }
}

sub append {
  my $list1 = shift;
#   assert( UNIVERSAL::isa($list1, __PACKAGE__) ), if DEBUG;

  my $list2 = shift;

  unless (defined $list2) { return; }
#   assert( UNIVERSAL::isa($list2, __PACKAGE__) ), if DEBUG;

  my $node = $list1->{LASTNODE};
  if (defined $node) {

    my ($next, $finger) = $list2->_first_node;

#    assert( $node->key_cmp( $next->key ) < 0 ), if DEBUG;

    if ($list1->level > $list2->level) {

      if ($list1->level < $list1->max_level) {

	my $i = $list1->level;
	while (!defined $list1->list->header()->[$i]) { $i--; }
	$list1->list->header()->[$i+1] = $next;
      } else {
	my $i = $list1->level-1;
	my $x = $list1->list->header()->[$i];
	while (defined $x->header()->[$i]) {
	  $x = $x->header()->[$i];
	}
	$x->header()->[$i] = $next;
      }
      $node->header()->[0] = $next;

    } else {
      for (my $i=0; $i<$node->level; $i++) {
	$node->header()->[$i] = $next;
      }
      for (my $i=$list1->level; $i<$list2->level; $i++) {
	$list1->list->header()->[$i] = $next;
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
#  assert( UNIVERSAL::isa($self, __PACKAGE__) ), if DEBUG;

  my $list   = $self->list;

  while (defined $list) {
    print STDERR
      $list->key||'undef', "=", $list->value||'undef'," ", $list,"\n";

    for(my $i=0; $i<$list->level; $i++) {
      print STDERR " ", $i," ", $list->header()->[$i]
	|| 'undef', "\n";
    }
    print STDERR " P ", $list->prev() || 'undef', "\n";
    print STDERR "\n";

    $list = $list->header()->[0];
  }

}

=head1 NAME

List::SkipList - Perl implementation of skip lists

=head1 REQUIREMENTS

The following non-standard modules are used:

  enum

Carp::Assert is no longer required.  However, the assertions can be
uncommented for debugging.

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

Defines a different maximum list level, or L</max_level>.  (The default
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

=item find_with_finger

  $value = $list->find_with_finger( $key );

Searches for the node associated with the key, and returns the value. If
the key cannot be found, returns C<undef>.

L<Search fingers|/"About Search Fingers"> may also be used:

  $value = $list->find_with_finger( $key, $finger );

To obtain the search finger for a key, call L</find_with_finger> in a
list context:

  ($value, $finger) = $list->find_with_finger( $key );

=item find

  $value = $list->find( $key );

  $value = $list->find( $key, $finger );

Searches for the node associated with the key, and returns the value. If
the key cannot be found, returns C<undef>.

This method is slightly faster than L</find_with_finger> since it does
not return a search finger when called in list context.

=item search

Search is an alias to L</find>.

=item first_key

  $key = $list->first_key;

Returns the first key in the list.

If called in a list context, will return a
L<search finger|/"About Search Fingers">:

  ($key, $finger) = $list->first_key;

A call to L</first_key> implicitly calls L</reset>.

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

then the value of L</last_key> is assumed:

  $key = $list->next_key( $list->last_key );

=item next

  ($key, $value) = $list->next( $last_key, $finger );

Returns the next key-value pair.

C<$last_key> and C<$finger> are optional.

This is an autoloading method.

=item last_key

  $key = $list->last_key;

  ($key, $finger, $value) = $list->last_key;

Returns the last key or the last key and finger returned by a call to
L</first_key> or L</next_key>.

Deletions and inserts will invalidate the L</last_key> value, although
they may not L</reset> the last key.

Values for L</last_key> can also be set by including parameters,
however this feature is meant for I<internal use only>:

  $list->last_key( $key, $finger, $value );

No checking is done to make sure that the C<$key> and C<$value> pairs
match, or that the C<$finger> is valid.

=item reset

  $list->reset;

Resets the L</last_key> to C<undef>. 

=item delete

  $value = $list->delete( $key );

Deletes the node associated with the key, and returns the value.  If
the key cannot be found, returns C<undef>.

L<Search fingers|/"About Search Fingers"> may also be used:

  $value = $list->delete( $key, $finger );

Calling L</delete> in a list context I<will not> return a search
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

If you do not want this entanglement, use the L</merge> or L</copy>
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
L</keys> method).

This is an autoloading method.

=back

=head2 Internal Methods

Internal methods are documented below. These are intended for
developer use only.  These may change in future versions.

=over

=item _search_with_finger

  ($node, $finger, $cmp) = $list->_search_with_finger( $key );

Searches for the node with a key.  If the key is found, that node is
returned along with a L</"header">.  If the key is not found, the previous
node from where the node would be if it existed is returned.

Note that the value of C<$cmp>

  $cmp = $node->key_cmp( $key )

is returned because it is already determined by L</_search>.

Search fingers may also be specified:

  ($node, $finger, $cmp) = $list->_search_with_finger( $key, $finger );

Note that the L</"header"> is actually a
L<search finger|/"About Search Fingers">.

=item _search

  ($node, $finger, $cmp) = $list->_search( $key, [$finger] );

Same as L</_search_with_finger>, only that a search finger is not returned.
(Actually, an initial "dummy" finger is returned.)

This is useful for searches where a finger is not needed.  The speed
of searching is improved.

=item p

  $plevel = $list->p;

Returns the I<P> value.  Intended for internal use only.

=item max_level

  $max = $list->max_level;

Returns the maximum level that L</_random_level> can generate.

=item _random_level

  $level = $list->_random_level;

This is an internal function for generating a random level for new nodes.

Levels are determined by the L<P|/"p"> value.  The probability that a
node will have 1 level is I<P>; the probability that a node will have
2 levels is I<P^2>; the probability that a node will have 3 levels is
I<P^3>, et cetera.

The value will never be greater than L</max_level>.

=item list

  $node = $list->list;

Returns the initial node in the list, which is a
C<List::SkipList::Node> (See L<below|/"Node Methods">.)

The key and value for this node are undefined.

=item level

  $level = $list->level;

Returns the number of levels in the list.  It is the same as

  $level = $list->list->level;

=item _first_node

  ($node, $finger) = _first_node;

Returns the first node with a key (the second node) in a list and the
finger.  This is used by the L</merge> method.

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

  $node = new List::SkipList::Node( $key, $value, $header );

Creates a new node for the list.  The parameters are optional.

Note that the versions 0.42 and earlier used a different calling
convention.

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

By default this is a dummy routine that is only called when assertions
are enabled.

=item value

  $value = $node->value;

Returns the node's value.

  $node->value( $value );

When used with an argument, sets the node's value.

=item validate_value

  if ($node->validate_value( $value )) { ... }

Used by L</"value"> to validate that value is valid.  Returns true if it
is ok, false otherwise.

By default this is a dummy routine that is only called when assertions
are enabled.

=item header

  $header_ref = $node->header;

Returns the forward list array of the node. This is an array of nodes
which point to the node returned, where each index in the array refers
to the level.

  $node->header( $header_ref );

When used with an argument, sets the forward list.  It does not check
if list elements are of the correct type.

Note that the interface has changed. This method only accepts or
returns header references.

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
L</first_key> and L</next_key> methods:

  ($key, $finger) = $list->first_key;

  while (defined $key) {
    ...
    ($key, $finger) = $list->next_key($key, $finger);
  }

See also the L</keys> method for generating a list of keys.

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

See the included F<Benchmark.txt> file for performance comparisons.

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
