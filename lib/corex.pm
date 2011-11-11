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

has depend =>
  ( isa => 'RegexpRef', is => 'rw', default => sub { qr/\/[A-Z]*DEPEND$/ } );

has 'rebuilder_root' =>
  ( isa => 'Str', is => 'rw', default => '/root/rebuilder' );

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

sub cache_gen {
    my $alias = shift;
    require CHI;
    return CHI->new(
        driver         => 'File',
        root_dir       => '/tmp/rebuilder-cache/',
        expires_in     => '5 hours',
        label          => $alias,
        namespace      => $alias,
        max_key_length => '80',
    );

}

sub _real_dep_file_to_cpv {
    my ( $self, %c ) = @_;
    my $file = $c{file};
    my $opts = $c{opts};

    my $dir = $self->dep_file_to_pkgdir( $c{file} );

    my $hash = $self->dep_file_to_cpv_hash( $file, $opts );

    my $x = $self->pkgdir_strip_to_p( $dir, $hash->{PVR} ) . q{:} . $hash->{SLOT};
    return $x;

}

sub _real_dep_file_to_cpv_hash {
    my ( $self, %c ) = @_;
    my $file = $c{file};
    my $opts = $c{opts};

    my $dir = $self->dep_file_to_pkgdir( $c{file} );
    open my $fh, '-|', 'bzcat', $dir . '/environment.bz2' or die;
    my %hash;
    my $done = sub {
        return (
                 ( not $opts->{want}->{ $_[0] } )
              or ( exists $hash{ $_[0] } )
        );
    };
    my $alldone = sub {
        for (@_) {
            return if not $done->($_);
        }
        return 1;
    };

    #print ">";
    while ( my $line = <$fh> ) {

        chomp $line;

        last if $alldone->(qw( CATEGORY PN SLOT PVR ));

        if ( !$done->(qw(CATEGORY)) and $line =~ /^CATEGORY=(.*$)/ ) {

            #print "|";
            $hash{CATEGORY} = $1;
            next;
        }

        #next unless exists $hash{CATEGORY};
        if ( !$done->(qw(PN)) and $line =~ /^PN=(.*$)/ ) {

            #print "^";
            $hash{PN} = $1;
            next;
        }

        #next unless exists $hash{PN};
        if ( !$done->(qw( PVR )) and $line =~ /^PVR=(.*$)/ ) {

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
    return \%hash;
}


sub _pre_opts {
    my ( $self, $opts, $file ) = @_;
    $opts //= {};
    $opts->{want} //= {};
    $opts->{want}->{$_} //= 0 for qw( CATEGORY PN );
    $opts->{want}->{$_} //= 1 for qw( SLOT PVR );

    my $key =
      $file . '-w-'
      . join( q{},
        map { $opts->{want}->{$_} ? 1 : 0 } sort qw( CATEGORY PN SLOT PVR ) );
    $key =~ s{/}{_}g;
    $key =~ s{\.}{_}g;
    return ( $opts, $key );
}

sub dep_file_to_cpv_hash {
    state $chicache = cache_gen('dep-file-to-cpv-hash');
     my ( $self, $file, $opts ) = @_;
     my ($key);
    ( $opts, $key ) = $self->_pre_opts( $opts, $file );
    my $result = $chicache->compute(
     $key,
        {},
        sub {
            return $self->_real_dep_file_to_cpv_hash(
                file => $file,
                opts => $opts,
            );
        }
    );
    return $result;
}
sub dep_file_to_cpv {
    state $chicache = cache_gen('dep-file-to-cpv');
    my ( $self, $file, $opts ) = @_;
    my ($key);

    ( $opts, $key ) = $self->_pre_opts( $opts, $file );

    my $result = $chicache->compute(
        $key,
        {},
        sub {
            return $self->_real_dep_file_to_cpv(
                file => $file,
                opts => $opts,
            );
        }
    );
    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

