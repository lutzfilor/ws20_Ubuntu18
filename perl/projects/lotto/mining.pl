#!/usr/bin/perl -w
####!/tools/sw/perl/bin/perl -w 
  
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   Prototype of a Perl Project, for fast prototyping
# 
#----------------------------------------------------------------------------
# I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;
use version; my $VERSION = version->declare('v1.01.02');                        # v-string using Perl API

#----------------------------------------------------------------------------
# U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                           # Add Include path to @INC

use Project::Lotto              qw  (   get_setup   );                                     # Hardcoded Information
use Application                 qw  (   new
                                        update
                                        inspect     );                          # Create Application
#use Application::CLI           qw  (   new         );                          # Create Application
use Application::Performance    qw  (   elapsedtime );                          # Measure run time/wall clock

#----------------------------------------------------------------------------
#   C O N S T A N T s

#----------------------------------------------------------------------------
#   C O N F I G U R A T I O N
my  $format =   {   indent          =>  5,
                    indent_pattern  =>  '',
                    reform          =>  'ON',                                       # remove trailing \n of hash/array values
                };

my  $termination    =   [   qw  (   message
                                    warnings
                                    errors
                                    line
                                    endtime
                                    starttime
                                    line
                                    runtime
                                    line
                                )
                        ];

#my  %config  =   (  application     =>  'mining',                                   # 'Rapid Prototyping',
#                    synopsis        =>  'Reduce Redundancy',                        # attack surface, CFT (Code for Testing), TTM
#                    projecthome     =>  '~/ws/perl/projects',                       # UserHome/ws/perl/projects
#                    project         =>  'Lotto',                                    # ProjectName
#                    configuration   =>  'config',                                   # ProjectConfiguration
#                    logging         =>  'logs',                                     # ProjectLogging
#                    termination     =>  [ qw (message) ],                           # Termination Information
#                    format          =>  $format,
#                );                                                              
#----------------------------------------------------------------------------
#   M A I N


my $a = Application->new(   Name        =>  'mining',
                            Author      =>  'Lutz Filor',
                            %config                     );                          # New API




sleep 2;
$a->sample_timingresolution();
my $perf = elapsedtime(localtime());

$a->inspect(    {   header  =>  'Inspect( 1st time)'
                ,   indent  =>  5
                ,   pattern =>  ''
                ,   spacer  =>  2
                ,   reform  =>  'ON'        }   );                                  # remove \n off of Array/Hash values
        
$a->update  (   {   author  =>  'Lutz Filor'
                ,   birth   =>  "1966-02-25"  } );

$a->inspect(    {   header  =>  'Inspect( 2nd time)'
                ,   indent  =>  5
                ,   pattern =>  ''  
                ,   reform  =>  'ON'        }   );                                  # remove \n off of Array/Hash value

$a->terminate();


# P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------
# END of mining.pl
__END__
