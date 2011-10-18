use 5.14.2;
use strict;
use warnings;

package corex;

# FILENAME: corex.pm
# CREATED: 09/09/11 12:16:58 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: core libraries for my rebuilder tool

use Moose;
use Path::Class::Dir;
use File::stat;
use File::Next;
use File::Basename;

has vdb => ( isa => 'Str', is => 'rw', default => '/var/db/pkg' );

has depend => ( isa => 'RegexpRef', is => 'rw', default => sub { qr/\/[A-Z]*DEPEND$/ } );

has 'rebuilder_root' => ( isa => 'Str', is => 'rw', default => '/root/rebuilder' );

{
  no warnings 'redefine';
  require File::Spec::Unix;

  sub File::Spec::Unix::catdir {
    shift;
    return ( join q{/}, @_ );
  }
}

sub rebuild_file {
  my ( $self, $filename ) = @_;
  return $self->rebuilder_root . '/' . $filename;
}

sub all_dependency_files {
  my ( $self, $callback ) = @_;
  my $it     = File::Next::files( $self->vdb );
  my $depend = $self->depend;
  while ( defined( my $file = $it->() ) ) {
    next unless $file =~ $depend;
    $callback->($file);
  }
}

sub old_dependency_files {
  my ( $self, $callback, $timestamp ) = @_;
  $self->all_dependency_files(
    sub {
      my $file = shift;
      if ( stat($file)->mtime <= $timestamp ) {
        return $callback->($file);
      }
    }
  );
}

sub new_dependency_files {
  my ( $self, $callback, $timestamp ) = @_;
  $self->all_dependency_files(
    sub {
      my $file = shift;
      if ( stat($file)->mtime > $timestamp ) {
        return $callback->($file);
      }
    }
  );
}

sub dep_file_to_pkgdir {
  my ( $self, $file ) = @_;
  $file =~ s{\/[^/]+$}{};
  return $file;
}

sub pkgdir_to_cat {
  my ( $self, $dir ) = @_;
  my $vdb = $self->vdb;
  $dir =~ s/^\Q$vdb\E\/?//;
  $dir =~ s/\/.*$//;
  return $dir;
}

sub pkgdir_strip_to_p {
  my ( $self, $dir, $v ) = @_;
  my $vdb = $self->vdb;
  $dir =~ s/^\Q$vdb\E\/?//;

  # $dir =~ s{/[^/]*$}{};
  $dir =~ s{-\Q$v\E$}{};
  return $dir;

}

sub dep_file_to_cpv {
  my ( $self, $file , $opts ) = @_;
  $opts //= { };
  $opts->{want} //= {};
  $opts->{want}->{$_} //= 0 for qw( CATEGORY PN );

  $opts->{want}->{$_} //= 1 for qw( SLOT PVR );
  state $cache = {};
  my $key = join(q{}, map { $opts->{want}->{$_} } sort keys %{ $opts->{want} });

  my $dir = $self->dep_file_to_pkgdir($file);

  return $cache->{$dir}->{$key} if exists $cache->{$dir} and exists $cache->{$dir}->{$key};

  open my $fh, '-|', 'bzcat', $dir . '/environment.bz2' or die;
  my %hash;
  my $done = sub {
    return ( 
      ( not $opts->{want}->{$_[0]} ) or  ( exists $hash{$_[0]} )
    );
  };
  my $alldone = sub { 
    for ( @_ )  {
      return if not $done->($_);
    }
    return 1;
  };

  #print ">";
  while ( my $line = <$fh> ) {
    chomp $line;
    
    last if $alldone->(qw( CATEGORY PN SLOT PVR ));

    if ( ! $done->(qw(CATEGORY)) and $line =~ /^CATEGORY=(.*$)/ ) {

      #print "|";
      $hash{CATEGORY} = $1;
      next;
    }

    #next unless exists $hash{CATEGORY};
    if ( ! $done->(qw(PN)) and $line =~ /^PN=(.*$)/ ) {

      #print "^";
      $hash{PN} = $1;
      next;
    }

    #next unless exists $hash{PN};
    if ( ! $done->(qw( PVR )) and $line =~ /^PVR=(.*$)/ ) {

      #print "&";
      $hash{PVR} = $1;
      next;
    }

    #next unless exists $hash{PV};
    if ( !$done->(qw( SLOT )) and $line =~ /^SLOT=(.*$)/ ) {

      #print "*";
      $hash{SLOT} = $1;
      next;
    }

    #next unless exists $hash{SLOT};
    #print '.';
  }

  #print "<\n";
  my $x = $self->pkgdir_strip_to_p( $dir, $hash{PVR} ) . q{:} . $hash{SLOT};

  #print "$x\n";
  $cache->{$dir}->{$key} = $x;
  return $x;    #. ':' . $hash{SLOT};
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

