
use strict;
use warnings;

my %vars = ( );

{
  foreach my $module (
    qw(
       List::SkipList
       Tree::RedBlack
       Tree::BPTree
       Tree::Smart
      )) {

    $vars{size}         = 10000;   # size of samples
    $vars{keysize}      = 32;      # length of key
    $vars{module}       = $module;
    $vars{count}        = 100;

    my $pgm_template = '
use strict;
use Benchmark;
use <<module>>;

use constant SIZE => <<size>>;

my @RandomKeys  = ();
my @BogusKeys   = ();
my $Cnt   = SIZE;

{
  my $stuff = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  while ($Cnt--) {
    my $key = "";
    for (1..<<keysize>>) {
      $key .= substr($stuff, int(rand(length($stuff))),1);
    }
    push @RandomKeys, $key;
    $key =~ tr/A-Za-z/a-zA-Z/;  # reverse case
    push @BogusKeys, $key;
  }
}

my @SortedKeys  = sort @RandomKeys;
my @ReverseKeys = reverse @SortedKeys;

my $Obj;

foreach (1..<<count>>) {

# timethis( <<size>>,
#  sub {
#    my $obj = new <<module>>;
#  }, "<<module>>::new" );


$Obj = new <<module>>;

timethis( 1,
 sub {
   foreach my $key (@SortedKeys) {
     $Obj->insert($key);
   }
 }, "<<module>>::ins-sorted" );

undef $Obj;

$Obj = new <<module>>;

timethis( 1,
 sub {
   foreach my $key (@ReverseKeys) {
     $Obj->insert($key);
   }
 }, "<<module>>::ins-reversed" );

undef $Obj;

$Obj = new <<module>>;

timethis( 1,
 sub {
   foreach my $key (@RandomKeys) {
     $Obj->insert($key);
   }
 }, "<<module>>::ins-random" );



timethis( 1,
 sub {
   foreach my $key (@RandomKeys) {
     $Obj->find($key);
   }
 }, "<<module>>::find" );

if ($Obj->can("exists")) { timethis( 1,
 sub {
   foreach my $key (@RandomKeys) {
     $Obj->exists($key);
   }
 }, "<<module>>::exists" );
}

timethis( 1,
 sub {
   foreach my $key (@BogusKeys) {
     $Obj->find($key);
   }
 }, "<<module>>::find_bogus" );

if ($Obj->can("delete")) { timethis( 1,
 sub {
   foreach my $key (@RandomKeys) {
     $Obj->delete($key);
   }
 }, "<<module>>::delete" );
}

undef $Obj;

}

';

    $pgm_template =~ s/<<(\w+)>>/$vars{$1}/gm;

    my $filename = 'bench_' . lc($vars{module}) . '.pl';
    $filename    =~ s/\:+/_/g;

    open my $fh, ('>'.$filename)
      or die "Unable to create file";
    print $fh $pgm_template;
    close $fh;

    my $shell = ($^O eq "MSWin32") ? 'cmd' : 'sh';

    open $fh, ('>>bench.'.$shell)
      or die "Unable to open file";
    print $fh "perl $filename >> bench.out\n";
    close $fh;
  }
}
__END__

