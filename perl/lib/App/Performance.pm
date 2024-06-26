package App::Performance;
#
# File          ~/ws/perl/lib/App/Performance.pm
# Created       05/08/2019
# Author        Lutz Filor
# 
# Synopsys      App::Performance::elapsedtime()
#
#               Evaluate    INFORMATION     (counted)           ??? - Do we need more classifications
#               Evaluate    WARNINGS        (counted)
#               Evaluate    ERRORS          (counted)
#               Evaluate    FATALS          (counted)           ??? - Do we need more differentiation
#
#               Evaluate    TIMING                                  -   Wall clock time of application program
# 
#   NOTE        This is experimental code, not stable, not final
#               
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;                                                                       # Required for CONSTANTS
use Switch;                                                                         # Installed 11/28/2018
use Time::HiRes     qw  (   gettimeofday    );                                      # available 05-15-2019
#use Term::ANSIColor qw  (   :constants      );                                      # available
##   print BLINK BOLD RED $msg, RESET;


use lib				"$ENV{PERLPATH}";                                               # Add Include path to @INC

#use PPCOV::DataStructure::DS    qw  /   list_ref    /;                             # Data structure
use DS              qw  /   list_ref    /;                                          # Data structure
use Dbg             qw  (   debug subroutine    );

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v2.01.02");

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

use App::Const  qw( :ALL );

#----------------------------------------------------------------------------
#   S U B R O U T I N S

#
#       This routine is outdated - and need to be reevaluated
#
sub     run_time     {
        my  (   $self
            ,   $endtime    )   =   @_;                                             # localtime()
        ${$self}{end0}      =`date +%s%N`;                                          # [ns] resolution suggested
        ${$self}{end1}      =   (localtime());                                      # $finished
        printf  "%5s%s\n"  ,'','='x35;
        printf  "%5s%s%s"  ,'','Stop  time : ',${$self}{stop};
        printf  "%5s%s%s\n",'','Start time : ',${$self}{start};
        printf  "%5s%s\n"  ,'','='x35;
        my $rt  =  ${$self}{stop} -  ${$self}{start};
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
        printf  "%*s%s()\n\n", $i,$p,$n;
}#sub   sample_timingresolution

sub     set_postamble   {
        my  (   $self                                                               # { } anonymous 
            ,   $term   )   =   @_;                                                 # [ ] anonymous tag list
        ${$self}{terminationinfo}   =   $term;
}#sub   set_postamble


sub     terminate   {
        my  (   $self   )   =   @_;                                                 # { } anonymous 
        my  $n  = subroutine('name');
        printf  "%5s%s()\n",'',$n if debug($n);                                     #   
        my  $t  = elapsedtime(localtime);                                           # { } anonymous
        ${$self}{stop}  = `date +%T.%N`;
        chomp   ${$self}{stop};                                                     #   Must remove newline
        ${$self}{runt}  =   calc_run_time( $self );
        my  $code = evaluate_success($self);                                         # Termination failure code
        my  $msg    =   join ' ', @{${$self}{start1}};  
        for my $sel ( @{${$self}{termination}} ) {
            switch ($sel) {
                    case    m/\bhead\b/       { whitespace  ( ${$self}{vwsh}    );  }
                    case    m/\bstarttime\b/  { starttime   ( ${$self}{start}   );  } 
                    case    m/\bstoptime\b/   { stoptime    ( ${$self}{stop}    );  } 
                    case    m/\bmessage\b/    { message     ( $self             );  }
                    case    m/\bline\b/       { line();                             } 
                    case    m/\bruntime\b/    { runtime     ( ${$self}{runt}    );  }
                    case    m/\btail\b/       { whitespace  ( ${$self}{vwst}    );  }
                    else    { }; #do nothing
            }#switch
        }#for each selection
        exit $code;                                                             # 0 - success, 1 - error
}#sub   terminate

#----------------------------------------------------------------------------
# P R I V A T E - S U B R O U T I N S

sub     evaluate_success {
        my  (   $self   )   =   @_;                                             # { } anonymous application parameter hash
        my  $w  =   ${$self}{warn};
        my  $e  =   ${$self}{error};
        my  $m1 =   'Terminat error free, ';
        my  $m2 =   sprintf "Terminate w/ %s errors, ",$e;
        my  $m3 =   'and w/out warnings';
        my  $m4 =   sprintf "%s%s%s",'and w/ ',$w,' warnings';
        my  $m  =   ($e) ? $m2 : $m1;
            $m .=   ($w) ? $m4 : $m3;
            ${$self}{message} = $m;
            ${$self}{status}  = ($e)?$FAIL:$PASS;
        ### printf "\n";
        ### #printf "%5s%s%s\n",'','FAIL encoding ',$FAIL;
        ### #printf "%5s%s%s\n",'','PASS encoding ',$PASS;
        ### #printf "%5s%s%s\n",'','Error count : ',$e;
        ### #printf "%5s%s%s\n",'','Exit status : ',${$self}{status};
        ### printf "%5s%s\n\n",'',${$self}{message};
        return ${$self}{status};
}#sub   evaluate_success

sub     calc_run_time    {                                                      #   STOP time > START time !! causality
        my  (   $self   )   =   @_;
        my  ($h2,$m2,$s2) = split(/:/, $$self{stop});
        my  ($h1,$m1,$s1) = split(/:/, $$self{start});

        my  $mb = ( $s2 >=  $s1     )   ?   0   :   1;                          #   Borrowed minute
        my  $hb = ( $m2 >= ($m1+$mb))   ?   0   :   1;                          #   Borrowed hour
        my  $db = ( $h2 >= ($h1+$mb))   ?   0   :   1;                          #   Borrowed day

        my  $s  =  ( $s2 >= ($s1+$mb) ) ?   $s2-($s1+$mb): 60+($s2-($s1+$mb));
        my  $m  =  ( $m2 >= ($m1+$hb) ) ?   $m2-($m1+$hb): 60+($m2-($m1+$hb));
        my  $h  =  ( $h2 >= ($h1+$db) ) ?   $h2-($h1+$db): 24+($h2-($h1+$db));  #   Not all programs start at Zulu hour and finish on the same day
                                                                                #   This program doesn't count long term in days up and running
        my  $rt =   sprintf "%02s:%02s:%012.9f", $h,$m,$s;
        return  $rt;
}#sub   calc_run_time

sub     stoptime    {
        my  (   $t  )   =   @_;
        printf  "%5s%s%s\n",'','Stop  time : ',$t;                              #
        return;
}#sub   stoptime

sub     starttime {
        my  (   $t  )   =   @_;                                                 # [ ] anonymous date time array
        printf  "%5s%s%s\n",'','Start time : ',$t;                              #
        return;
}#sub   starttime

sub     runtime {
        my  (   $t  )   =   @_;                                                 # { } anonymous 
        printf  "%5s%s%s\n",'','Run   time : ',$t;                              #
        return;
}#sub   runtime

sub     line    {                                                               # Line of character 
        printf  "%5s%s\n",'','-'x40;
}#sub   line

sub     message {
        my  (   $self    )   =   @_;
        my  $msg    =   ${$self}{message};
        printf  "%5s%s\n",'',$msg;
}#sub   message

sub     whitespace  {
        my  (   $lines  )   =   @_;
        for my $n (1..$lines) {
            printf "\n";                                                        #   Insert vertical whitespace
        }#  
        return;
}#sub   whitespace

#----------------------------------------------------------------------------
#       End of module Application::Performance
1;

