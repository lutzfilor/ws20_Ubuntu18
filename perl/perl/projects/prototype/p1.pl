#!/tools/sw/perl/bin/perl -w 
####!/usr/bin/perl -w
  
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   Prototype of a Perl Project, for fast prototyping
# 
#----------------------------------------------------------------------------
# I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;
use version; my $VERSION = version->declare('v1.01.01');                        # v-string using Perl API

#----------------------------------------------------------------------------
# U s e r   Perl - L i b r a r i e s
 
#use lib						qw  ( ~/ws/perl/lib/ );                         # Add Include path to @INC
#use lib						    qw  ( /mnt/ussjf-home/lfilor/ws/perl/lib );     # Add Include path to @INC

use lib							"$ENV{PERLPATH}";                               # Add Include path to @INC

use Application                             qw  (   new         );              # Create Application
use Application::CLI                        qw  (   new         );              # Create Application
use Application::Performance::Performance   qw  (   elapsedtime );              # Measure run time/wall clock

#----------------------------------------------------------------------------
# C O N S T A N T s
#----------------------------------------------------------------------------
# C O N F I G U R A T I O N
my %config  =   (   application     =>  'Rapid Prototyping',
                    synopsis        =>  'Reduce Redundancy',                    # attack surface, CFT, TTM
                    projecthome     =>  '~/ws/perl/projects',                   # UserHome/ws/perl/projects
                    project         =>  'p1',                                   # ProjectName
                    configuration   =>  'config',                               # ProjectConfiguration
                    logging         =>  'logs',                                 # ProjectLogging
                );                                                              
#----------------------------------------------------------------------------
# M A I N

my $a   =   Application->new();

sleep 2;
my $perf = elapsedtime(localtime());
printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{t_stamp};
printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{start};
printf  "%5s%s%s\n"   ,'','End   time : ',${$perf}{end};                        #
printf  "%5s%s%s"     ,'','End0  time : ',${$perf}{end0};                          
printf  "%5s%s%s\n"   ,'','End1  time : ',join ' ',@{$perf}{end1};              #
printf  "%5s%s%s\n"   ,'','End2  time : ',${$perf}{end2};                       #
#printf  "%5s%s%s\n"   ,'','End4  time : ',${$perf}{end4};                      # Time::HiRes::gettimeofday Works !!
printf  "%5s%s%9d%s\n",'','Rsltn Time : ',${$perf}{resolution},' ns';           #
printf  "%5s%s%s%s\n" ,'','Rsltn Time : ',${$perf}{resolution}/10e6,' ms';
printf  "%5s%s%9d%s\n",'','Rsltn1Time : ',${$perf}{resolution1},'  s';          #
printf  "%5s%s%s\n"   ,'',$0,' done ...';

# P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------
# END of p1.pl
__END__
