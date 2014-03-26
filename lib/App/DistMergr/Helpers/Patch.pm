use strict;
use warnings;

package App::DistMergr::Helpers::Patch;

use boolean;

use Moose;

extends 'App::DistMergr::Helpers::Base::Dir';

use String::ShellQuote '&shell_quote';

use Cwd 'getcwd';

use File::Spec ();

use namespace::autoclean;


has 'cmd' => ( is => 'rw', isa => 'Str', lazy => true, default => 'exit 1; # %s %s' );


sub exec_cmd
{
	my ( $self, $patch_file, $target_file ) = @_;

	my $cwd = getcwd();

	unless( File::Spec -> file_name_is_absolute( $target_file ) )
	{
		$target_file = File::Spec -> rel2abs( $target_file, $cwd );
	}

	unless( File::Spec -> file_name_is_absolute( $patch_file ) )
	{
		$patch_file = File::Spec -> rel2abs( $patch_file, $cwd );
	}

	my @parts = File::Spec -> splitdir( $target_file );

	pop @parts;

	my $dest_dir = File::Spec -> catfile( @parts );

	chdir $dest_dir;

	my $cmd = sprintf( $self -> cmd(), ( map{ &shell_quote( $_ ) } ( $patch_file, $target_file ) ) );
	my $code = system( $cmd );

	chdir $cwd;

	$code >>= 8;

	die sprintf( 'patch exited with code %d', $code ) if $code;

	return;
}

sub apply_to
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

	my @parts = File::Spec -> splitdir( $self -> as_relative_path( $source ) );

	pop @parts;

	$dest = File::Spec -> catfile( $dest, @parts );

	$self -> exec_cmd( ( map{ File::Spec -> canonpath( $_ ) } ( $source, $dest ) ) );

	return;
}

sub calc_padding
{
	my ( $self, $dir ) = @_;

	my $i = 0;

	foreach my $node ( File::Spec -> splitdir( $dir ) )
	{
		next unless $node;
		next if $node eq '.';

		if( $node eq '..' )
		{
			--$i;

		} else
		{
			++$i
		}
	}

	return $i;
}


__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

