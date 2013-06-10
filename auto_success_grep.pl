#!/usr/bin/perl 
use v5.16;
use warnings;
use Path::Tiny qw( path );
use Scalar::Util qw( refaddr );


my $ts_file = path('/root/rebuilder/paludis_success.ts');

my $timestamp = do { my $x = $ts_file->slurp(); chomp $x; $x };

say "looking for new install successes after $timestamp";

my $auto_success = path('/root/rebuilder/rebuild.txt')->opena();

my  $filereader = FileReader->new( 
	source_fd => path('/var/log/paludis_success.log')->openr(),
);

if ( $filereader->seek_to_match( qr/^\Q$timestamp\E/ ) ) {
	say "Found timestamp at l" . $filereader->user_pos;
	while( $filereader->seek_to_match( qr/success\s+install/ ) ) { 
		my $line = $filereader->getline;
		if ( my $desc = assemble_distname( parse_distname( $line )) ) {
			say "Found good: \e[31m$desc \e[0m\n\e[37m>> $line \e[0m";
			$auto_success->say( $desc );
		}
	}
}
$filereader->rewind_to_match( qr/^\+/ );
{ 
	my $wh = $ts_file->openw;
	my $new_timestamp = $filereader->getline;
	chomp($new_timestamp);
	$wh->print($new_timestamp);
	$wh->close;
}

exit 0;
sub assemble_distname { 
	my ($conf) = @_;
	return unless $conf;
	return sprintf '%s/%s:%s', $conf->{cat}, $conf->{pkg_simple} , $conf->{slot};
}
sub parse_distname { 
	my ( $line ) = @_ ; 
	if ( $line =~ qr{  ([^\s]+) [/] ([^\s]+) [:] ([^\s]+) [:]{2} ([^\s]+) }x ){
		my $res = { cat => "$1" , pkg => "$2", slot => "$3", overlay => "$4" };
		my $pkg_f = $res->{pkg};
		$pkg_f =~ s{ ( -r\d+	| _beta\d* | _rc\d* | -[0-9.]+ | _p\d* | _pre\d* )+$}{}x;
		$res->{pkg_simple} = $pkg_f;
		return $res;
	};
	return;
}

BEGIN { 

	package FileReader;

	use Moose;

	has 'lines' => (
		isa => ArrayRef =>,
		is  => rw =>,
		lazy => 1,
		default => sub { [] },
	);

	has source_fd => ( is => rw =>, required => 1, );
	has source_line => ( isa => Int  =>, is => rw =>, lazy => 1, default => sub { 0 } );
	has source_eof  => ( isa => Bool =>, is => rw =>, lazy => 1, default => sub { undef } );
	has user_pos => ( isa => Int =>, is => rw =>, lazy => 1, default => sub { 0 } );


	sub _spool_next_line { 
		my ( $self ) = @_;
		return if $self->source_eof;
		if ( defined ( my $line = $self->source_fd->getline ) ) { 
			$self->lines->[ $self->source_line ] = $line;
			$self->source_line( $self->source_line + 1 );
			return $line;
		}
		$self->source_eof(1);
		return;
	}
	sub getline {
		my ( $self ) = @_;
		if ( not $self->lines->[ $self->user_pos ] and not $self->source_eof ) {
			$self->_spool_next_line;
		}
		if ( not $self->lines->[ $self->user_pos ] and $self->source_eof ) {
			return;
		}
		my $result = $self->lines->[ $self->user_pos ];
		$self->user_pos( $self->user_pos + 1 );
		return $result;
	}
	sub seek_to_match {
		my ( $self, $match ) = @_;
		while( my $line = $self->getline ){ 
			next unless $line =~ $match;
			$self->user_pos( $self->user_pos - 1 );
			return 1;
		}
		return;	
	}
	sub rewind_to_match { 
		my ( $self, $match )  = @_;
		my $p = $self->user_pos;
		while( $p >  0 ){
			my $line = $self->lines->[ $p - 1 ];
			if ( $line =~ $match ) { 
				$self->user_pos( $p - 1 );
				return 1;
			}
			$p = $p - 1;
		}
		return;
	}
	__PACKAGE__->meta->make_immutable;
}


