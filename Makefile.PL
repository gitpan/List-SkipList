use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'List::SkipList',
    'VERSION_FROM'	=> 'SkipList.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      'AutoLoader'   => 0,
      'Carp'         => 0,
      'Carp::Assert' => 0.17,
      'warnings'     => 0,
    }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (
#        DISTNAME   => 'List::SkipList', 
#        ABSTRACT_FROM => 'SkipList.pm', # retrieve abstract from module
       ABSTRACT   => 'Skip list implementation in Perl',
       AUTHOR     => 'Robert Rothenberg <rrwo@cpan.org>') : ()),
);
