package IP_XACT::API;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          projects/IP_XACT/API.pm
#               
# Created       10/03/2020
# Author        Lutz Filor
# 
# Synopsys      Definition of application programming interface (API)
#               Definition of application specific configurations, settings
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

#use Readonly;                                                                  #   [Fi]    if application constants are needed
use Switch;                                                                     #   [Fi]    Installed 11/28/2018
   
use Getopt::Long;

use lib            "$ENV{PERLPATH}";                                               # Add Include path to @INC
use DS::Hash    qw  /   list_hash
                        prune_hash  /;
use Terminal    qw  /   t_list
                        t_warn      /;                                          #   Terminal uniform display 
#----------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.05");

use Exporter qw (import);                               # Import <import>method  
use parent 'Exporter';                                  # parent replaces base

#our @EXPORT     =   qw  (   );#implicite export        #   deprecated - not recommended 

our @EXPORT_OK  =   qw  (   get_api
                            get_config
                        );#explicite export             # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL   =>  [   @EXPORT_OK  ]   #
                        );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       C O N F I G U R A T I O N

my  $defines=   {   };
my  $opts   =   {   };


#===============================================================================
my  $format =   {   indent          =>  5,                                      #   default indentation
                    indent_pattern  =>  '',                                     #   default pattern
                };# format_end

#===============================================================================
my  %config =   (   appname         =>  'IP_XACT creator',                      #   Application Longname, different form Filename
                    synopsis        =>  'Create Memory Maps',                   #   attack surface, CFT, TTM
                    projecthome     =>  "$ENV{PERLPROJ}",                       #   UserHome/ws/perl/projects. '~/ws/perl/projects'
                    project         =>  'IP_XACT',                              #   ProjectName
                    datahome        =>  "$ENV{PERLDATA}"."/ip_xact",
                    logging         =>  'logs',                                 #   ProjectLogging
                    subs            =>  [],                                     #
                    vwsh            =>  1,                                      #   Vertical Whitespace before termination message
                    vwst            =>  2,                                      #   Vertical Whitespace after  termination message
                    termination     =>  [ qw (  head
                                                line      
                                                message
                                                line
                                                stoptime
                                                starttime
                                                runtime
                                                line
                                                tail        ) ],                #   Termination Information
                    format          =>  $format,                                #   Default format information, for terminal
                );# config_end
#===============================================================================

my  $tag;
my  %options    =   (   );                                                      #   option-storage
my  %description=   (   'debug|dbg=s@'      =>  \$options{dbg}                  #   Debug     Turn on debug feature on sub by sub base
                    ,   'file=s'            =>  \$options{file}                 #   option-description 
                    ,   'debugging|d'       =>  \$options{debug}                #   debugging feature for App::, App::Dbg::ST::
                    ,   'worksheet|ws=s'    =>  \$options{worksheet} 
                    ,   'tag|t=s'           =>  \$tag               );          #   Command line options


#----------------------------------------------------------------------------

sub     get_api {
        check_cline ();                                                         #   Preemptive CL checking agains user error
        GetOptions  (    %description   );                                      #   
        prune_hash  (   \%options       );                                      #   Clean up API options
        return  %options;  
}#sub   get_api

sub     get_config  {
        #   load a configuration from a file                                    #   overriding configuration by file
        return  %config;                                                        #   argv    -->     %config
}#sub   get_config

#----------------------------------------------------------------------------
#   P R I V A T E  M E T H O D S

sub     check_cline  {                                                          #   commandline check against option w/out -,--
        my  $clic   =   [];                                                     #   commandline check
        foreach my $option ( @ARGV )  {
            if ( $option =~ m/^[^-]+/ ) {
                my $l = sprintf  "%s Not starting w/ <'-'>",$option;
                push    ( @{$clic}, $l );
            }
        }#inspect all options
        my $info = "Check your commandline options, for leading w/ hyphen <'-'>";
        if ( @{$clic} ) {
            t_warn  (   $info, { after => 1      } );
            t_list  (   $clic, { after => 1
                               , color => 'RED' } );  
        };
        return;
}#sub   check_cline

#----------------------------------------------------------------------------
#   End of module IP_XACT/API.pm
1;
