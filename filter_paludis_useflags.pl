#!/usr/bin/env perl 

use strict;
use warnings;
# FILENAME: filter_paludis_useflags.pl
# CREATED: 10/09/11 21:34:58 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: find interesting useflag changes in paludis output

my $package;
use Data::Dump qw( dump );
while ( defined ( my $line = <> ) ){ 
  if(  $line =~ /^([urv])\s+([^:]*):([^:]*)::([^\s]+)\s+([^\s]+)/ ){
    $package = {
      change => $1,
      cpv => $2,
      slot => $3,
      repo => $4,
      version => $5,
      quick => "$1 $2:$3::$4 $5",
    };
  }
  if( $line =~/^\s+(.*)build_options:\s+/ ){
    my $build_opts = $1;
    my %sections; 
    my $label = 'USE';
    while( $build_opts =~ /\G(.+?)(\s+([A-Z_]+):\s+|\s*$)/g ){
      $sections{$label} = { flags => $1 };
      $label = $3;
    }
    for my $key ( keys %sections ){
      my @ignored;
      $sections{$key}->{flags} =~ s{(\([^)]+\))\s*}{
        push @ignored, "$1";
        ""
      }gxe;
      if( @ignored ){
        $sections{$key}->{ignored} = \@ignored;
      }
      my @tokes = split /\s+/, $sections{$key}->{flags};
      $sections{$key}->{flagtokes} = @tokes;
      my @ctokes = map {
        
        if( $_ =~ /^-.+\-$/ ) {
          "\e[31;44m$_\e[0m"
        } elsif( $_ =~ /^-.+\+$/ ){
          "\e[31;44m$_\e[0m"
        } elsif ( $_ =~ /^[^-].+\-$/ ){
          "\e[31;44m$_\e[0m"
        } elsif ( $_ =~ /^[^-][^+]+\+$/ ){
          "\e[32;44m$_\e[0m"
        } elsif ( $_ =~ /^-.+$/ ) {
          "$_"
        } elsif ( $_ =~ /^[^-].*(?![+-])$/i ){
          "\e[32m$_\e[0m"
        } else {
          "\e[34m$_\e[0m"
        }

      } @tokes;
      $sections{$key}->{cflags} = join q{ }, @ctokes;
    }
    print $package->{quick} . " " . join qq{  }, (), map {
       "\e[33m$_ =>\e[0m "  . $sections{$_}->{cflags}
    } sort keys %sections;
    print "\n";
  }

}
