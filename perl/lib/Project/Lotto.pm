package Project::Lotto;
# File          ~/ws/perl/lib/Project/Lotto.pm
#
# Author        Lutz Filor
# 
# Synopsys      Project configuration separated from script file.
#
#----------------------------------------------------------------------------
#       I M P O R T S 

use strict;
use warnings;
use Switch;                                             # Multi choice selection

use lib "$ENV{PERLPATH}";                               # Add Include path to @INC

#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.02.01");

use Exporter qw (import);
use parent 'Exporter';                                  # replaces base; base is deprecated


our @EXPORT    =    qw(
                      ); # Project/Lotto                # Deprecate implicite exports

our @EXPORT_OK =    qw(     get_setup
                      ); # Project/Lotto                # PREFERED explicite exports

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S
my $format  =   {   indent          =>  5,
                    indent_pattern  =>  '',
                    reform          =>  'ON',                                       # remove trailing \n of hash/array values
                };

my %config  =   (   application     =>  'mining',                                   # 'Rapid Prototyping',
                    synopsis        =>  'Reduce Redundancy',                        # attack surface, CFT (Code for Testing), TTM
                    projecthome     =>  '~/ws/perl/projects',                       # UserHome/ws/perl/projects
                    project         =>  'Lotto',                                    # ProjectName
                    configuration   =>  'config',                                   # ProjectConfiguration
                    logging         =>  'logs',                                     # ProjectLogging
                    termination     =>  [ qw (message) ],                           # Termination Information
                    format          =>  $format,
                );                         
#----------------------------------------------------------------------------
#       V A R I A B L E S

my $rubicon =   {}; #different project
my $lotto   =   {   project         =>  'Lotto'
                ,   user            =>  $ENV{USER}                                          #   'lutz'
                ,   path            =>  $ENV{PERLPATH}.'/Project'                           #   /home/lutz/ws/perl/lib/Project/Lotto.pm
                ,   proj_path       =>  $ENV{PERLPROJ}.'/Lotto'                             #   /home/lutz/ws/perl/projects
                ,   data_sdir       =>  $ENV{PERLDATA}                                      #   /home/lutz/ws/perl/data
                ,   data_file       =>  $ENV{PERLDATA}.'drawings.dat'                       #   /home/lutz/ws/perl/data/drawings.dat->
                ,   parameter       =>  {   data_sdir   =>  {   name        =>  'data_sdir'
                                                            ,   attributes  =>  'exists|readable'
                                                            }#data subdirectory
                                        ,   data_file   =>  {   name        =>  'data_file'
                                                            ,   attributes  =>  'exists|link|readable'
                                                            }#data source file
                                        }   #defined envirnoment parameter
                ,   files           =>  [   qw  (   data_file   )
                                        ]   #[Files] to be tested
                ,   pathes          =>  [   qw  (   data_sdir   )
                                        ]   #[AccessPathes] to be tested
                };  #statistics

#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     get_setup   {
        my  (   $select )  =    @_;                             #   select $project
        my  $f  =   {   fullcolor   =>  1                       #   configure message, whole message colored
                    ,   newline     =>  2   };                  #   vertical format 2 newlines
        my  $project;                                           #   {HashRef}
        my  $msg    =   'Project not defined';
        printf  "%*s%s : %s\n",5,'','Select project  ', $select;
        switch ( $select ) {
            case    m/\bRubicon\b/  { $project  =   $rubicon;   }
            case    m/\bLotto\b/    { $project  =   $lotto;     }  
            else    { t_warn( $msg, $f); exit;  }               #   
        }#switch
        return  $project;
}#sub   get_setup

sub     clone_setup {
}#sub   clone_setup
#----------------------------------------------------------------------------
# End of module Project/Lotto.pm
1
