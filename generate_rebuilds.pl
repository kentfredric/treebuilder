#!/usr/bin/env perl 

use strict;
use warnings;

# FILENAME: generate_rebuilds.pl
# CREATED: 09/09/11 20:39:09 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: generate rebuild lists from rebuild sources
use 5.14.1;
use lib 'lib';
use corex;
use File::stat;
use File::Spec;

my $core = corex->new();
my @regexen;
my @brokenregexen;
{
  open my $regfh, '<', $core->rebuild_file('rebuild.txt') or die;
  while ( my $line = <$regfh> ) {
    chomp $line;
    next if $line =~ /^\s*#/;
    next if $line =~ /^\s*$/;
    $line =~ s/:.*$//;
    my $regex = qr{
    \Q$line\E
    (
      $
    |
      [[:space:]]
    |
      [^[:alpha:]]
      (
        $
        |
        [[:space:][:digit:]]
      )
    )
  }x;
    push @regexen, $regex;
  }
}
{
  open my $regfh, '<', $core->rebuild_file('broken.txt') or die;
  while ( my $line = <$regfh> ) {
    chomp $line;
    next if $line =~ /^\s*#/;
    next if $line =~ /^\s*$/;
    $line =~ s/:.*$//;
    my $regex = qr{
    (
      \Q$line\E$  # terminated
    |
      \Q$line\E[[:space:]] # simple
    |
      \Q$line\E-[\d] # version specific
    |
      \Q$line\E: # slotted
    )
    }x;
    push @brokenregexen, $regex;
  }
}

my $timestamp = stat( $core->rebuild_file('timestamp.x') )->mtime;

#open my $fh,  '<', $core->rebuild_file('newer_depends.txt') or die;
open my $wfh,  '>', $core->rebuild_file('rebuilds.out') or die;
open my $wbfh, '>', $core->rebuild_file('brokens.out')  or die;
open my $allfh , '>', $core->rebuild_file('brokens.all') or die;
open my $uniquefh, '>', $core->rebuild_file('brokens.unique') or die;
open my $dupfh, '>', $core->rebuild_file('brokens.duplicate') or die;

my %rebuild_cache;
my %broken_cache;
my %all_cache;

$core->old_dependency_files(
  sub {
    my $file    = shift;
    my $package = $core->dep_file_to_pkgdir($file);

    open my $grepfile, '<', $file or die;

    my $schema = sub {
      return state $schemaval = $core->dep_file_to_cpv($file);
    };

    INP: while ( my $sourceline = <$grepfile> ) {
      if ( not exists $rebuild_cache{$package} ) {
        foreach my $re (@regexen) {

          #      print ">~ $re\n";
          next unless $sourceline =~ $re;
          print "+ rebuild " . $schema->() . "\n";
          $wfh->print( $schema->() . "\n" );
          $rebuild_cache{$package} = 1;
          $all_cache{$schema->()}++;
          #print "+ $file due to $re\n";
          last INP;
        }
      }
    }
    if ( not exists $broken_cache{$package} ) {
        foreach my $re (@brokenregexen) {

          next unless $package =~ $re;
          last if exists $broken_cache{$schema->()};
          print "+ broken " . $schema->() . "\n";
          $wbfh->print( $schema->() . "\n" );
          $broken_cache{$package} = 1;
          $broken_cache{$schema->()} = 1;
          $all_cache{$schema->()}++;
         
          last;
        }
      }
  },
  $timestamp
);
foreach my $p ( sort keys %all_cache ){
  $allfh->print("$p\n");
  if( $all_cache{$p} == 1 ){
    $uniquefh->print("$p\n");
  } else {
    $dupfh->print("$p\n");
  }
r
