package main;

use Test;
BEGIN { plan tests => 7 };
use List::SkipList 0.34;

tie my %hash, 'List::SkipList';

my $h = tied %hash;
ok(ref($h), 'List::SkipList');
ok($h->size,0);

$hash{abc} = 2;

ok($hash{abc}, 2);

ok($h->size, 1);
ok($h->find('abc'), 2);

delete $hash{'abc'};

ok($h->size, 0);
ok(!$h->find('abc'));

# TODO: More tests should be added
