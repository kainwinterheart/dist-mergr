use strict;
use warnings;

package App::DistMergr::Spec;

use boolean;

use Moose;
use MooseX::StrictConstructor;

use Moose::Util::TypeConstraints 'find_type_constraint';

use Perl6::Slurp 'slurp';

use YAML::Syck 'Load';

use Module::Load 'load';

use namespace::autoclean;


has 'patch_cmd' => ( is => 'ro', isa => 'Str', lazy => true, default => 'patch -p0 < %s # %s' );

foreach my $dir ( (
	'lib',
	'patch',
	'dest'
) )
{
	has $dir => ( is => 'ro', isa => 'Str', lazy => true, default => $dir );

	has sprintf( '%s_filelist', $dir ) => ( is => 'ro', isa => 'ArrayRef[Str]', predicate => sprintf( 'has_%s_filelist', $dir ) );

	my $builder = sprintf( 'build_%s_helper', $dir );

	__PACKAGE__ -> meta() -> add_method( $builder => sub
	{
		my $self = shift;

		load my $pkg = sprintf( 'App::DistMergr::Helpers::%s', ucfirst( $dir ) );

		return $pkg -> new( path => $self -> $dir() );
	} );

	has sprintf( '%s_helper', $dir ) => ( is => 'ro', isa => 'App::DistMergr::Helpers::Base::Dir', lazy => true, builder => $builder );
}


sub new_from_file
{
	my ( $proto, $file ) = @_;

	my $text = slurp( $file );

	my $data = Load( $text );

	$data = {} unless defined $data;

	my $tc = find_type_constraint( 'HashRef' );

	die unless defined $tc;

	$tc -> assert_valid( $data );

	return $proto -> new( %$data );
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

