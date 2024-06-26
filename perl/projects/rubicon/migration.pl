#!/usr/bin/perl -w
#----------------------------------------------------------------------------
# File      migration.pl  
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   Prototype of a Perl Project, for fast prototyping
#           Migrate verilog test cases -> UVM test cases
#----------------------------------------------------------------------------
# I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;
use version; my $VERSION = version->declare('v1.01.01');                        # v-string using Perl API

#----------------------------------------------------------------------------
# U s e r   Perl - L i b r a r i e s
 
use lib	"$ENV{PERLPATH}";                                                       # Add Include path to @INC

use Application                             qw  (   new         );              # Create Application
#use Application::CLI                        qw  (   new         );              # Create Application
use Application::Performance                qw  (   set_postamble
                                                    run_time
                                                    elapsedtime );              # Measure run time/wall clock

#----------------------------------------------------------------------------
# C O N S T A N T s

#----------------------------------------------------------------------------
# C O N F I G U R A T I O N
my $format  =   {   indent          =>  5,
                    indent_pattern  =>  '',
                };

my $termination =   [   qw  (   line
                                starttime
                                endtime 
                                line        )   ];                              #

my %config  =   (   application     =>  'Project Migration',
                    synopsis        =>  'Migrate Test Cases',                   # attack surface, CFT, TTM
                    projecthome     =>  '~/ws/perl/projects/rubicion',          # UserHome/ws/perl/projects/rubicon
                    project         =>  'migration',                            # ProjectName
                    configuration   =>  'config',                               # ProjectConfiguration
                    logging         =>  'logs',                                 # ProjectLogging
                    termination     =>  $termination,                           # Termination Information
                    format          =>  $format,                                # Format Parameter
                );                                                              
#----------------------------------------------------------------------------
# M A I N

my $a   =   Application->new(   Author  =>  'Lutz Filor'
                            ,   %config                     );                  # New API

sleep 2;
$a->sample_timingresolution();
$a->run_time();

my $perf = elapsedtime(localtime());
#printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{t_stamp};
#printf  "%5s%s%s\n"   ,'','Start0time : ',${$perf}{start0};
printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{start};
printf  "%5s%s%s\n"   ,'','End   time : ',${$perf}{end};                        #
printf  "%5s%s%s"     ,'','End0  time : ',${$perf}{end0};                          
printf  "%5s%s%s\n"   ,'','End1  time : ',join ' ',@{$perf}{end1};              #
printf  "%5s%s%s\n"   ,'','End2  time : ',${$perf}{end2};                       #
#printf  "%5s%s%s\n"   ,'','End4  time : ',${$perf}{end4};                      # Time::HiRes::gettimeofday Works !!
#printf  "%5s%s%9d%s\n",'','Rsltn Time : ',${$perf}{resolution},' ns';          #
printf  "%5s%s%s%s\n" ,'','Rsltn Time : ',${$perf}{resolution}/10e6,' ms';
#printf  "%5s%s%9d%s\n",'','Rsltn1Time : ',${$perf}{resolution1},'  s';         #
printf  "%5s%s%s\n\n"  ,'',$0,' done ...';

#printf "%5s%s%s\n",'','Type of Reference : ',ref $a;
#printf "%5s%s%s\n",'','Application       : ',${$a}{application};
#$a->set_postamble( [ qw( endtime ) ] );
$a->terminate( );


# P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------
# END of migration.pl
__END__
