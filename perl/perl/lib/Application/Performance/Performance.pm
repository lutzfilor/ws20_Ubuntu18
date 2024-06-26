package Application::Performance::Performance;
#
# File          ~/ws/perl/lib/Application/Performance/Performance.pm
# Created       05/08/2019
# Author        Lutz Filor
# 
# Synopsys      Application::Performance::Performance::elapsedtime()
#               Wall clock time of application program
# 
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;                                                                   # Required for CONSTANTS
use Time::HiRes     qw  (   gettimeofday    );                                  # available 05-15-2019
use Term::ANSIColor qw  (   :constants      );                                  # available
#   print BLINK BOLD RED $msg, RESET;

use PPCOV::DataStructure::DS    qw  /   list_ref    /;                          # Data structure
use lib             qw  (   ~/ws/perl/lib );                                    # Relative UserModulePath
use Dbg             qw  (   debug subroutine    );

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.02");

use Exporter qw (import);
use parent 'Exporter';                                                          # replaces base; base is deprecated


our @EXPORT    =    qw(
                      );                                                        # wall clock run time

our @EXPORT_OK =    qw(     elapsedtime
                      );                                                        # wall clock run time

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
# C O N S T A N T S


#----------------------------------------------------------------------------
# S U B R O U T I N S

sub     elapsedtime {
        my  (   $end    )   =   @_;
        my  $t              =   {};                                             # { } hash reference
        ${$t}{end0}         =   `date +%s%N`;                                   # [ns] resolution suggested
        ${$t}{end3}         =   `date +%s%N`;                                   # measure time resolution
        ${$t}{end1}         =   (localtime());                                  # $finished
        ${$t}{end4}         =   gettimeofday;                                   # Time::HiREs::gettimeofday()
        ${$t}{end5}         =   gettimeofday;                                   # Time::HiREs::gettimeofday()

        ${$t}{end2}         =   $end;                                           # current time [sec]
        my  $s              =     $^T % 60;
        my  $m              =   (($^T - $s)/60) % 60;
        my  $h              =  ((($^T - $s)/60 -$m)/60) % 24 - 7;
        ${$t}{start}        =     $^T;
        #sleep   2;
        ${$t}{end}          =     localtime;                                    # [ s] only res
        ${$t}{start_s}      =     $^T % 60;
        ${$t}{start_m}      =   (($^T - $s)/60) % 60;
        ${$t}{start_h}      =  ((($^T - $s)/60 -$m)/60) % 24 - 9;
        ${$t}{t_stamp}      =  sprintf "%02d:%02d:%02d", $h,$m,$s;
        ${$t}{resolution}   =   ${$t}{end3} - ${$t}{end0};                      # [ns] resolution measured
        ${$t}{resolution1}  =   ${$t}{end5} - ${$t}{end4};                      # Time::HiREs::gettimeofday()
        return $t;
}#sub   elapsedtime

#----------------------------------------------------------------------------
# End of module
1;
