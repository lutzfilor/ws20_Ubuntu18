use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PPCOV::HTML',
    VERSION_FROM      => 'lib/PPCOV/HTML.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PPCOV/HTML.pm', # retrieve abstract from module
       AUTHOR         => 'Lutz Filor (SJC) TASK0051462 <lfilor@(none)>') : ()),
);
