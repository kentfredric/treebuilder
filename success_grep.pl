#!/usr/bin/env perl
use 5.16.0;
use strict;
use warnings;
use Data::Dump qw( pp );

open my $fh, '<', '/var/log/paludis_success.log';

my $sig = $ARGV[0];

my @match;
my @postmatch;

while(1){
	my $line = <$fh>;
	last if not defined $line;
	next unless $line =~ /success\s+install/;
	if ( $line =~ /\Q$sig\E/ ){ 
		chomp $line;
		push @match, [ $line, $. ];
		last;
	}
}
my $keep_push = 0;

while(1){
	my $line = <$fh>;
	my $skip_keep = 0;
	last if not defined $line;
	chomp $line;
	next unless $line =~ /success\s+install/;
	if ( $line =~ /\Q$sig\E/ ){
		push @postmatch, $match[-1][0];
		push @postmatch, $line;
		$keep_push  = 1;
		$skip_keep = 1;
	}
	if ( $keep_push and not $skip_keep) {
		$keep_push--;
		push @postmatch, $line;
	}
	push @match, [ $line, $. ];
	$line =~ s/^.* : //;
	$line =~ s/::.*$//;
	$line =~ s/-r\d+:/:/;
	$line =~ s/_beta\d*:/:/;
	$line =~ s/_rc\d*:/:/;
	$line =~ s/(-[0-9.]+)+:/:/;
	say $line;
}
my (@indices) = (
	0, 1, 2, 
	$#match - 3, 
	$#match - 2,
	$#match - 1,
	$#match
);
for my $i (  @indices ) {
	*STDERR->say("$i => " . pp( $match[$i] ));
}
for my $i ( @postmatch ) {
	*STDERR->say("\e[31m $i\e[0m");
}
