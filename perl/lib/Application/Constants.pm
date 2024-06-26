package Application::Constants;
#
# File          ~/ws/perl/lib/Application/Constants.pm
# Created       05/24/2019
# Author        Lutz Filor
# 
# Synopsys      Application::Constants::$Shared_constances
#               
# 
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;                                                                   # Required for CONSTANTS

use lib				"$ENV{PERLPATH}";                                           # Add Include path to @INC

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.05");

use Exporter qw (import);                                                       # ??? Not sure if this is needed
use parent 'Exporter';                                                          # replaces base; base is deprecated


our @EXPORT    =    qw(
                      );                                                        # Implicit export
our @EXPORT_OK =    qw(     $FAIL $PASS $INIT
                      );                                                        # Explicit export

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );                                                           # Group export

#----------------------------------------------------------------------------
# C O N S T A N T S

Readonly our $FAIL  =>  1;                                                      # Default setting, Success must be determinated
Readonly our $PASS  =>  0;                                                      # PASS value ZERO as in ZERO failure count
Readonly our $INIT  =>  0;                                                      # Initialize to ZERO

#----------------------------------------------------------------------------
# End of module Application::Constants
1;
