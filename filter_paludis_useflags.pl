#!/usr/bin/env perl 

use strict;
use warnings;

# FILENAME: filter_paludis_useflags.pl
# CREATED: 10/09/11 21:34:58 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: find interesting useflag changes in paludis output

my $package;
use Data::Dump qw( dump );
use Term::ANSIColor qw( colorstrip );
sub extract_linepart {
  my ( $line, $package ) = @_;
  my $bad = "?\e[31m";
  $package //= {
    change      => $bad,
    category    => $bad,
    packagename => $bad,
    slot        => $bad,
    cpv         => $bad,
    version     => $bad,
    repository  => $bad,
    has         => [],
  };
  my $exit = 1;

  my $X = qr{(?:\e\[(?:\d+;)*\d+m)*};

parser: {
    if ( $line =~ /^\s*([nurv])\s*(.*$)/ ) {
      $package->{change} = "$1";
      push $package->{has}, 'change';
      $line ="$2";
    }
    else { $exit = 0; last parser; }

    if ( $line =~ /^($X[a-z0-9-]+)\/(.*$)/ ) {
      $package->{category} = "$1";
      $line = "$2";
      push $package->{has}, 'category';

    }
    else { $exit = 0; last parser; }

    if ( $line =~ qr{^([^:]+):(.*$)} ) {
      $package->{packagename} = $1;
      $line                   = $2;
      $package->{cpv}         = $package->{category} . "/" . $package->{packagename};
      push $package->{has}, 'packgename', 'cpv';

    }
    else { $exit = 0; last parser; }

    if ( $line =~ qr{^([^:]+)::(.*$)} ) {
      $package->{slot} = $1;
      $line = $2;
      push $package->{has}, 'slot';

    }

    else { $exit = 0; last parser; }

    if ( $line =~ qr{^([^\s]+)\s*(.*$)} ) {
      $package->{repository} = $1;
      $line = $2;
      push $package->{has}, 'repository';

    }
    else { $exit = 0; last parser; }

    $line =~ s{^\([^)]+\)\s*}{};

    if ( $line =~ qr{^([^\s]+)\s*(.*$)} ) {
      $package->{version} = $1;
      $line = $2;
      push $package->{has}, 'version';

    }
    else { $exit = 0; last parser; }

  }

  $package->{quick} =
    sprintf "%s:%s::%s %s",
    $package->{cpv},
    $package->{slot}, $package->{repository},
    $package->{version};

  $package->{rest} = $line;

  $package->{dumped} = dump $package;

  $_[0] = $line;
  $_[1] = $package;
  return $exit;
}
use Term::ANSIColor qw(colorstrip);
sub extract_useflags {
  my ( $line, $sections, $package ) = @_;
  $sections //= {};
  return 0 unless $line =~ /^\s+(.*)build_options:\s+/;
  my $flags = colorstrip($1);
  my $label = 'USE';

  while ( $flags =~ /\G(.+?)(\s+([A-Z_]+):\s+|\s*$)/g ) {
    $sections->{$label} = { flags => $1 };
    $label = $3;
  }
  for my $key ( keys $sections ) {
    my @ignored;
    $sections->{$key}->{flags} =~ s{(\([^)]+\)[+*-]?)\s*}{
        push @ignored, "$1";
        ""
      }gxe;
    if (@ignored) {
      $sections->{$key}->{ignored} = \@ignored;
    }
    my @tokes = split /\s+/, $sections->{$key}->{flags};
    $sections->{$key}->{flagtokes} = @tokes;
    my @ctokes = map {

      if ( $_ =~ /^-.+\-$/ ) {
        "\e[31;44m$_\e[0m";
      }
      elsif ( $_ =~ /^-.+\+$/ ) {
        "\e[31;44m$_\e[0m";
      }
      elsif ( $_ =~ /^[^-].+\-$/ ) {
        "\e[31;44m$_\e[0m";
      }
      elsif ( $_ =~ /^[^-][^+]+\+$/ ) {
        "\e[32;44m$_\e[0m";
      }
      elsif ( $_ =~ /^-.+$/ ) {
        "$_";
      }
      elsif ( $_ =~ /^[^-].*(?![+-])$/i ) {
        "\e[32m$_\e[0m";
      }
      else {
        "\e[34m$_\e[0m";
      }

    } @tokes;
    $sections->{$key}->{cflags} = join q{ }, @ctokes;
  }
  print $package->{change} eq 'n' ? "\e[36m" : "";
  print $package->{change} . " ";
  print $package->{quick} . " " . join qq{  }, (), map { "\e[33m$_ =>\e[0m " . $sections->{$_}->{cflags} } sort keys $sections;
  print "\n";

}
while ( defined( my $line = <> ) ) {
  my $xpackage;
  if ( extract_linepart( $line, $xpackage ) ) {
    $package = $xpackage;

    #    print $xpackage->{dumped};
  }
  #print $xpackage->{dumped};

  extract_useflags( $xpackage->{rest}, {}, $package );

}
