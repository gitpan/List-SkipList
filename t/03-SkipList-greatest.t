#-*- mode: perl;-*-

package main;

use Test::More tests => 7;

use List::SkipList 0.70;

my $List = new List::SkipList;

foreach ('A'..'D') {
  $List->insert($_, 1+$List->size);
}

{
  my $last;
  while ($List->size) {
    my($key, $value) = $List->greatest;
    ok($value == $List->delete($key), "verify greatest via deletion");
    if (defined $last) {
      ok($last gt $key);
    }
    $last = $key;
  }
}
