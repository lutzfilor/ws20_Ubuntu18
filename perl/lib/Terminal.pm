package Terminal;
# File          ~/ws/perl/lib/Terminal.pm
#
# Author        Lutz Filor
# 
# Project       Rubicon,    major challenge standardize the terminal output
#
# Synopsys      Standard TERMINAL output w/ colored predefined Line headers
#
#               Terminal::t_help            (          $msg, {format} )  present GREEN   info tips 
#               Terminal::t_warn            (          $msg, {format} )  present RED     warning messages
#               Terminal::t_info            (          $msg, {format} )  present BLUE    information
#               Terminal::t_note            (          $msg, {format} )  present YELLOW  note message
#               Terminal::t_okay            (          $msg, {format} )  present GREEN   Okay feedback (All in green)
#               Terminal::t_exit            (          $msg, {format} )  present Magenta EXIT warnings
#               Terminal::t_blank           (          $msg, {format} )  present         message w/out line header bold/normal
#               Terminal::t_usage           (          $msg, {format} )  present BLUE    custom USAGE information
#               Terminal::t_custom          ( $header, $msg, {format} )  present         custom color, format, messages
#               Terminal::t_list            (       $ArrRef, {format} )  present BLUE, GREEN, RED lists, aligned w/ all other 
#               Terminal::t_function_header (          $msg           )  present         function call( ), derivative of t_blank
#               


# Term::ANSIColor       Styles      BOLD, BLINK, UNDERLINE,             RESET
#                       Color       RED, BLUE, GREEN, YELLOW, MAGENTA
#                       Subroutines print
#
#               FORMAT  before      vertical  number of lines BEFORE terminal display
#                       newline     vertical  number of lines AFTER  terminal display
#                       lineheader  horizonal indentation           - default 9
#                       fullcolor   1   whole message formated
#                                   0   only line header formated   - default
# 
#               Example :     print BLINK BOLD RED $msg, RESET;
#----------------------------------------------------------------------------
#       I M P O R T S 

use strict;
use warnings;
use Switch;                                                                     # Multi choice selection

use lib "$ENV{PERLPATH}";                                                       # Add Include path to @INC

#use Term::ANSIColor qw  (   :constants  );                                      # available
use Term::ANSIColor qw  (   BLUE RED GREEN YELLOW MAGENTA
                            BOLD BLINK 
                            RESET       );                                      # available
use DS::Array       qw  (   maxwidth    );                                      # maxwidth( [$ArrRef], $MinimumSeed )
### use Hash    qw  (   list_HashRef    );                                      # list formated content of {$HashRef}

#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v2.02.12");

use Exporter qw (import);
#use parent 'Exporter';                                 # replaces base; base is deprecated
use base    'Exporter';                                 # replaces base; base is deprecated [Fi]    2020-05-06


#our @EXPORT   =    qw  (   ); # Test Case Generation   # Deprecate implicite exports

our @EXPORT_OK =    qw  (   t_help
                            t_warn
                            t_info
                            t_note
                            t_okay
                            t_exit
                            t_blank
                            t_usage
                            t_custom
                            t_list
                            t_function_header
                        ); # Test Case Generation       # PREFERED explicite exports

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       V A R I A B L E S

#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     t_warn  {                                                               #   RED
        my  ( $info, $format )   =   @_;
        my  $b  =   ${$format}{before};                                         #   Vertical format before the message
        my  $c  =   ${$format}{fullcolor};                                      #   Color full report
        my  $v  =   ${$format}{after};                                          #   vertical format
        my  $i  =   ${$format}{lineheader};                                     #   Horizontal format for line header
            $b  //= 0;                                                          #   default no lines ahead
            $i  //= 9;
            $c  //= 0;
            $v  //= 0;
        my  $msg=   sprintf"%-*s",$i,'WARN: ';    
        for ( 1..$b) { printf  "\n"; }                                          #   vertical format
        if  ( $c == 1 ) {
            $msg    .=  $info;
            print   BOLD BLINK RED $msg, RESET;
        } else {
            print   BOLD RED $msg, RESET;
            printf  "%s",   $info;
        }
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format
        return;
}#sub   t_warn

sub     t_exit  {                                                               #   MAGENTA
        my  ( $info, $format )   =   @_;                                        #   API
        my  $b  =   ${$format}{before};                                         #   Vertical format before the message
        my  $c  =   ${$format}{fullcolor};                                      #   Color full report
        my  $v  =   ${$format}{after};                                          #   vertical format
        my  $i  =   ${$format}{lineheader};                                     #   Horizontal format for line header
            $b  //= 0;                                                          #   default no lines ahead
            $i  //= 9;                                                          #   default indent
            $c  //= 0;                                                          #   default fullcolor OFF
            $v  //= 0;                                                          #   default no lines 
        my  $msg=   sprintf"%-*s",$i,'EXIT: ';                                  #   Standard Format
        for ( 1..$b) { printf  "\n"; }                                          #   vertical format
        if  ( $c == 1 ) {
            $msg    .=  $info;
            print   BOLD BLINK MAGENTA $msg, RESET;
        } else {
            print   BOLD BLINK MAGENTA $msg, RESET;
            printf  "%s",   $info;
        }
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format
        return;                                                                 #   Should the exit statment pulled into the function?
}#sub   t_exit

sub     t_info  {                                                               #   BLUE
        my  ( $info, $format )   =   @_;                                        #   API
        my  $b  =   ${$format}{before};                                         #   Vertical format before the message
        my  $c  =   ${$format}{fullcolor};                                      #   Color full report
        my  $v  =   ${$format}{newline};                                        #   vertical format
        my  $i  =   ${$format}{lineheader};                                     #   Horizontal format for line header
            $b  //= 0;                                                          #   default no lines ahead
            $i  //= 9;                                                          #   default indent
            $c  //= 0;                                                          #   default fullcolor OFF
            $v  //= 0;
        my  $msg=   sprintf"%-*s",$i,'INFO: ';                                  #   Standard Format
        for ( 1..$b) { printf  "\n"; }                                          #   vertical format
        if  ( $c == 1 ) {
            $msg    .=  $info;
            print   BLINK BOLD BLUE $msg, RESET;
        } else {
            #print   BLINK BOLD UNDERLINE BLUE $msg, RESET;
            print   BLINK BOLD BLUE $msg, RESET;
            printf  "%s",   $info;
        }
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format
        return;
}#sub   t_info

sub     t_note  {                                                               #   YELLOW
        my  ( $info, $format )   =   @_;
        my  $i  //= 9;
        my  $msg=   sprintf"%-*s",$i,'NOTE: ';    
        #print   BLINK BOLD YELLOW $msg, RESET;
        print   BLINK YELLOW $msg, RESET;
        printf  "%s\n",   $info;
}#sub   t_note

sub     t_okay  {                                                               #   GREEN
        my  ( $info )   =   @_;
        my  $i  //= 9;
        my  $msg=   sprintf"%-*s",$i,'OKAY: ';    
        print   BLINK BOLD GREEN $msg, RESET;
        printf  "%s\n",   $info;
}#sub   t_status

sub     t_usage {
        my  (   $info, $format  )   =   @_;
        my  $b  =   ${$format}{before};                                         #   Vertical format before the message
        my  $c  =   ${$format}{fullcolor};                                      #   Color full report
        my  $v  =   ${$format}{newline};                                        #   vertical format
        my  $i  =   ${$format}{lineheader};                                     #   Horizontal format for line header
            $b  //= 0;                                                          #   default no lines ahead
            $i  //= 9;
            $c  //= 0;
            $v  //= 0;
        my  $msg=   sprintf"%-*s",$i,'Usage: '; 
        my  $txt=   sprintf"%s --%s",$0,$info;                                  #   Prepend program name
        for ( 1..$b) { printf  "\n"; }                                          #   vertical format
        if  ( $c == 1 ) {
            $msg    .=  $txt;
            print   BOLD BLUE $msg, RESET;
        } else {
            #print   BOLD UNDERLINE RED $msg, RESET;
            print   BOLD BLUE $msg, RESET;
            printf  "%s",   $txt;
        }
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format
}#sub   t_usage

sub     t_blank {                                                               #   No line header
        my  ( $info, $format )  =   @_;
        my  $b  =   ${$format}{before};                                         #   Vertical format before the message
        my  $h  =   ${$format}{header};                                         #   Line header, default blank, aka not assigned
        my  $c  =   ${$format}{fullcolor};                                      #   Color full report
        my  $v  =   ${$format}{newline};                                        #   vertical format
        my  $i  =   ${$format}{lineheader};                                     #   Horizontal format for line header
        my  $d  =   ${$format}{bold};                                           #   Control, BOLD
            $b  //= 0;                                                          #   default no lines ahead
            $h  //= '';                                                         #   default blank
            $i  //= 9;
            $c  //= 0;
            $v  //= 0;
            $d  //= 0;
        my  $choice =   $d;                                                     #   BITFIELD, to be extended
        #$info = sprintf "%2s %s",$choice, $info;
        #printf "%9s%s %s %s :: %s\n",'','$choice',$choice,$info;
        #$info = sprintf "%2s %s",$choice, $info;                               #   debugging
        my  $msg=  sprintf "%*s%s",$i,$h,$info;                                 #   Line Headers are blank/indented
        for ( 1..$b) { printf  "\n"; }                                          #   vertical format
        switch ( $choice )   {
            case    0   { print $msg;   }
            case    1   { print BOLD $msg, RESET; }
        }#switch
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format
}#sub   t_blank

sub     t_custom    {
        my  (   $header                                                         #   custom line header
            ,   $info
            ,   $format     )   =   @_;
        my  $b      =   ${$format}{before};                                     #   Vertical format before the message
        my  $v      =   ${$format}{newline};                                    #   vertical format
        my  $i      =   ${$format}{lineheader};                                 #   Horizontal format for line header
        my  $bf1    =   ${$format}{bold};                                       #   Control, BOLD
        my  $bf2    =   ${$format}{blink};                                      #   Control, BLINK
        my  $bf3    =   ${$format}{fullcolor};                                  #   Color full report
        my  $bf4    =   ${$format}{color};                                      #   Idea ???
            $b      //= 0;                                                      #   default no lines ahead
            $i      //= 9;
            $v      //= 0;
            $bf1    //= 0;
            $bf2    //= 0;
            $bf3    //= 0;
        my  $msg;                                                               #   BITFIELD, to be extended
        my  $choice =   $bf1 * 1                                                #   BF BOLD  
                    +   $bf2 * 2                                                #   BF BLINK mutual exclusive from BOLD
                    +   $bf3 * 4;                                               #   BF COLOR Header Only vs Header & Message
        if ( $bf3 == 1 ) {
            $msg = sprintf "%-*s%s",$i,$header,$info;                           #   Line Headers are blank/indented
        } else {
            $msg = sprintf "%-*s",$i,$header;
        }
        #printf "%9s%s %s %s :: %s\n",'','$choice',$choice, $msg;
        $info = sprintf "%2s %s",$choice, $info;
        for ( 1..$b) { printf  "\n"; };                                         #   vertical format
        switch ( $choice )   {
            case   (0)  { print $msg, RESET;   
                          print $info;              }
            case   (1)  { print BOLD  GREEN $msg, RESET;
                          print $info;              }
            case   (2)  { print BLINK $msg, RESET;
                          print $info;              }
            case   (4)  { print GREEN $msg, RESET;  }
            case   (5)  { print BOLD  $msg, RESET; }
            #case   (5)  { print BOLD  GREEN $msg, RESET; }
            case   (6)  { print BLINK GREEN $msg, RESET; }
        }#switch
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format
}#sub   t_custom

sub     t_help  {
        my  ( $info, $format )  =   @_;
        my  $b      =   ${$format}{before};                                     #   Vertical format before the message
        my  $c      =   ${$format}{fullcolor};                                  #   Color full report
        my  $v      =   ${$format}{newline};                                    #   vertical format
        my  $i      =   ${$format}{lineheader};                                 #   Horizontal format for line header
        my  $bf1    =   ${$format}{bold};                                       #   Control, BOLD
        my  $bf2    =   ${$format}{blink};                                      #   Control, BLINK
            $b      //= 0;                                                      #   default no lines ahead
            $i      //= 9;
            $c      //= 0;
            $v      //= 0;
            $bf1    //= 0;
            $bf2    //= 0;
        my  $choice =   $bf1                                                    #   BITFIELD, to be extended
                    +   $bf2 * 1;                                               #   BF BLINK mutual exclusive from BOLD
        my  $msg    =   sprintf"%-*s%s",$i,'',$info;                            #   Line Headers are blank/indented
        #printf "%9s%s %s :: %s\n",'','$choice',$choice, $msg;
        for ( 1..$b ) { printf  "\n"; };                                        #   vertical format
        switch ( $choice )   {
            case   (0) { print GREEN $msg, RESET;      }
            case   (1) { print BOLD  GREEN $msg, RESET;}
            case   (2) { print BLINK GREEN $msg, RESET;}
        }#switch
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format  
}#sub   t_help

sub     t_list  {
        my  (   $list                                                           #   ArrRef  []
            ,   $format )   =   @_;                                             #   HashRef {} of format attributes 
        my  $b      =   ${$format}{before};                                     #   Vertical   format before the message
        my  $i      =   ${$format}{lineheader};                                 #   Horizontal format for line header indentation
        my  $h      =   ${$format}{header};                                     #   Line header,                      indentation pattern
        my  $info   =   ${$format}{info};                                       #   Head line information aka Name of List/collection
        my  $s      =   ${$format}{spacer};                                     #   Vertical   format betweem headline and table
        my  $c      =   ${$format}{color};                                      #   RED, GREEN
        my  $v      =   ${$format}{after};                                      #   vertical format
            $c      //= 'UNDEFINED';                                            #   default value
            $h      //= ' ';                                                    #   blank line header default
            $i      //=  9;
            $b      //=  0;
            $s      //=  0;
            $v      //=  0;
        my  $w;
        if ( ref ($list) eq "ARRAY" ) {
            $w  =   maxwidth(  $list, 0 );                                      #   Allow max(List) > Seed
        } else {
            $w  =   length  $list;
        }
        my  $choice = ( $c eq 'RED'  ) ? 0                                      #  $$format{color}
                    : ( $c eq 'GREEN') ? 1                                      #  $$format{color}
                    : ( $c eq 'BLUE' ) ? 2                                      #  $$format{color}
                    : -1;
        for ( 1..$b) { printf  "\n"; };                                         #   vertical format
        if ( defined $info ) {
            my $msg = sprintf "%-*s%s\n",$i,$h,$info;                           #   Line Headers are blank/indented
                switch ( $choice )   {
                    case    0   { print RED   $msg, RESET; }
                    case    1   { print GREEN $msg, RESET; }
                    case    2   { print BLUE  $msg, RESET; }
                    else        { print       $msg, RESET; }
                }#switch
            for ( 1..$s) { printf  "\n"; };                                     #   vertical format, lines between headline and list
        }#if headline defined
        if ( ref ( $list ) eq "ARRAY" ) {
            foreach my $entry   ( @{$list} )  {
                my  $msg = sprintf"%-*s%s\n",$i,'',$entry;                      #   Line Headers are blank/indented
                switch ( $choice )   {
                    case    0   { print RED   $msg, RESET; }
                    case    1   { print GREEN $msg, RESET; }
                    case    2   { print BLUE  $msg, RESET; }
                    else        { print       $msg, RESET; }
                }#switch
           }# for all
        } elsif ( ref ( $list ) eq "HASH" ) {
            t_warn ( "Coding Error :: Parameter is a HashREF",
                     { newline => 2 } );
            exit;
        } else {
           my  $msg = sprintf"%-*s%s\n",$i,'',$list;                            #   List is a single item
           switch ( $choice )   {
               case    0   { print RED   $msg, RESET; }
               case    1   { print GREEN $msg, RESET; }
               case    2   { print BLUE  $msg, RESET; }
               else        { print       $msg, RESET; }
           }#switch
        }
        for ( 1..$v) { printf  "\n"; }                                          #   vertical format
}#sub   t_list

sub     t_function_header {
        my  (   $name, $parameter  )   =   @_;                                  #   eg   'check_project_suite_setup()';
            $parameter  //= ' ';
        my  $m  = sprintf   "%s(%s)",$name, $parameter;
        t_blank (   $m
                ,   { before    =>  1
                    , lineheader=>  5
                    , newline   =>  1
                    , bold      =>  1   } );
}#sub   t_function_header



#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D S


#----------------------------------------------------------------------------
# End of module Terminal.pm
1;
