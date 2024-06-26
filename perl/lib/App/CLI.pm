package Application::CLI;
#
# File          ~/ws/perl/lib/Application/CLI.pm
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

use Readonly;                                       # Required for CONSTANTS
use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;

use lib				"$ENV{PERLPATH}";               # Add Include path to @INC
use Dbg     qw  /   debug subroutine    /;
use DS      qw  /   list_ref            /;          # Data structure
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

Readonly my  $FAIL  =>  1;                                                      # default setting, Success must be determinated
Readonly my  $PASS  =>  0;                                                      # PASS value ZERO as in ZERO failure count
Readonly my  $INIT  =>  0;                                                      # Initialize to ZERO

#----------------------------------------------------------------------------
# S U B R O U T I N E S

sub     new {                                                                   # constructor
        my $class       =   shift;                                              # Object Name
        my %options     =   @_;                                                 # Allow Parameter Hash input 
        my $self    =   {                                                       # Anonymous Hash Application parameter
            start0  =>  `date +%s%N`,                                           # Current Time  - integer number [ns]
            start1  =>  (localtime()),                                          # Current Time  - ananymous array
            status  =>  $FAIL,                                                  # Default exit  - status set to $FAIL
            error   =>  $INIT,                                                  # Error   count - innitialization
            warn    =>  $INIT,                                                  # Warning count - innitialization
            %options,
            elapse  =>  `date +%s%N`,
        };
        bless   $self, $class;
        printf  "%5s%s%s\n",'','Create Object ', $class;
        return  $self;                                                          # Application parameter hash
}#sub   new

#----------------------------------------------------------------------------
# P R I V A T E - S U B R O U T I N E S

#----------------------------------------------------------------------------
# End of module
1;
