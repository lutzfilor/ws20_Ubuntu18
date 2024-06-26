package Application::Performance;
#
# File          ~/ws/perl/lib/Application/Performance.pm
# Created       05/08/2019
# Author        Lutz Filor
# 
# Synopsys      Application::Performance::elapsedtime()
#               Wall clock time of application program
# 
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;                                                                       # Required for CONSTANTS
use Switch;                                                                         # Installed 11/28/2018
use Time::HiRes     qw  (   gettimeofday    );                                      # available 05-15-2019
use Term::ANSIColor qw  (   :constants      );                                      # available
#   print BLINK BOLD RED $msg, RESET;

#use PPCOV::DataStructure::DS    qw  /   list_ref    /;                             # Data structure
use DS              qw  /   list_ref    /;                                          # Data structure
use lib				"$ENV{PERLPATH}";                                               # Add Include path to @INC
use Dbg             qw  (   debug subroutine    );

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.04");

use Exporter qw (import);
use parent 'Exporter';                                                              # replaces base; base is deprecated


our @EXPORT    =    qw(
                      );                                                            # wall clock run time

our @EXPORT_OK =    qw(     elapsedtime
                            set_postamble
                            run_time
                            terminate
                            sample_timingresolution
                      );                                                            # wall clock run time

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#   C O N S T A N T S

use Application::Constants  qw( :ALL );

#----------------------------------------------------------------------------
#   S U B R O U T I N S

sub     run_time     {
        my  (   $self
            ,   $endtime    )   =   @_;                                             # localtime()
        ${$self}{end0}      =`date +%s%N`;                                          # [ns] resolution suggested
        ${$self}{end1}      =   (localtime());                                      # $finished
        printf  "%5s%s\n"  ,'','='x35;
        printf  "%5s%s%s" ,'','End   time : ',${$self}{end0};
        printf  "%5s%s%s\n",'','Start time : ',${$self}{start};
        printf  "%5s%s\n"  ,'','='x35;
        my $rt  =  ${$self}{end0} -  ${$self}{start};
        printf  "%5s%s%19s\n",'','Run   time : ',$rt;
}#sub   run_time


sub     elapsedtime {
        my  (   $end    )   =   @_;
        my  $t              =   {};                                                 # { } hash reference
        ${$t}{end0}         =   `date +%s%N`;                                       # [ns] resolution suggested
        ${$t}{end4}         =   gettimeofday;                                       # Time::HiREs::gettimeofday()
        ${$t}{end1}         =   (localtime());                                      # $finished
        ${$t}{end2}         =   $end;                                               # current time [sec]
        ${$t}{end5}         =   gettimeofday;                                       # Time::HiREs::gettimeofday()
        ${$t}{end3}         =   `date +%s%N`;                                       # measure time resolution

        my  $s              =     $^T % 60;
        my  $m              =   (($^T - $s)/60) % 60;
        my  $h              =  ((($^T - $s)/60 -$m)/60) % 24 - 7;
        ${$t}{start}        =     $^T;
        #sleep   2;
        ${$t}{end}          =     localtime;                                        # [ s] only res
        ${$t}{start_s}      =     $^T % 60;
        ${$t}{start_m}      =   (($^T - $s)/60) % 60;
        ${$t}{start_h}      =  ((($^T - $s)/60 -$m)/60) % 24 - 9;
        ${$t}{t_stamp}      =  sprintf "%02d:%02d:%02d", $h,$m,$s;
        ${$t}{resolution}   =   ${$t}{end3} - ${$t}{end0};                          # [ns] resolution measured
        ${$t}{resolution1}  =   ${$t}{end5} - ${$t}{end4};                          # Time::HiREs::gettimeofday()
        return $t;
}#sub   elapsedtime


sub     sample_timingresolution {
        my  (   $self   )   =   @_;
        printf  "\n%5s>>> %s()\n",'','sample_timeing_resolution';
        my $i = ${$self}{format}{indent};
        my $p = ${$self}{format}{indent_pattern};                                   # indentation pattern
        my $n = subroutine('name');                                                 # name of subroutine
        list_ref ( $self );
        printf "%*s%s()\n\n", $i,$p,$n;
}#sub   sample_timingresolution

sub     set_postamble   {
        my  (   $self                                                               # { } anonymous 
            ,   $term   )   =   @_;                                                 # [ ] anonymous tag list
        ${$self}{terminationinfo}   =   $term;
}#sub   set_postamble

sub     terminate   {
        my  (   $self   )   =   @_;                                                 # { } anonymous 
        my $t = elapsedtime(localtime);                                             # { } anonymous
        printf "%5s%s%s\n",'','Type of Reference : ',ref $self;
        printf "%5s%s%s\n",'','Application       : ',${$self}{application};
        my $c = 1;
        #foreach my $key ( keys %{$self} ) {
        #    #if ()
        #    printf "%5s%2s%17s : %s\n",'',$c,$key, ${$self}{$key};
        #    $c++;
        #}#foreach
        my $code = evaluate_success($self);                                         # Termination failure code
        #for my $sel ( @{${$self}{terminationinfo}} ) {
        printf "%5s%s : %s\n",'','number of entries', $#{${$self}{start1}};
        my  $msg    =   join ' ', @{${$self}{start1}};  
        for my $sel ( @{${$self}{termination}} ) {
            printf  "%5s%s%s\n",'','>>>>>      : ',$sel;                            #
        }#for each selection
        ### for my $sel ( @{${$self}{termination}} ) {
        ###     switch ($sel) {
        ###         #case    m/\bstarttime\b/  { starttime   ( join ' ', @{$self}{start1} ); } 
        ###         case    m/\bstarttime\b/  { starttime   ( $msg      ); } 
        ###         case    m/\bstarttime1\b/ { starttime1  ( ${$self}  ); }
        ###         case    m/\bendtime\b/    { endtime     ( ${$self}  ); }
        ###         case    m/\bruntime\b/    { runtime     ( ${$self}  ); }
        ###         case    m/\bmessage\b/    { message     ( ${$self}  ); }
        ###         case    m/\bline\b/       { line();           } 
        ###         else    { }; #do nothing
        ###     }#switch
        ### }#for each selection
        exit $code;                                                             # 0 - success, 1 - error
}#sub   terminate

#----------------------------------------------------------------------------
# P R I V A T E - S U B R O U T I N S

sub     evaluate_success {
        my  (   $self   )   =   @_;                                             # { } anonymous application parameter hash
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
        printf "\n";
        #printf "%5s%s%s\n",'','FAIL encoding ',$FAIL;
        #printf "%5s%s%s\n",'','PASS encoding ',$PASS;
        #printf "%5s%s%s\n",'','Error count : ',$e;
        #printf "%5s%s%s\n",'','Exit status : ',${$self}{status};
        printf "%5s%s\n\n",'',${$self}{message};
        return ${$self}{status};
}#sub   evaluate_success

sub     starttime {
        my  (   $t  )   =   @_;                                                 # [ ] anonymous date time array
        #printf  "%5s%s%s\n",'','Start time : ',join ' ',@{$t}{start1};         #
        #printf  "%5s%s%s\n",'','Start time : ',join ' ',@$t;                   #
        printf  "%5s%s%s\n",'','Start time : ',$t;                              #
}#sub   starttime

sub     starttime1  {
        my  (   $self   )   =   @_;
        printf "%5s%s : \n\n",'','',${$self}{message};
}#sub   starttime1

sub     endtime {
        my  (   $t  )   =   @_;                                                 # { } anonymous date time array{end1}         =   (localtime());                                  # $finished
        #printf  "%5s%s%s\n",'','End   time : ',join ' ',@{$t}{end1};           #
        printf  "%5s%s%s\n",'','End   time : ',join ' ',@$t;                    #
}#sub   endtime

sub     runtime {
        my  (   $t  )   =   @_;                                                 # { } anonymous 
}#sub   runtime

sub     line    {                                                               # Line of character 
        printf  "%5s%s\n",'','-'x37;
}#sub   line

sub     message {
        my  (   $msg    )   =   @_;
        printf  "%5%s\n",'',$msg;
}#sub   message

#----------------------------------------------------------------------------
# End of module Application::Performance
1;

