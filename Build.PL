use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'List::SkipList',
     license => 'perl',
     requires => {
       'perl'                       => '5.6.1',
       'Carp::Assert'               => 0,
     },
     recommends => {
     },
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
