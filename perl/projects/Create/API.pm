package Create::API;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          projects/Create/API.pm
#               
# Created       10/19/2020
# Author        Lutz Filor
# 
# Synopsys      Definition of application programming interface (API)
#               Definition of application specific configurations, settings
# Keywords      Keywords are the soft underbelly of this application framework
#               and no function is allowed to overwrite or delete these configurations
#
#               dbg     =   [$packed,array,with,subroutines]                    #   --dbg=sub1,sub2,sub3 --dbg=sub4
#               dbg_up  =   [Unpacked array of subroutines]                 
#               debug   =   $Switch reference                                   #   --debugging, Switch for static debugging
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

#use Readonly;                                                                  #   [Fi]    if application constants are needed
use Switch;                                                                     #   [Fi]    Installed 11/28/2018
   
use Getopt::Long;

use lib         "$ENV{PERLPATH}";                                               #   [Fi]    Add/include library path to @INC
use DS::Hash    qw  /   list_hash   /;  

use Terminal    qw  /   t_list
                        t_warn      /;                                          #   Terminal uniform display 
#----------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.09");

use Exporter qw (import);                               #   Import <import>method  
use parent 'Exporter';                                  #   parent replaces base

#our @EXPORT    =   qw  (   );#implicite export         #   deprecated - not recommended 

our @EXPORT_OK  =   qw  (   get_api
                            get_config
                        );#explicite export             #   RECOMMENDED method

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
my  $layout =   [   qw  (   /data /logs /App /API   )   ];                      #   predefined subdirectories

my  $fllist =   [   qw  (   Create/data/_change.log )   ];                      #   list of files to clone

#===============================================================================

my  $file1  =   {   target      =>  "$ENV{PERLPROJ}"."/Create/data/_change.log"
                ,   destination =>  "$ENV{PERLPROJ}"
                ,   subpath     =>  "_change.log"                               #   <PROJECT>/<project>_change.log
                ,   clone       =>  "clone"                     };              #   $$self{clone}

my  $file2  =   {   target      =>  "$ENV{PERLPROJ}"."/Create/data/_change.log"
                ,   destination =>  "$ENV{PERLPROJ}"
                ,   subpath     =>  "APP/APP_change.log"                        #   <PROJECT>/APP/APP_change.log
                ,   clone       =>  "clone"                     };              #   $$self{clone}

my  $file3  =   {   target      =>  "$ENV{PERLPROJ}"."/Create/data/_change.log"
                ,   destination =>  "$ENV{PERLPROJ}"
                ,   subpath     =>  "API/API_change.log"                        #   <PROJECT>/API/API_change.log
                ,   clone       =>  "clone"                     };              #   $$self{clone}

my  $clonelist  =   [ $file1, $file2, $file3 ];
#===============================================================================

my  $logpth     =   "$ENV{PERLPROJ}"."/Create/logs/";

#===============================================================================

my  $tag;
my  %options    =   (   );                                                      #   option-storage
my  %description=   (   'debug|dbg=s@'      =>  \$options{dbg}                  #   Debug     Turn on debug feature on sub by sub base
                    ,   'project|proj|p=s@' =>  \$options{project}              #   create target project
                    ,   'file=s'            =>  \$options{file}                 #   option-description 
                    ,   'debugging|d'       =>  \$options{debugging}            #   debugging feature for App::, App::Dbg::ST::
                    ,   'logging|log'       =>  \$options{logging}              #   logging feature turning on static logfile
                    ,   'worksheet|ws=s'    =>  \$options{worksheet} 
                    ,   'tag|t=s'           =>  \$tag               );          #   Command line options
my  $tags   =   [   qw  (   dbg dbg_up  project file debug 
                            debugging   logging)  ];                              #   Command line option tags

#===============================================================================
my  %config =   (   appname         =>  'Project creator',                      #   Application Longname, different form Filename
                    synopsis        =>  'Create perl projects',                 #   Reduce attack surface, CFT, TTM
                    application     =>  'Create',                               #   ProjectName
                    applicationhome =>  "$ENV{PERLPROJ}",                       #   UserHome/ws/perl/projects. '~/ws/perl/projects'
                    applicationdata =>  "$ENV{PERLDATA}"."/create",
                    environment     =>  $layout,                                #   Project directory layout
                    cloning         =>  $fllist,                                #   Project files to be cloned
                    clonelist       =>  $clonelist,                             #   
                    logpath         =>  $logpth, 
                    raw_dbg_log     =>  "$logpth"."raw_dbg.log",                #   Logging Command Line directives
                    raw_sub_log     =>  "$logpth"."sub_collection.log",         #   Logging list of subroutines linked/found
                    debug_log       =>  "$logpth"."reporting_subs.log",         #   Logging list of reporting subs   
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
                    tags            =>  $tags,                                  #   Default list of API options
                );# config_end
                
#----------------------------------------------------------------------------

sub     get_api {                                                               #   Load the CL options defined in THIS api
        check_cline ();                                                         #   Preemptive CL checking agains user error
        GetOptions  (   %description    );                                      #   API descriptions    ==>    API options
        prune_cline (   \%options, $options{debugging}  );                      #   Remove undefined API options, with debugging options
        return  %options;  
}#sub   get_api

sub     get_config  {                                                           #   This function is ONLY used for PEEKING into %config
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

sub     prune_cline  {                                                          #   remove undefined hash value entries/otptions after command line evaluation
        my  (   $href                                                           #   %options is the target for all API descriptions
            ,   $dbg    )   =   @_;                                             #   overruling debug parameter - optional
        my  @tmp=   ( split(/::/, (caller(1))[3]) );                            #   Name of the function which called subroutine == App::Dbg::subroutine('name')
        my  $n  =   pop @tmp;                                                   #   [Fi]    Work around - Experimental pop on scalar is now forbidden at
        my  $verbose    =  $dbg;                                                #   remove UNDEFINED %options after command line evaluation 
        if( $verbose ) {
            printf  "%*s%s( %s )\n",5,'',$n,scalar( keys %{$href} );
        }
        while   ( my ($k, $v) = each ( %{$href} )) {
            printf  "%*s%10s -> ",5,'',$k   if( $verbose );
            if ( defined $v ) {
                printf  "%s",$v             if( $verbose );
            } else {                                                            #   if ( defined $v );
                printf  "undefined"         if( $verbose );
                delete(${$href}{$k});                                           #   unless ( defined $v );
            }
            printf  "\n"                    if( $verbose );
        }# inspect all
        if( $verbose ) {
            printf  "%*s%s( %s ) done\n\n"
            ,5,'',$n, scalar(keys %{$href});                                    #   Show effectivness of pruning
        }
        return $href;
}#sub   prune_cline

#----------------------------------------------------------------------------
#   End of module Create/API.pm
1;
