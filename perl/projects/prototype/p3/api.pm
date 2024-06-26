package p3::API;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          projects/prototype/p3/API.pm
#               
# Created       07/25/2020
# Author        Lutz Filor
# 
# Synopsys      Definition of application programming interface (API)
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Switch;                                                                     # Installed 11/28/2018
   
use lib			"$ENV{PERLPATH}";                                               # Add Include path to @INC

#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.01");

use Exporter qw (import);                               # Import <import>method  
use parent 'Exporter';                                  # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export             # NOT recommended 

our @EXPORT_OK  =   qw  (   get 
                        );#explicite export             # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL   =>  [   @EXPORT_OK  ]   #
                        );

#----------------------------------------------------------------------------
#   C O N S T A N T S

#----------------------------------------------------------------------------
#   C O N F I G U R A T I O N

my $format  =   {   indent          =>  5,                                      #   default indentation
                    indent_pattern  =>  '',                                     #   default pattern
                };

my %config  =   (   appname         =>  'Prototype 3',                          #   Application Longname, different form Filename
                    synopsis        =>  'Rapid prototyping',                    # attack surface, CFT, TTM
                    projecthome     =>  "$ENV{PERLPROJ}",                       # UserHome/ws/perl/projects. '~/ws/perl/projects'
                    project         =>  'prototype/p3',                         # ProjectName
                    configuration   =>  'config',                               # ProjectConfiguration
                    datahome        =>  "$ENV{PERLDATA}",
                    logging         =>  'logs',                                 # ProjectLogging
                    subs            =>  [],                                     #
                    termination     =>  [ qw (  line 
                                                message 
                                                line    ) 
                                        ],                                      # Termination Information
                    format          =>  $format,
                );

my  %api    =   (   'defines=s'             =>  \%defines,
                    'man|m'                 =>  \&help2,                                # Manual    Information
                    'input|in=s'            =>  \$opts{pseudo_seq},                     # Source    w/ read,write transaction definition
                    'debug|dbg=s@'          =>  \$opts{dbg},                            # Debug     Turning on debug feature on sub by sub
                    'dbg0'                  =>  \$opts{dbg0},                           #           Observe prior to debug feature
                    'dbg1'                  =>  \$opts{dbg1},                           #           Reveal unpacking and assignment, ll
                	'silent'				=>	\$opts{silent},							# Silent 	Turning reporting off
                    'test=s'                =>  \$opts{test},                           # Test      Testing aspects for development
                    'file=s'                =>  \$opts{file},
                    'list=s'                =>  \$opts{list},                           # List      subroutines, modules
                    'flush'                 =>  \$opts{flush},                          # Flush     Test Sequence
                    'scan'                  =>  \$opts{scan},                           #           Scan sweep full address range
                    'diag'                  =>  \$opts{diag},                           #           Diagnostic selected address in range
                    'init'                  =>  \$opts{init},                           #           Initialization of IP block
                    'random|rand|r=s@'      =>  \$opts{rand},                           #           Random value sweep full address range
                    'fullrand'              =>  \$opts{fullrand},                       #           Random data random order
                    'specification|spec=s'  =>  \$opts{spec},                           # Input     test specification
                    'sequence|seq=s'        =>  \$opts{seq},                            # Output    test sequence
                    'output|o=s'            =>  \$opts{log},                            # Logfile   rename compile logfile
                    'help|h|?:s'            =>  \$opts{help},                           # Usage     Information
                    'map=s'                 =>  \$opts{map},                            # Map       subdirectory
                    'maps=s'                =>  \$opts{maps},                           #           subroutines
                    'open:s'                =>  \$opts{open},                           #           Experimental binary filename
                    'lint:s'                =>  \$opts{lint},                           # Lint      Take manual text files and apply
                    'colar=i'               =>  \$opts{colar},                          #           Lines around prio and past the target line
                    'seek=s'                =>  \$opts{seek},                           # Seek      grep
                    'path=s'                =>  \$opts{path},                           #           absolute path to seek_path
                    'find'                  =>  \$opts{find},                           # Find      objects aka modules
                    'modules|mod=s@'        =>  \$opts{modules},
                    'workbook|wb=s'         =>  \$opts{workbook},                       # Input     .xlsx file
                    'worksheet|ws=s'        =>  \$opts{worksheet},                      #           Select worksheet/tab
                    'column|col=s'          =>  \$opts{column},                         #           Select column
                    'row=s'                 =>  \$opts{row},                            #           Select row
                    'cell=s{2}'             =>  \$opts{cell},                           #           Select cell                                my  %format     =   (   
                	'date=s'				=>	\$opts{date},							#			Select worksheet/filename 'YYYY-MM-DD' my  %options    =   (   );
                    'target=s'              =>  \$opts{output},                         # Output    .xlsx file overwrite filename
                    'coverage|cover=s'      =>  \$opts{coverage},                       # Input     .html file "legacy.html"                   #  S U B R O U T I N S  -  P U B L I C  M E T H O D E S
                );                                                                      # Command Line Processor                              
sub     get {
        my  %options;

        return  %options;  
}#sub   get

#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S


#----------------------------------------------------------------------------
#  End of module p3/API.pm
1;
