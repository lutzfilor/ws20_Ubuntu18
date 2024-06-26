package File::IO::Log;
# File          ~/ws/perl/lib/File/IO/Log.pm
#
# Refactored    08/13/2020          lib/File/IO/UTF8
#               
# Author        Lutz Filor
# 
# Synopsis      Log::log_activity       ( LogFile, LogMessage )
#               Log::activity_message   ( {HashRef} )                           #   w/ message info
#               Log::log_hashref        ( {HshRef}, $Logfile, format )
#               Log::log2_hashref       ( {HshRef}, $Logfile, format )
#               Log::log_arrayref       ( [ArrRef], $Logfile, format )

#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

#use lib "$ENV{PERLPATH}";

use DS::Array       qw/     maxwidth
                            unique          /;

use File::IO::UTF8  qw/     read_utf8
                            write_utf8      /;

#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.12");

use Exporter qw (import);
use parent 'Exporter';                              # replaces base; base is deprecated

#our @EXPORT    =   qw(     );                      # implicite export deprecated

our @EXPORT_OK  =   qw(     log_hashref
                            log2_hashref
                            log_arrayref
                            log_activity
                            activity_message    );  # log DS, Activities

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]   );     # Export groups :ALL

#----------------------------------------------------------------------------
#       C O N S T A N T S


#----------------------------------------------------------------------------
#       S U B R O U T I N S

#       my $ac
#       my $logm = activity_message ( { date    =>  `TZ='America/Los_Angeles' 
#                                                    date +%Y/%m/%d-%H:%M:%S`
#                                       proc    =>  $logmessage                  }
#                                   );

sub     activity_message    {
        my  (   $info   )   =   @_;                                             #   {HashRef}   with message info
        my  $msg    =   '';
        my  $d      =   $$info{date};                                           #   date
        my  $a      =   $$info{proc};                                           #   activity, process
        chomp   $d;
        $msg    =   sprintf "%s %s",$d,$a;
        #printf  "%5smessage :: %s",'',$msg;                                    #   Development vestigal
        return  $msg;
}#sub   activity_message

#       my  $logf   =   "$ENV{PERLDATA}"."/logs/backup/activity.log";           #   Log file
#       log_activity    (   $logf,  $logm   );

sub     log_activity    {
        my  (   $file                                                           #   Logfile name
            ,   $message    )   =   @_;                                         #   Log message
        my  $log    =   [];
        my  $tmp    =   [];
        chomp  $file                if  ( defined $file );
        #printf "%5s%s\n",'',$file   if  ( defined $file );                     #   Development vestigal
        push ( @{$tmp},$message )   if  ( defined $message );                   #   Insert latest log message at file head
        $log = [ read_utf8($file) ] if  ( -e -f -r $file );                     #   Read log file
        foreach my $line (@{$log}) {
            chomp $line;
            #printf "%5s>>>> %s\n",'',$line;                                    #   silence terminal copy back
            push ( @{$tmp}, $line );
        }#for all line
        write_utf8( $tmp, $file )    if  ( defined $file );
        return;                                                                 #   terminate subroutine
}#sub   log_activity

sub     log_arrayref    {
        my  (   $ArrRef                                                         #   Target Array to be loged
            ,   $file                                                           #   Logfile
            ,   $format )   =   @_;                                             #   formatting logfile, optional
        my  $i  =   $$format{indent};                                           #   Overwrite of indent space
        my  $p  =   $$format{pattern};                                          #   Overwrite of indent pattern
        my  $no =   $$format{number};                                           #   Turn on numbering line numbering
        my  $ap =   $$format{appendix};                                         #   appendix to column item
        my  $align  =   $$format{align};                                        #   align left/right w/in column
            $align  =   'unaligned';                                            #   Default align == unalignment
            $i      //=  5;                                                     #   Default indent
            $p      //= '';                                                     #   Default pattern
            $ap     //= '()';                                                   #   Default col item appendix of subroutine_names<'()'>
        my  $a  =   ( $align eq 'right' ) ? 1 :
                    ( $align eq 'left'  ) ?-1 : -1;
        my  $tmp=   [];                                                         #   temporary file of array
        my  $l  =   '';                                                         #   temporary line array element
        my  $w  =   maxwidth($ArrRef);                                          #   Maxwidth of Column list
        my  $ln =   $#{$ArrRef};                                                #   Size of Array
        my  $w0 =   length $ln + 1;                                             #   Space for numbering
            $ln =   1;                                                          #   Initialize line counter
        foreach my $line ( @{$ArrRef} ) {                                       #   unknown array reference
            chomp   $line;                                                      #   remove potential newline \n
            if ( defined $$format{number} ) {                                   #   turn on line numbering
                $l  = sprintf   "%*s%*s%*s%s",$w0,$ln++                         #   item number
                                ,$i-$w0,$p,$a*$w,$line,$ap;                     #   padding,item&appendix 
            } else {
                $l  = sprintf   "%*s%*s%s",$i,$p,$w,$line,$ap;                  #   reporting without line numbering
            }
            push    ( @{$tmp}, $l );                                            #   compile temporary logfile
        }
        write_utf8( $tmp, $file )    if  ( defined $file );                     #   Writeout Logfile, if filename defined
        return;                                                                 #   default statement
}#sub   log_arrayref

sub     log_hashref {
        my  (   $HshRef
            ,   $file   
            ,   $format )   =   @_;
        my  $i  =   $$format{indent};
        my  $p  =   $$format{pattern};
            $i  //= 5;
            $p  //= '';
        my  $tmp=   [];
        my  $w  =  maxwidth( [ keys %{$HshRef} ] );                             #   See Perl - Design Pattern
        while ( my (($k, $v) ) = each(%{$HshRef}) ) {                           #   ${$HshRef}{$k} == $v
            my  $l  = sprintf "%*s%*s | %s",$i,$p,$w,$k,$v;
            push    ( @{$tmp}, $l );
        }
        write_utf8( $tmp, $file )    if  ( defined $file );
        return;
}#sub   log_hashref

sub     log2_hashref    {
        my  (   $HshRef
            ,   $file   
            ,   $format )   =   @_;
        my  $i  =   $$format{indent};
        my  $p  =   $$format{pattern};
            $i  //= 5;
            $p  //= '';
        my  $sort   =   {};
        my  $tmp    =   [];
        my  $w1 =  maxwidth( [ keys %{$HshRef} ] );                             #   See Perl - Design Pattern
        my  $w2 =  maxwidth( [ values %{$HshRef} ] );                           #   See Perl - Design Pattern
        while ( my (($k, $v) ) = each(%{$HshRef}) ) {                           #   ${$HshRef}{$k} == $v
            #printf "%*sModule : %s\n",5,'',$v;                                 #   Development vestigal lead to development of unique()
            push ( @{${$sort}{$v}}, $k );
        }#resort
        my  $modules = unique( [values %{$HshRef}] );                           #   select unique modules
        foreach my $mod ( sort @{$modules } ) {
            foreach my $sub ( sort @{${$sort}{$mod}} ) {
                my  $l  = sprintf   "%*s%*s | %*s"
                                    ,$i,$p,$w2,$mod,$w1,$sub;
                push    ( @{$tmp}, $l );
            }#for all subroutines
        }#for all modules
        write_utf8( $tmp, $file )    if  ( defined $file );
        return;
}#sub   log2_hashref
#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D S

sub     filename    {
        my  (   $fullname   )   =   @_;                                         #   absolute file path
        my  @file_hierarchy =   split   /\//,   $fullname;
        my  $name   =   $file_hierarchy[-1];                                    #   pick ('name.txt') /path/to/file/ name.txt
        return  $name;
}#sub   filename

#----------------------------------------------------------------------------
#       End of module  -  Log.pm
1;
