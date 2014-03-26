use strict;
use warnings;

package App::DistMergr::Helpers::Base::Dir;

use boolean;

use Moose;

use Moose::Util::TypeConstraints ();

use File::Spec ();

use namespace::autoclean;


has 'path' => ( is => 'ro', isa => 'Str', required => true );


sub as_relative_path
{
	my ( $self, $path ) = @_;

	my $orig = $self -> path();

	( my $relative = $path ) =~ s/^\Q$orig\E//;

	return $relative;
}

sub as_absolute_path
{
	my ( $self, $path ) = @_;

	return File::Spec -> catfile( $self -> path(), $path );
}

sub check_scan_dir_args
{
	my ( $self, $callbacks ) = @_;

	my (
		$file_callback,
		$dir_callback,
		$special_callbacks

	) = @$callbacks{
		'file',
		'dir',
		'special'
	};

	my $basic_callback_tc = &Moose::Util::TypeConstraints::find_or_parse_type_constraint( 'Maybe[CodeRef]' );
	my $special_callbacks_tc = &Moose::Util::TypeConstraints::find_or_parse_type_constraint( 'Maybe[ArrayRef[ArrayRef[CodeRef]]]' );

	die unless defined $basic_callback_tc;
	die unless defined $special_callbacks_tc;

	$basic_callback_tc -> assert_valid( $file_callback );
	$basic_callback_tc -> assert_valid( $dir_callback );

	$special_callbacks_tc -> assert_valid( $special_callbacks );

	return;
}

sub process_filelist
{
	my ( $self, $list, %callbacks ) = @_;

	my $list_tc = &Moose::Util::TypeConstraints::find_type_constraint( 'ArrayRef[Str]' );

	die unless defined $list_tc;

	$list_tc -> assert_valid( $list );

	my $path = $self -> path();

	my $callbacks_ref = \%callbacks;
	my $stahp = true;

	foreach my $node ( @$list )
	{
		my @sublist = File::Spec -> splitdir( $node );

		pop @sublist;

		if( scalar( @sublist ) > 0 )
		{
			my $subpath = '/';

			while( defined( my $subnode = shift @sublist ) )
			{
				$subpath = File::Spec -> catfile( $subpath, $subnode );

				$self -> process_node( $callbacks_ref, $path, $subpath, $stahp );
			}
		}

		$self -> process_node( $callbacks_ref, $path, $node );
	}

	return;
}

sub scan_dir
{
	my ( $self, %callbacks ) = @_;

	my $callbacks_ref = \%callbacks;

	$self -> check_scan_dir_args( $callbacks_ref );

	$self -> __scan_dir( $callbacks_ref, $self -> path() );

	return;
}

sub __scan_dir
{
	my ( $self, $callbacks, $path ) = @_;

	opendir( my $dh, $path ) or die $!;

	while( defined( my $node = readdir( $dh ) ) )
	{
		$self -> process_node( $callbacks, $path, $node );
	}

	closedir( $dh );

	return;
}

sub process_node
{
	my ( $self, $callbacks, $path, $node, $stahp ) = @_;

	$path = File::Spec -> canonpath( $path );
	$node = File::Spec -> canonpath( $node );

	my (
		$file_callback,
		$dir_callback,
		$special_callbacks

	) = @$callbacks{
		'file',
		'dir',
		'special'
	};

	return if $node =~ m/^\./;

	chomp $node;

	my $inner = File::Spec -> catfile( $path, $node );

	if( defined $special_callbacks )
	{
		foreach my $special_callback ( @$special_callbacks )
		{
			if( $special_callback -> [ 0 ] -> ( $inner ) )
			{
				$special_callback -> [ 1 ] -> ( \$inner );

				last;
			}
		}
	}

	if( -l $inner )
	{
		my $counter = 100;

		do
		{
			$inner = readlink( $inner );

			--$counter;

		} while( ( -l $inner ) and ( $counter > 0 ) );

		next unless $counter > 0;
	}

	if( -f $inner )
	{
		if( defined $file_callback )
		{
			$file_callback -> ( $inner );
		}

	} elsif( -d $inner )
	{
		if( defined $dir_callback )
		{
			$dir_callback -> ( $inner );
		}

		$self -> __scan_dir( $callbacks, $inner ) unless $stahp;
	}

	return;
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

