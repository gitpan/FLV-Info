use Module::Build;
Module::Build->new(
   module_name => 'FLV::Info',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   license => 'perl',
   requires => {
      'AMF::Perl' => 0.15,
      'List::Util' => 0,
   },
   build_requires => {
      'Test::More' => 0,
   },
   script_files => ['bin/flvinfo'],
   add_to_cleanup => [ 'FLV-Info-*' ],
)->create_build_script;
