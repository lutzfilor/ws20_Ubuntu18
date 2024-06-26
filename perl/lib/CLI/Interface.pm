package CLI::Interface;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/CLI/Interface.pm
#
# Created       02/13/2019          
# Author        Lutz Filor
# 
# Synopsys      CLI::Interface::report_param()
#                    input   message, 
#                    return  list of design instances
#
# NOTE          Maintain CLI::Changes log to document this module            
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Term::ANSIColor         qw  (   :constants  );                              # available
#   print BLINK BOLD RED $msg, RESET;

use lib				        qw  (   /mnt/ussjf-home/lfilor/ws/perl/lib );     # Add Include path to @INC
use Dbg                     qw  (   debug subroutine    );
use File::IO::UTF8::UTF8    qw  (   read_utf8   );

#use lib                qw  (   ../lib );               # Relative UserModulePath
#use UTF8               qw  (   read_utf8   );          # 05/08/2019
#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.02");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  ( report_param
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S
Readonly my $TRUE           =>     1;               # Create boolean like constant
Readonly my $FALSE          =>     0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S

sub     report_param    {
        my  (   $opts_ref                           # command line options
            ,   $message
            ,   $parameter  )   =   @_;
        my $i = ${$opts_ref}{indent};               # indentation
        my $p = ${$opts_ref}{indent_pattern};       # indentation pattern
        my $m = ${$opts_ref}{$message};             # display message
        my $v = ${$opts_ref}{$parameter};           # display value
        my $n = subroutine('name');                 # name of subroutine
        printf "\n%*s%s()\n", $i,$p,$n;
        printf "%*s%s %s\n",$i,$p,$m,$v;
        return;
}#sub   report_param
#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

#----------------------------------------------------------------------------
#  End of module
1;
