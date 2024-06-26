package Application::CLI::CLI;
#
# File          ~/ws/perl/lib/Application/Performance/Performance.pm
# Created       05/09/2019
# Author        Lutz Filor
# 
# Synopsys      Application::CLI::new()
#               Wall clock time of application program
# 
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;                                                                   # Required for CONSTANTS
use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;

use PPCOV::DataStructure::DS    qw  /   list_ref    /;                          # Data structure
use lib             qw  (   ~/ws/perl/lib );                                    # Relative UserModulePath
use Dbg             qw  (   debug subroutine    );

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.01");

use Exporter qw (import);
use parent 'Exporter';                                                          # replaces base; base is deprecated


our @EXPORT    =    qw(
                      );                                                        # new CLI {} anonymous hash
                      
our @EXPORT_OK =    qw(     new
                      );                                                        # new CLI {} anonymous hash

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
# C O N S T A N T S


#----------------------------------------------------------------------------
# S U B R O U T I N S

#----------------------------------------------------------------------------
# End of module
1;
