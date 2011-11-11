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
use Term::ANSIColor qw( :constants );

my $core = corex->new( depend => qr/\/R?DEPEND$/ );
*STDOUT->autoflush(0);
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
    push @regexen, [ $regex, $line ];
  }
}
{
  open my $regfh, '<', $core->rebuild_file('broken.txt') or die;
  while ( my $line = <$regfh> ) {
    chomp $line;
    next if $line =~ /^\s*#/;
    next if $line =~ /^\s*$/;
    my $slot = 0;
    if ( $line =~ /:(.*)$/ ) {
      $slot = "$1";
	    $line =~ s/:.*$//;
    }
    my $regex = qr{
    (
      \Q$line\E$  # terminated
    |
      \Q$line\E[[:space:]] # simple
    |
      \Q$line\E-[\d] # version specific
    )
    }x;
    push @brokenregexen, [ $regex , $line , $slot ];
  }
}

my $timestamp = stat( $core->rebuild_file('timestamp.x') )->mtime;

#open my $fh,  '<', $core->rebuild_file('newer_depends.txt') or die;
open my $wfh,      '>', $core->rebuild_file('rebuilds.out')      or die;
open my $wbfh,     '>', $core->rebuild_file('brokens.out')       or die;
open my $allfh,    '>', $core->rebuild_file('brokens.all')       or die;
open my $uniquefh, '>', $core->rebuild_file('brokens.unique')    or die;
open my $dupfh,    '>', $core->rebuild_file('brokens.duplicate') or die;

my %rebuild_cache;
my %broken_cache;
my %all_cache;

my (%rebuild, %broken, %processed );

$core->old_dependency_files(
  sub {
    my $file    = shift;
    my $b = $file;
    $b =~ s[^.*/([^/]+)$][$1];
    my $package = $core->dep_file_to_pkgdir($file);

    open my $grepfile, '<', $file or die;

    my $schemahash = sub {
      return state $schemaval = $core->dep_file_to_cpv_hash($file);

    };
    my $schema = sub {
      return state $schemaval = $core->dep_file_to_cpv($file);
    };
    #say $file;
    #return if ( exists $broken_cache{$package} );
    #return if ( exists $rebuild_cache{$package} );
    #return if ( exists $processed{$package}  );
    #$processed{$package} = 1;
  INP: while ( my $sourceline = <$grepfile> ) {
      if ( not exists $rebuild_cache{$package} ) {
        foreach my $re (@regexen) {

          #      print ">~ $re\n";
          next unless $sourceline =~ $re->[0];
          my $s = $schema->();
          print BLUE . "+ rebuild $s ( $b  : $re->[1] )" . RESET . "\n";
          #$wfh->print("$s\n");
          $rebuild_cache{$package} = 1;
          $rebuild{$s}++;
          $all_cache{$s}++;

          #print "+ $file due to $re\n";
          last INP;
        }
      }
    }
    XINP: {

    if ( not exists $broken_cache{$package} ) {
      foreach my $re (@brokenregexen) {
        next unless $package =~ $re->[0];
        my $slot = $re->[2];
 #       print " $package matches " . $re->[0]. "\n";;
        my $s = $schema->();
        my $h = $schemahash->();
        require Data::Dump;
        if( $h->{SLOT} ne $slot ) {
          print "$s != $s + $slot \n";
          next;
        }
        last if exists $broken_cache{$s};
      
#        print(Data::Dump::pp($h));
        print YELLOW . "+ broken $s" . RESET . "\n";

        #$wbfh->print( "$s\n" );
        $broken_cache{$package} = 1;
        $broken_cache{$s}       = 1;
        $all_cache{$s}++;
        $broken{$s}++;
        last XINP;
      }
      #if ( not exists $broken_cache{$package} and not exists $rebuild_cache{$package} ){ 
      #  my $s = $schema->();
      #  print GREEN . "- skip $s ( $b )" . RESET . "\n";
      #}
    }
  }
  },
  $timestamp
);
foreach my $p ( sort { $a cmp $b } keys %all_cache ) {
  $allfh->print("$p\n");
  if ( $all_cache{$p} == 1 ) {
    $uniquefh->print("$p\n");
  }
  else {
    $dupfh->print("$p\n");
  }
}
foreach my $p ( sort { $a cmp $b } keys %broken ) {
  $wbfh->print("$p\n");
}
foreach my $p ( sort { $a cmp $b } keys %rebuild ) {
  $wfh->print("$p\n");
}
