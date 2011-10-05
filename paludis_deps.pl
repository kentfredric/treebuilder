#!/usr/bin/env perl 

use strict;
use warnings;
# FILENAME: paludis_deps.pl
# CREATED: 10/09/11 21:27:13 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Extract dependencies from Paludis pretend output

my %stash;

while( defined ( my $line = <> )){
  next unless $line =~ /^[urv]\s*([^:]*):([^:]*)::/;
  my $label = "$1:$2";
  $label =~ s{\e\[(\d+;)*\d+m}{}g;

  $stash{"$label"}++;
}
for my $k ( sort keys %stash ){
  print "$k\n";
}
