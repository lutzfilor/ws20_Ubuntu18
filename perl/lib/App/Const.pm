package App::Const;
#
# File          ~/ws/perl/lib/App/Const.pm
# Created       05/24/2019
# Author        Lutz Filor
# 
# Synopsys      App::Const::$Shared_constances
#               
# 
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;                                                                   # Required for CONSTANTS

use lib	"$ENV{PERLPATH}";                                                       # Add Include path to @INC

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v2.01.04");

use Exporter qw (import);                                                       # ??? Not sure if this is needed
use parent 'Exporter';                                                          # replaces base; base is deprecated


#our @EXPORT    =   qw(     );                                                  #   Implicit export
our @EXPORT_OK  =   qw(     $FAIL $PASS $INIT $TRUE $FALSE
                      );                                                        #   Explicit export

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );                                                           # Group export

#----------------------------------------------------------------------------
#   C O N S T A N T S

Readonly our $FAIL  =>  1;                                                      #   Default setting, Success must be determinated
Readonly our $PASS  =>  0;                                                      #   PASS value ZERO as in ZERO failure count

Readonly our $TRUE  =>  1;                                                      #   Boolean, constant w/ value true
Readonly our $FALSE =>  0;                                                      #   Boolean, constant w/ value false

Readonly our $INIT  =>  0;                                                      #   Initialize to ZERO

Readonly our $DONE  =>  1;

#----------------------------------------------------------------------------
# End of module App::Const
1;
