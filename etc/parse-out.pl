
# Simple script to parse the output of concatenated Benchmark.pl runs
# and print statistics.

use strict;
use warnings;

use Statistics::Descriptive;

my %stats = ( );

while (my $line = <>) {
  chomp($line);
  if ($line =~ /^Benchmark/) {
  } elsif ($line =~ /^(.+)\:\s+(\d+) wallclock secs \(\s*(\d+\.\d+)/) {
    my $name = $1;
    my $utim = $3;

    unless (exists $stats{$name}) {
      $stats{$name} = Statistics::Descriptive::Full->new();
    }
    $stats{$name}->add_data($utim);
  } else {
#    print STDERR $line, "\n";
  }
}



foreach my $name (sort keys %stats) {
  print $name, "\n  ",
    join(" ", map { sprintf('%5.2f', $_||0) }
      $stats{$name}->count(),
      $stats{$name}->min(),
      $stats{$name}->mean(),
      $stats{$name}->median(),
      $stats{$name}->max(),
      $stats{$name}->variance(),
      $stats{$name}->standard_deviation(),
    
    ), "\n";
}
