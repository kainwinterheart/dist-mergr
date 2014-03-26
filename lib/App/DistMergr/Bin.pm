use strict;
use warnings;

package App::DistMergr::Bin;

use boolean;

use Moose;

use Module::Load 'load';


has 'options' => ( is => 'ro', isa => 'HashRef', required => true, traits => [ 'Hash' ], handles => { opt => 'get' } );

has 'spec' => ( is => 'ro', isa => 'App::DistMergr::Spec', lazy => true, builder => 'build_spec' );


sub main
{
	my $self = shift;

	my $mode = $self -> opt( 'mode' );
	my $method = sprintf( 'mode_%s', $mode );

	if( $self -> can( $method ) )
	{
		return $self -> $method();
	}

	die sprintf( 'Unknown mode: %s', $mode );
}

sub mode_copy
{
	my $self = shift;

	my $spec = $self -> spec();
	my $helper = $spec -> lib_helper();

	$helper -> copy_to( $spec -> dest(), ( $spec -> has_lib_filelist() ? $spec -> lib_filelist() : () ) );

	return;
}

sub mode_patch
{
	my $self = shift;

	my $spec = $self -> spec();
	my $helper = $spec -> patch_helper();

	$helper -> cmd( $spec -> patch_cmd() );

	$helper -> apply_to( $spec -> dest(), ( $spec -> has_patch_filelist() ? $spec -> patch_filelist() : () ) );

	return;
}

sub build_spec
{
	my $self = shift;

	load my $pkg = 'App::DistMergr::Spec';

	return $pkg -> new_from_file( $self -> opt( 'spec' ) );
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

