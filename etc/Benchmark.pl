use strict;
use warnings;

use Benchmark;
use List::SkipList 0.42;
use Tree::Smart;
use Tree::Ternary;
use Tree::RedBlack;

use constant SIZE => 10000;

my @RandomKeys  = ();
my $Cnt   = SIZE;

{
  my $stuff = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  while ($Cnt--) {
    my $key = "";
    for (1..32) {
      $key .= substr($stuff, int(rand(length($stuff))),1);
    }
    push @RandomKeys, $key;
  }
}


my @SortedKeys  = sort @RandomKeys;
my @ReverseKeys = reverse @SortedKeys;

sub make_sub {
  my $obj    = shift;
  my $method = shift;
  my $list   = shift;

  return sub {
    foreach my $num (@$list) {
      $obj->$method($num);
    }
  }
}

# sub make_sub_test {
#   my $obj    = shift;
#   my $method = shift;
#   my $list   = shift;

#   return sub {
#     foreach my $num (@$list) {
#       unless ($num eq $obj->$method($num)) {
# 	die "Mismatch";
# 	return;
#       }
#     }
#   }
# }

my $Sl  = new List::SkipList;
my $Ts  = new Tree::Smart;
my $Tt  = new Tree::Ternary;
my $Trb = new Tree::RedBlack;

use constant COUNT => 1;

timethese( COUNT, {
  'List::SkipList::ins RandomKeys' => make_sub($Sl, 'insert', \@RandomKeys),
  'Tree::RedBlack::ins RandomKeys' => make_sub($Trb, 'insert', \@RandomKeys),
  'Tree::Smart::ins RandomKeys' => make_sub($Ts, 'insert', \@RandomKeys),
  'Tree::Ternary::ins RandomKeys' => make_sub($Tt, 'insert', \@RandomKeys),
});

$Sl = new List::SkipList;
$Ts = new Tree::Smart;
$Tt = new Tree::Ternary;
$Trb = new Tree::RedBlack;

timethese( COUNT, {
  'List::SkipList::ins SortedKeys' => make_sub($Sl, 'insert', \@SortedKeys),
  'Tree::RedBlack::ins SortedKeys' => make_sub($Trb, 'insert', \@SortedKeys),
  'Tree::Smart::ins SortedKeys' => make_sub($Ts, 'insert', \@SortedKeys),
  'Tree::Ternary::ins SortedKeys' => make_sub($Tt, 'insert', \@SortedKeys),
});

$Sl = new List::SkipList;
$Ts = new Tree::Smart;
$Tt = new Tree::Ternary;
$Trb = new Tree::RedBlack;

timethese( COUNT, {
  'List::SkipList::ins ReverseKeys' => make_sub($Sl, 'insert', \@ReverseKeys),
  'Tree::RedBlack::ins ReverseKeys' => make_sub($Trb, 'insert', \@ReverseKeys),
  'Tree::Smart::ins ReverseKeys' => make_sub($Ts, 'insert', \@ReverseKeys),
  'Tree::Ternary::ins ReverseKeys' => make_sub($Tt, 'insert', \@ReverseKeys),
});

timethese( COUNT, {
  'List::SkipList::find' => make_sub($Sl, 'find', \@RandomKeys),
  'Tree::RedBlack::find' => make_sub($Trb, 'find', \@RandomKeys),
  'Tree::Smart::find' => make_sub($Ts, 'find', \@RandomKeys),
  'Tree::Ternary::search' => make_sub($Tt, 'search', \@RandomKeys),
});


timethese( COUNT, {
  'List::SkipList::delete' => make_sub($Sl, 'delete', \@RandomKeys),
  'Tree::Smart::delete' => make_sub($Ts, 'delete', \@RandomKeys),
#  'Tree::RedBlack::delete ReverseKeys' => make_sub($Trb, 'delete', \@RandomKeys),
});


exit 0;


__END__

