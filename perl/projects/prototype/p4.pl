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
use version; my $VERSION = version->declare('v4.01.01');                    # v-string using Perl API

#----------------------------------------------------------------------------
# U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                       #   Include path to @INC, general
use lib             "$ENV{PERLPROJ}/prototype";                             #   Include path to @INC, specific

use p3::API         qw  (   get_api     );                                  #   Add Command layer API
use App             qw  (   new
                            get
                            update
                            inspect     );                                  # Create Application
use DS::Array       qw  (   );
#use Application::CLI               qw  (   new         );                  # Create Application
use App::Performance        qw  (   elapsedtime 
                                    sample_timingresolution
                                );                          # Measure run time/wall clock

#----------------------------------------------------------------------------
# C O N S T A N T s

#----------------------------------------------------------------------------
# C O N F I G U R A T I O N
my $format  =   {   indent          =>  5,
                    indent_pattern  =>  '',
                };

my %config  =   (   application     =>  'Rapid Prototyping',
                    synopsis        =>  'Reduce Redundancy',                    # attack surface, CFT, TTM
                    projecthome     =>  '~/ws/perl/projects',                   # UserHome/ws/perl/projects
                    project         =>  'p4',                                   # ProjectName
                    configuration   =>  'config',                               # ProjectConfiguration
                    logging         =>  'logs',                                 # ProjectLogging
                    message         =>  'Good bye',                             # Termination message
                    subs            =>  [],                                     #
                    termination     =>  [ qw (  line
                                                message
                                                line
                                                stoptime
                                                starttime
                                                runtime
                                                line        ) ],                # Termination Information
                    format          =>  $format,
                ); 
#----------------------------------------------------------------------------
# M A I N

my $a   =   App->new(   Author  =>  'Lutz Filor',                               #   New application
                        %config                     );                          #   New API

sleep 2;
### printf  "%5s%s"   ,'',"\$a->sample_timingresolution( )";
### $a->sample_timingresolution();
### my $perf = elapsedtime(localtime());

# printf  "%5s%s\n"   ,'','$a->inspect( 1st time )';
# $a->inspect (   {   header  =>  'Inspect( 1st time)'
#                 ,   indent  =>  5
#                 ,   pattern =>  ''
#                 ,   spacer  =>  2   }   );
#         
# printf  "%5s%s\n"   ,'','$a->update( %options )';
# $a->update  (   {   author  =>  'Lutz Filor'
#                 ,   birth   =>  "1966-02-25"  } );
# $a->inspect (   {   header  =>  'Inspect( 2nd time)'
#                 ,   indent  =>  5
#                 ,   pattern =>  ''  }   );
# printf  "%5s%s\n"   ,'',"\$a->get( 'subs' )";
# my  $subs   =   $a->get (   'subs'  );

#printf "%5s%s%s\n",'','Type of Reference : ',ref $a;
#printf "%5s%s%s\n",'','Application       : ',${$a}{application};
#printf  "%5s%s\n"   ,'', ref ( $a );               # output App
#printf  "%5s%s\n"   ,'',"\$a->terminate( )";
$a->terminate();


# P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------
# END of p1.pl
__END__
