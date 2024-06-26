#!/usr/bin/perl -w
####!/tools/sw/perl/bin/perl -w 
  
#   Author      Lutz Filor
#   Phone       408 807 6915
#   FILE        perl/projects/prototypes/cg.pl
# 
#   Purpose     Code Generate   -   
#               Rapid Prototype of a Perl Project, for fast prototyping
# 
#----------------------------------------------------------------------------
# I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;
use version; my $VERSION = version->declare('v1.01.0');                         # v-string using Perl API

#----------------------------------------------------------------------------
# U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                           # Add Include path to @INC

use App              qw (   new
                            update
                            inspect     );                                      # Create Application
#use Application::CLI               qw  (   new         );                      # Create Application
use App::Performance        qw  (   elapsedtime );                              # Measure run time/wall clock

#----------------------------------------------------------------------------
# C O N S T A N T s

#----------------------------------------------------------------------------
# C O N F I G U R A T I O N
my $format  =   {   indent          =>  5,
                    indent_pattern  =>  '',
                };

my %config  =   (   application     =>  'Rapid Prototyping',
                    synopsis        =>  'Code Generation',                      # attack surface, CFT, TTM
                    projecthome     =>  '~/ws/perl/projects',                   # UserHome/ws/perl/projects
                    project         =>  'cg',                                   # ProjectName
                    configuration   =>  'config',                               # ProjectConfiguration
                    logging         =>  'logs',                                 # ProjectLogging
                    subs            =>  [],                                     #
                    termination     =>  [ qw (message) ],                       # Termination Information
                    format          =>  $format,
                );                                                              
#----------------------------------------------------------------------------
# M A I N

my $a   =   App->new(   Author  =>  'Lutz Filor',                               #   New application
                        %config                     );                          #   New API

sleep 2;
$a->sample_timingresolution();
my $perf = elapsedtime(localtime());
### printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{t_stamp};
### printf  "%5s%s%s\n"   ,'','Start time : ',${$perf}{start};
### printf  "%5s%s%s\n"   ,'','End   time : ',${$perf}{end};                        #
### printf  "%5s%s%s"     ,'','End0  time : ',${$perf}{end0};                          
### printf  "%5s%s%s\n"   ,'','End1  time : ',join ' ',@{$perf}{end1};              #
### printf  "%5s%s%s\n"   ,'','End2  time : ',${$perf}{end2};                       #
### #printf  "%5s%s%s\n"   ,'','End4  time : ',${$perf}{end4};                      # Time::HiRes::gettimeofday Works !!
### printf  "%5s%s%9d%s\n",'','Rsltn Time : ',${$perf}{resolution},' ns';           #
### printf  "%5s%s%s%s\n" ,'','Rsltn Time : ',${$perf}{resolution}/10e6,' ms';
### printf  "%5s%s%9d%s\n",'','Rsltn1Time : ',${$perf}{resolution1},'  s';          #
### printf  "%5s%s%s\n"   ,'',$0,' done ...';


printf  "%5s%s\n"   ,'','$a->inspect( 1st time )';
$a->inspect(    {   header  =>  'Inspect( 1st time)'
                ,   indent  =>  5
                ,   pattern =>  ''
                ,   spacer  =>  2   }   );
        
printf  "%5s%s\n"   ,'','$a->update( %options )';
$a->update  (   {   author  =>  'Lutz Filor'
                ,   birth   =>  "1966-02-25"  } );
$a->inspect(    {   header  =>  'Inspect( 2nd time )'
                ,   indent  =>  5
                ,   pattern =>  ''  }   );

#printf "%5s%s%s\n",'','Type of Reference : ',ref $a;
#printf "%5s%s%s\n",'','Application       : ',${$a}{application};
$a->terminate();


# P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------
# END of p1.pl
__END__
