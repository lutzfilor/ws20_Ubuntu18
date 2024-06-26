#!/usr/bin/perl -w
  
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   IP_XACT designer, editor, validator, for fast prototyping
# 
#----------------------------------------------------------------------------
#   I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;

use version; my $VERSION = version->declare('v1.01.04');                        #   v-string using Perl API

#----------------------------------------------------------------------------
#   U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                           #   Include path to @INC, general
use lib             "$ENV{PERLPROJ}";                                           #   Include path to @INC, specific
                           
#use IP_XACT::API    qw  (   get_api     
#                            get_config  );                                      #   Add Command line API, App configuration

use IP_XACT::App    qw  (   new         
                            get
                            
                            debug
                            subroutine

                            terminate   );

use DS::Hash        qw  (   list_hash   );
use DS::Array       qw  (   list_array  );

my  $a  =   IP_XACT::App->new   (   );

#list_hash   (   $a  );
my  $start1 =   $a->get( 'start1'   );
my  $file   =   $a->get( 'file'     );
my  $dbg    =   $a->get( 'dbg'      );
my  $subs   =   $a->get( 'subs_up'  );                                          #   Get [ArrRef]    list of subroutines
my  $debug  =   $a->get( 'd1'   );                                              #   Schnittmenge    of subroutines to report on
my  $dhash  =   $a->get( 'debug'   );                                           #   Schnittmenge    associated array
#my  $startup=   $a->get( 'start1_up');
#list_array  (   $subs,  {   name    =>  '[$subs]'   
#                        ,   size    =>  1
#                        ,   leading =>  2           }   );
#list_array  (   $debug, {   name    =>  '[$debug]'
#                        ,   before  =>  1           }   );
#list_hash   (   $dhash, {   name    =>  '{$dhash}'
#                        ,   size    =>  1
#                        ,   leading =>  1           }   );
#list_array  ( $start1,  {   name    =>  '[$start1]'   
#                        ,   leading  =>  2           }   );
#list_array  ( $startup,  {   name    =>  '[$start1_up]'   
#                        ,   leading  =>  1           }   );
#my  $opt1   =   $a->get( 'dbg' );
#printf      "%*s%s <<<\n",5,'',$opt1;
#list_array  (   $subs,  {   name    =>  '[$subs]'   }   );

#my  $s_subs =   $#{$subs};                                                      #   Number of subroutines
#printf  "%5sNumber of ",'',$s_subs
my_subroutine();                                                                #   test debug feature

$a->terminate();                                                                #   Application planned termination ?? - why did this work w/out import

#   P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------

sub     my_subroutine   {
        my  $n  =   subroutine('name');                                         #   subroutine name
        printf "%*s%s()\n",5,'',$n if( debug($n) );
        return;
}#sub   my_subroutine

#----------------------------------------------------------------------------
#   END of ip_xact.pl
__END__
