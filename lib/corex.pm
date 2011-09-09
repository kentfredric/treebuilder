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

has depend => ( isa => 'RegexpRef', is => 'rw', default => sub { qr/\/[A-Z]*DEPEND$/ });

has 'rebuilder_root' => ( isa => 'Str', is => 'rw', default => '/root/rebuilder' );

{
  no warnings 'redefine';
  require File::Spec::Unix;
  sub File::Spec::Unix::catdir {
    shift;
    return ( join q{/}, @_  );
  }
}

sub rebuild_file {
  my ( $self, $filename ) = @_ ;
  return $self->rebuilder_root . '/' . $filename;
}
sub all_dependency_files {
  my ( $self, $callback ) = @_;
 my $it = File::Next::files( $self->vdb );
  my $depend = $self->depend;
  while ( defined ( my $file = $it->() ) ){ 
    next unless $file =~ $depend;
    $callback->( $file );
  }
}

sub old_dependency_files {
  my ( $self, $callback, $timestamp )  = @_;
  $self->all_dependency_files(sub{
    my $file = shift; 
    if ( stat($file)->mtime <= $timestamp ){ 
      return $callback->( $file );
    }
  });
}
sub new_dependency_files {
  my ( $self, $callback, $timestamp )  = @_;
  $self->all_dependency_files(sub{
    my $file = shift; 
    if ( stat($file)->mtime > $timestamp ){ 
      return $callback->( $file );
    }
  });
}

sub dep_file_to_pkgdir {
  my ( $self, $file ) = @_;
  $file =~ s{\/[^/]+$}{};
  return $file;
}

sub pkgdir_to_cat {
  my ( $self , $dir ) = @_; 
  my $vdb = $self->vdb;
  $dir =~ s/^\Q$vdb\E\/?//;
  $dir =~ s/\/.*$//;
  return $dir;
}

sub dep_file_to_cpv {
  my ( $self, $file ) = @_ ;
  my $dir = $self->dep_file_to_pkgdir( $file );
  open my $fh ,'-|', 'bzcat', $dir . '/environment.bz2' or die;
  my %hash;
  while( my $line = <$fh> ){
    chomp $line;
    last if exists $hash{CATEGORY} and exists $hash{PN} and exists $hash{SLOT};
    if( $line =~ /^CATEGORY=(.*$)/ ) {
      $hash{CATEGORY} = $1;
      next
    }
    if( $line =~ /^PN=(.*$)/ ) {
      $hash{PN} = $1;
      next
    }
    if( $line =~ /^SLOT=(.*$)/ ){
      $hash{SLOT} = $1;
      next;
    }
  }
  return $self->pkgdir_to_cat( $dir ) . '/' . $hash{PN} ;#. ':' . $hash{SLOT};
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;


