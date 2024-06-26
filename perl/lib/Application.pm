package Application;
#
# File          ~/ws/perl/lib/App.pm
#               ~/ws/perl/lib/Application.pm
# Created       05/15/2019
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

use lib	"$ENV{PERLPATH}";                                                       # Add Include path to @INC
use Application::Performance    qw  (   sample_timingresolution
                                        set_postamble
                                        run_time
                                        elapsedtime 
                                        terminate   );                          # Measure run time/wall clock
use DS    qw  /   list_ref    /;                          # Data structure
use Dbg   qw  /   debug subroutine    /;

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.02.02");

use Exporter qw (import);
use parent 'Exporter';                                                          # replaces base; base is deprecated


our @EXPORT    =    qw(
                      );                                                        # new CLI {} anonymous hash
                      
our @EXPORT_OK =    qw(     new
                            update
                            inspect
                            run_time
                            terminate
                      );                                                        # new CLI {} anonymous hash

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#Readonly my  $FAIL  =>   1;                                                     # default setting, Success must be determinated
#Readonly my  $PASS  =>   0;                                                     # PASS value ZERO as in ZERO failure count
#Readonly my  $INIT  =>   0;                                                     # Initialize to ZERO

use Application::Constants  qw( :ALL );                                         #   Prove of concept, of external defined Constants
#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     new {                                                                   # constructor
        my $class       =   shift;                                              # Object Name
        my %options     =   @_;                                                 # Allow Parameter Hash input
        my $self    =   {
            nano1   =>  `date +%N`,                                             #   Nanoseconds - 0.### ### ### [s]
            time1   =>  `date +%T`,                                             #   HH:MM:SS    - Time stamp
            date1   =>  `date +%F`,                                             #   YYYY-MM-DD  - Date stamp
            start   =>  `date +%s%N`,                                           #   Current Time
            date    =>  `date`,                                                 #   Current Date
            start1  =>  [localtime()],                                          # Current Time
            status  =>  $FAIL,                                                  # Default exit  - status set to $FAIL
            error   =>  $INIT,                                                  # Error   count - innitialization
            warn    =>  $INIT,                                                  # Warning count - innitialization
            #status =>  1,                                                      # Default exit  - status set to $FAIL
            #error  =>  0,                                                      # Error   count - innitialization
            #warn   =>  0,                                                      # Warning count - innitialization
            #
            %options,                                                           # Provide more parameter
            #
            elapse  =>  `date +%s%N`,
        };
        chomp   ${$self}{start};
        chomp   ${$self}{elapse};
        printf  "%5s%s%s\n",'','Create Object      : ', $class;
        #printf  "%5s%s%s\n",'','Default FAIL  : ', ${$self}{status};
        printf  "%5s%s%s\n",'','Number of Warnings : ', ${$self}{warn};
        printf  "%5s%s%s\n",'','Number of Errors   : ', ${$self}{error};
        printf  "%5s%s%s\n",'','Status             : ', ${$self}{status};
        printf  "%5s%s%s\n",'','Date               : ', ${$self}{date};
        printf  "%5s%s%s\n",'','Start  Time        : ', ${$self}{start};
        printf  "%5s%s%s\n",'','Elapse Time        : ', ${$self}{elapse};
        my  $delta  =    ${$self}{elapse}   -   ${$self}{start};
        printf  "%5s%s%19s\n",'','Run    Time        : ', $delta/1000/1000/1000;

        printf  "%5s%s%s\n",'','Create Timeing     : ', join ' ',@{${$self}{start1}};
        return  bless   $self, $class;
}#sub   new


sub     load    {
}#sub   load

sub     update  {
        my  (   $self
            ,   $options )  =   @_;                                         #   {Secondary sourceHashRef}, Prevalent over new()
        my  $w  =   maxwidth ( [ keys %{$options} ] );
        foreach my $k   (  keys %{$options} )  {
            #printf  "%*s%*s = %s\n",$i,$p,$w,$k,${$self}{$k};              <<< false statment
            #printf  "%*s%*s = %s\n",5,'',$w,$k,${$options}{$k};
            ${$self}{$k} =  ${$options}{$k};                                #   
        }#for all new value pairs
        #my  %options    =   @_;
        #return  { %{$self, %options };
        #$self   =  { %{$self}, %{$options} }; 
}#Sub   update

sub     inspect {
        my  ( $self, $format )  =   @_;
        my  $i  =   ${$format}{indent};
        my  $p  =   ${$format}{pattern};
        my  $s  =   ${$format}{spacer};
            $i  //= 5;
            $p  //= '';
            $s  //= 0;
        my  $w  =   maxwidth ( [ keys %{$self} ] );
        if  ( ${$format}{header} )   {
            printf "%*s%s\n",$i,$p,${$format}{header};
        }# Header

        list_ref ( $self, $format );                                        #   DataStructure DS.pm

        foreach ( 1..$s )   {
            printf  "\n";
        }#vertical terminal format
}#sub   inspect
#----------------------------------------------------------------------------
#       P R I V A T E  M E T H O D S

sub     maxwidth    {
        my  (   $array_r    )   =   @_;
        my  $max    =   0;
        foreach my $entry  ( @{$array_r} ) {
            my $tmp =   length($entry);
            $max = ( $max > $tmp ) ? $max : $tmp;
        }#for all
        return $max;
}#sub   maxwidth

#----------------------------------------------------------------------------
# End of module Application
1;
