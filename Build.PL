use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'List::SkipList',
     license => 'perl',
     requires => {
       'base'                       => 0,
       'enum'                       => 1.016,
       'perl'                       => '5.6.1',
     },
     recommends => {
       'Carp::Assert'               => 0.17,
     },
     build_requires => {
       'Test::More'                 => 0,
       'Test::Warn'                 => 0,
     },
     autosplit => 'lib/Algorithm/SkipList.pm',
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
