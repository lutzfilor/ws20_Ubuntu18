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
use Switch;                                                                     # Installed 11/28/2018
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
                            terminate
                      );                                                        # wall clock run time

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
# C O N S T A N T S

Readonly my  $FAIL  =   1;                                                      # default setting, Success must be determinated
Readonly my  $PASS  =   0;                                                      # PASS value ZERO as in ZERO failure count

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


sub     terminate   {
        my  (   $self   )   =   @_;                                              # { } anonymous 
        my $t = elapsedtime(localtime);                                          # { } anonymous
        printf "%5s%s%s\n",'','Type of Reference : ',ref $self;
        printf "%5s%s%s\n",'','Application       : ',${$self}{application};
        my $c = 1;
        foreach my $key ( keys %{$self} ) {
            printf "%5s%2s%17s : %s\n",'',$c,$key, ${$self}{$key};
            $c++;
        }#foreach
        my $code = evaluate_success($self);                                      # Termination failure code
        for my $sel ( @{${$self}{info}} ) {
            switch ($sel) {
                case    m/\bstarttime\b/  { } 
                case    m/\bendtime\b/    { }
                case    m/\bruntime\b/    { } 
                else    { }; #do nothing
            }#switch
        }#for each selection
        exit $code;                                                             # 0 - success, 1 - error
}#sub   terminate

#----------------------------------------------------------------------------
# P R I V A T E - S U B R O U T I N S

sub     evaluate_success {
        my  (   $self   )   =   @_;
        my  $w  =   ${$self}{warn};
        my  $e  =   ${$self}{error};
        my  $m1 =   'Error free ';
        my  $m2 =   sprintf "%s%s",$e,' errors  ';
        my  $m3 =   'without warnings';
        my  $m4 =   sprintf "%s%s%s",'with ',$w,' warnings';
        my  $m  =   ($e) ? $m2 : $m1;
            $m .=   ($w) ? $m4 : $m3;
            ${$self}{message} = $m;
            ${$self}{status}  = ($e)?$FAIL:$PASS;
        return ${$self}{status};
}#sub   evaluate_success

sub     starttime {
}#sub   starttime

sub     endtime {
}#sub   endtime

sub     runtime {
}#sub   runtime

sub     message {
}#sub   message

#----------------------------------------------------------------------------
# End of module
1;


## printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{t_stamp};
## printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{start};
## printf  "%5s%s%s\n"   ,'','End   time : ',${$perf}{end};                        #
## printf  "%5s%s%s"     ,'','End0  time : ',${$perf}{end0};                          
## printf  "%5s%s%s\n"   ,'','End1  time : ',join ' ',@{$perf}{end1};              #
## printf  "%5s%s%s\n"   ,'','End2  time : ',${$perf}{end2};                       #
## #printf  "%5s%s%s\n"   ,'','End4  time : ',${$perf}{end4};                      # Time::HiRes::gettimeofday Works !!
## printf  "%5s%s%9d%s\n",'','Rsltn Time : ',${$perf}{resolution},' ns';           #
## printf  "%5s%s%s%s\n" ,'','Rsltn Time : ',${$perf}{resolution}/10e6,' ms';
## printf  "%5s%s%9d%s\n",'','Rsltn1Time : ',${$perf}{resolution1},'  s';          #
## printf  "%5s%s%s\n"   ,'',$0,' done ...';
