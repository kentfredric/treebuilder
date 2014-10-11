use strict;
use warnings;

use Path::Tiny qw( path );

my (@lines) = path( 'broken.txt' )->lines_raw({ chomp => 1 });

my (@recs);

my $re = qr{
	^
	( [^/]+ )
	/
	( [^:]+ )
	(?:
		:
		(.*)
	)
}x;

my $cache = {};
sub dcache {
	my ( $path ) = @_;
	return @{ $cache->{$path} } if exists $cache->{$path};
	return @{ $cache->{$path} = [ $path->children ] };
}
for my $line ( @lines ) {
	my ( $cat, $pkg, $slot ) = $line =~ $re;
	if ( not $cat ) {
		warn "Cant divine cat from $line";
		next;
	}
	if ( not $pkg ) {
		warn "Cant divine pkg from $line";
		next;
	}

	
	my $catdir = path('/var/db/pkg/' . $cat  );
	my $m;
	for my $child ( dcache($catdir) ) { 
		next unless $child->basename =~ /^\Q$pkg\E-/;
		my $stat = $child->child('CONTENTS')->stat->mtime;
		$m = $stat if not defined $m or $stat > $m;
	}
	if ( not $m ) {
		warn "\e[31m is $line installed? \e[0m";
		next;
	}
	push @recs, [ $line, $m ];
}
for my $record ( sort { $a->[1] <=> $b->[1] } @recs ) { 
	printf "%s\n", $record->[0];
}

