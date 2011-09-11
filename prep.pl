#!/usr/bin/env perl 

use strict;
use warnings;

# FILENAME: prep.pl
# CREATED: 11/09/11 16:32:06 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Prepare pre-selection merge info

use List::Util qw( first );
my ( $new, $append, $run, $nomerge );

if ( first { $_ eq '--new' } @ARGV ) {
  $new = 1;
  @ARGV = grep { $_ ne '--new' } @ARGV;
}
if ( first { $_ eq '--append' } @ARGV ) {
  $append = 1;
  @ARGV = grep { $_ ne '--append' } @ARGV;
}
if ( first { $_ eq '--run' } @ARGV ) {
  $run = 1;
  @ARGV = grep { $_ ne '--run' } @ARGV;
}
if ( first { $_ eq '--nomerge' } @ARGV ) {
  $nomerge = 1;
  @ARGV = grep { $_ ne '--nomerge' } @ARGV;
}

sub enote {
  *STDERR->print("\e[32m ** ", join q{ }, @_ , "\e[0m\n");
}

if ($new) {
  enote("Generating first 2000 new items");
  system( 'shuf', '-n', '2000', '-o', '/root/rebuilder/current.txt', '/root/rebuilder/brokens.all' ) and die;
}

open my $fh, "<", '/root/rebuilder/current.txt' or die;

my @builds = <$fh>;
chomp for @builds;
@builds = sort @builds;

my @cmdbase = (
  'resolve', '-1', '-c',
  '--permit-old-version' => '*/*',
  '--permit-downgrade'   => '*/*',
  '-H'                   => '>sys-block/parted-2.4',
  '-km',
  '-sa', '--continue-on-failure' => 'if-independent',
);

if ( not $nomerge and not $run ) {
  {
    enote("Doing first pass to fix metadata");
    open my $cave, '-|', 'sudo', '-i', 'cave', ( @cmdbase, @builds, '-Km', @ARGV ) or die;
    while ( defined( my $line = <$cave> ) ) { next; }
  }
  {
    enote("Computing changed depgraph");
    open my $cave, '-|', 'sudo' , '-i', 'cave', ( @cmdbase, @builds, '-Km', @ARGV ) or die;
    open my $caveout, '>', '/root/rebuilder/current.out' or die;
    while ( defined( my $line = <$cave> ) ) {
      $caveout->print($line);
    }
  }
}
if ( not $run ) {
  {
    my $mode = '>';
    $mode = '>>' if $append;
    enote("Updating rebuild file $mode");
    open my $rebuildtxt, $mode, '/root/rebuilder/rebuild.txt' or die;
    open my $depper, '-|', $^X, '/root/rebuilder/paludis_deps.pl', '/root/rebuilder/current.out' or die;

    $depper->autoflush(1);
    while ( defined( my $line = <$depper> ) ) {
      $rebuildtxt->print($line);
    }
  }
  {
    enote("Finding interesting changes");
    exec { $^X } 'filter_paludis_useflags', '/root/rebuilder/filter_paludis_useflags.pl',
      '/root/rebuilder/current.out';
  }
}
else {
  enote("Running build");
  exec {'sudo'} 'sudo', '-i', 'cave', @cmdbase, @builds, '-Kn', '-x', @ARGV;
}
