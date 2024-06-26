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

use version; my $VERSION = version->declare('v1.01.02');                    #   v-string using Perl API

#----------------------------------------------------------------------------
#   U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                       #   Include path to @INC, general
use lib             "$ENV{PERLPROJ}";                                       #   Include path to @INC, specific
                           
use IP_XACT::API    qw  (   get_api
                            get_config  );                                  #   Add Command line API, App configuration

use IP_XACT::App    qw  (   new         );

use DS::Hash        qw  (   list_hash   );
use DS::Array       qw  (   list_array  );

sub     my_subroutine   {
        printf  "%*smy_subroutine()\n",5,'';
        return;
}#sub   my_subroutine


my_subroutine();
my  $a  =   IP_XACT::App->new   (   );

list_hash   (   $a  );
my  $subs   =   $a->get( 'subs' );                                          #   Get [ArrRef]    list of subroutines
list_array  (   $subs,  {   name    =>  '[$subs]'   }   );

printf  "%*sList namespace main:: ",5,'',
foreach my $sym ( keys %{main::} )   {
    printf "%*s Symbol %s\n",5,'',$sym;
}
$a->terminate();



#   P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------

#sub     my_subroutine   {
#        return;
#}#sub   my_subroutine

#----------------------------------------------------------------------------
#   END of ip_xact.pl
__END__
