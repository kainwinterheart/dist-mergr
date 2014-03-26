use strict;
use warnings;

package App::DistMergr::Helpers::Lib;

use boolean;

use Moose;

extends 'App::DistMergr::Helpers::Base::Dir';

use File::Copy 'copy';

use File::Spec ();

use namespace::autoclean;


sub copy_to
{
	my $self = shift;
	my $dest = shift;

	my $list = undef;
	my $has_list = false;

	if( scalar( @_ ) == 1 )
	{
		$list = shift;
		$has_list = true;
	}

	unless( -e $dest )
	{
		mkdir $dest;

		chmod 0755, $dest;
	}

	my @callbacks = (
		file => sub
		{
			return $self -> file_callback( $_[ 0 ], $dest );
		},
		dir => sub
		{
			return $self -> dir_callback( $_[ 0 ], $dest );
		}
	);

	if( $has_list )
	{
		$self -> process_filelist( $list, @callbacks );

	} else
	{
		$self -> scan_dir( @callbacks );
	}

	return;
}

sub file_callback
{
	my ( $self, $source, $dest ) = @_;

	$dest = File::Spec -> catfile( $dest, $self -> as_relative_path( $source ) );

	copy( $source, $dest ) || die $dest, ' ', $!;

	return;
}

sub dir_callback
{
	my ( $self, $source, $dest ) = @_;

	$dest = File::Spec -> catfile( $dest, $self -> as_relative_path( $source ) );

	unless( -d $dest )
	{
		mkdir $dest;

		chmod 0755, $dest;
	}

	return;
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

