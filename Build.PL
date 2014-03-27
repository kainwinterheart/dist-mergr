use strict;
use warnings;

package Build_PL;

use Module::Build ();

Module::Build
	-> new(
		module_name => 'App::DistMergr',
		dist_abstract => 'Easily merge one distribution into another',
		dist_author => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
		recursive_test_files => 1,
		configure_requires => {
			'Module::Build' => 0.36
		},
		requires => {
                        'perl' => '>= 5.10.1',
			'boolean' => 0,
			'Cwd' => 0,
			'File::Copy' => 0,
			'File::Spec' => 0,
			'Module::Load' => 0,
			'Moose' => 0,
			'MooseX::StrictConstructor' => 0,
			'namespace::autoclean' => 0,
			'Perl6::Slurp' => 0,
			'String::ShellQuote' => 0,
			'YAML::Syck' => 0
		}
	)
	-> create_build_script()
;

exit 0;

