use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'List::SkipList',
     license => 'perl',
     requires => {
       'enum'                       => 1.016,
       'perl'                       => '5.6.1',
       'Carp::Assert'               => 0.17,
     },
     recommends => {
     },
     autosplit => 'lib/List/SkipList.pm',
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
