#!/usr/bin/env perl 

use strict;
use warnings;

# FILENAME: newer_depends_than.pl
# CREATED: 09/09/11 12:38:56 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Generate all new depends

use lib 'lib';
use corex;
use File::stat;
use File::Spec;

my $core = corex->new();

my $timestamp = stat( $core->rebuild_file('timestamp.x') )->mtime;
open my $fh, '>', $core->rebuild_file('newer_depends.txt') or die;
$core->old_dependency_files(
  sub {
    my ($file) = @_;
    $fh->print("$file\n");
  },
  $timestamp
);
