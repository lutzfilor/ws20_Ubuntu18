#!/tools/sw/perl/bin/perl -w 
####!/usr/bin/perl -w
  
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   Post processing of coverage reports, for graphical representation
# 
 
 
#----------------------------------------------------------------------------
# I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;
use version; my $VERSION = version->declare('v1.02.09');                            # v-string using Perl API
 
use Switch;                                                                         # Installed 11/28/2018
 
use Carp                    qw  /   croak
                                    carp
                                    cluck
                                    confess     /;
 
#no warnings 'experimental::smartmatch';                                            # Turning of smartmatch
use feature 'state';                                                                # Static local variables
use feature 'switch';
 
use Readonly;
use Getopt::Long;
use File::Path              qw  /   make_path       /;                              # Create directories
use File::Basename;                                                                 # Handle absolute file names
use Cwd                     qw  /   abs_path
                                    getcwd
                                    cwd             /;                              # Current working directory
 
#use autodie;                                                                       # available
use Term::ANSIColor				qw  /   :constants          /;                      # available
#use Class::Std::Utils;     	                                                    # Not available
#use POSIX                   	qw  /   strftime            /;
use JSON                    	qw  /   decode_json         /;
use JSON::PP                	qw  /   decode_json         /;
use Data::Dumper				qw	/	Dumper				/;
 
#----------------------------------------------------------------------------
# U s e r   Perl - L i b r a r i e s
 
use lib							qw  ( ../lib  );                                    # Relative path to User Modules
 
use XLSX                    	qw  /   read_workbook       /;
use Dbg                     	qw  /   DebugControl
                            	        subroutine
                            	        debug       
                            	        ListModules
                                        DebugFeatures       /;                      # Allows you to select subs from CLI
                            	                                                    # by name individual, or all.
use UTF8                    	qw  /   read_utf8
                            	        read_utf8_slurp
                            	        read_utf8_string    /;                                                                                
use Find                    	qw  /   modules             /;                      # Find installation path for modules
 
use CLI::Interface          	qw  /   report_param        /;                      # Report on command line parameter
use Logging::Record         	qw  /   discard_logs        /; 

use PPCOV::Excel::XLSX			qw	/	deepcopy_workbook
										extract_array
										extract_hash
										add_worksheet
										insert_worksheet
										write_workbook
										revise_workbook		/;
use PPCOV::Archive::Index::HTML qw  /   read_html
									    process_instances
										get_references
										get_attribute
										get_accesspath		/;                      # Coverage Report index.html
use PPCOV::Archive::JSON::JSON	qw	/	get_record			/;						
use	PPCOV::Application::Prog	qw	/	validate_setup
										overwrite_setup		
										get_writebackpath	
										full_wbkpath		/;
										
use PPCOV::DataStructure::DS	qw  /   list_ref            /;                      # Data structure

use PPCOV::FileIO           	qw  /   file_exists
										filename_generator  
                            	        sheetname_generator /;						# To be deprecated
use PPCOV::Control          	qw  /   :ALL                /;                      # Read .xlsx Coverage_Spec deprecated
use PPCOV::DataPrep::Staging	qw	/   extraction          
										build_header
										build_cpit_header
										build_cpit_picker
										build_table			/;                      # DB datapath access

use TEST::Application::Prog     qw  /   testing             /;                      # Create Objects

 
sub report;
sub parse_header;
sub calculate_payload;
sub elaborate_tracefile;
sub CreateLoggingPath;
sub extract_coverage;
 
Readonly my $TRUE           =>     1;                                               # Create boolean like constant
Readonly my $FALSE          =>     0;
 
Readonly my $RIGHT          =>     1;                                               # Create alignment constant
Readonly my $LEFT           =>    -1;
 
printf "%5s%s = %s\n",'','IO buffering before', $|;
$|++;
printf "%5s%s = %s\n",'','IO buffering after ', $|;

my %defines;                                                                        # Command line defines

my %memorymap;                                                                      # Top Memory Map
my %testspecification;                                                              # Test specification derived from input
my @testsequence;                                                                   # Test sequence of instructions output
my $error_log       = 'error.log';                                                  # log    trace file reporting errors
 
my %opts    =   (   default_base        =>  'binary',                               # decimal 1000 vs binary 1024
                    progress_log        =>  'run.log',                              # log       default  command line log  !! Can't be turned off, aka run.log
                    application_log     =>  'app.log',                              # log       default  application logfile
                    error_log           =>  'error.log',                            # log       default  error logfile   
                    owner               =>  'Lutz Filor',                           # Author    Maintainer
                    call                =>  join (' ', @ARGV),                      # Capture   command line input 
                    program             =>  $0,                                     # Script    Name
                    version             =>  $VERSION,                               # Script    Version
                    log_path_default    =>  'logs',                                 # Default   logging path appendix for each trace
                    format              =>  {   self            =>  'format',       # EigenName Hash name is stored in self
                                                indent          =>  5,              # Default   indent left 5 char (pleasing to the eye)
                                                indent_pattern  =>  '',             # Default   indent pattern, leading whitespace
                                                dryrun          =>  0,              # Default   dryrun, not suppress subsequent execution
                                            },
                    subs                =>  [   qw  (   debug
                                                        DebugControl
                                                        check_command_line
														deepclone
														discard_logs
														_printf_scalar
														_printf_scalar2
                                                        testing
                                                        instruction
                                                        _create
                                                        makepaths
                                                    )                               # List of Subroutines for debugging
                                            ],
					setup				=>	{	initial =>	{},
												ovrwrit	=>	{},
												final	=>	{},
											},										# Hash of control flow
                    keywords            =>  [   qw  (   address
                                                        addressspace
                                                        addresssize
                                                        baseaddress
                                                        block_range
                                                        databussize
                                                        wordaligned
                                                        blk_boundry
                                                        offset
                                                        reserved
                                                        mask
                                                    )
                                            ],                                      # List of implemented keywords
                    instructions        =>  [   qw  (   READ
                                                        WAIT
                                                        WRITE
                                                        WRCMP
                                                        RSRVD
                                                        PRINT
                                                        POLL
                                                        SET_INTERVAL
                                                        SET_TIMEOUT
                                                        SET_MASTER
                                                        SET_BASE
                                                    )                               # List of implemented SV instructions --lint
                                            ],
                    default_decimal     =>  [   qw  (   databussize
                                                        addresssize
                                                        block_range
                                                        blk_boundary
                                                    )
                                            ],                                      # default decimal values
                    default_hexadecimal =>  [   qw  (   address
                                                        addressspace
                                                        baseaddress
                                                        offset
                                                        reserved
                                                        address
                                                        mask
                                                    )
                                            ],                                      # default hexadecimal values
                    default_binary      =>  [],
                    tmp                 =>  [],                                     # parsing xlsx doc
                    tmp2                =>  [],                                     # parsing XML files
                    tmp3                =>  [],                                     # parsing XML string
                    tmp4                =>  [],                                     # parsing XML element
                    tmp5                =>  [],                                     # experimental
 
                    units_of_data_size  =>  [   qw  (   bit byte    )   ],          # Default unit of data size
                    legal_data_prefixes =>  [   qw  (   k M G T P E Z Y )   ],      # Legal   prefixes for units of data
                    indent              =>  5,                                      # Default indentation
                    preamble            =>  ' ... ',                                # Default preamble
                    indent_pattern      =>  '',                                     # Default indent pattern Whitespace
                    memorymap           =>  \%memorymap,                            # Hierachical map of memory specification
                    testspecification   =>  \%testspecification,                    # Unordered list of specifications
                    testsequence        =>  \@testsequence,                         # Ordered list of test sequence instructions
                ); 
 
#################################################################################################################################
#
# main entry
#
#=================================================================================================================================
my      ($s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst) = localtime;
my      $runlog =  $opts{log_path_default}.'/'.$opts{progress_log}; 
open    (my $proh, ">$runlog") ||  die " Cannot create log $runlog";                # Open Progress log file
printf  $proh " %s %s\n\n",$opts{program}, $opts{call};

GetOptions  (   'input|in=s'            =>  \$opts{pseudo_seq},                     # Source    w/ read,write transaction definition
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

                'defines=s'             =>  \%defines,
                'format=s'              =>  \%{$opts{format}},                      # Input     Command line overwrite of formats
                'output|o=s'            =>  \$opts{log},                            # Logfile   rename compile logfile
                'help|h|?:s'            =>  \$opts{help},                           # Usage     Information
                'man|m'                 =>  \&help2,                                # Manual    Information

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
                'cell=s{2}'             =>  \$opts{cell},                           #           Select cell
				'date=s'				=>	\$opts{date},							#			Select worksheet/filename 'YYYY-MM-DD'
                'target=s'              =>  \$opts{output},                         # Output    .xlsx file overwrite filename


                'create=s'              =>  \$opts{create},                         # Input     object string
                'coverage|cover=s'      =>  \$opts{coverage},                       # Input     .html file "legacy.html"
            );                                                                      # Command Line Processor

printf STDERR "\n";                                                                 # Spacer to command line
DebugFeatures        (   \%opts      );                                              # Disabled for silencing terminal
DebugControl        (   \%opts      );                                              # Tuning debugging
debug               (   '','debug'  ) if debug('debug');                            # debug(subr=name,phase=set/debug/probe
check_command_line  (   \%opts      ) if debug('check_command_line');               # Break the chicken and egg problem
$opts{log}           //= $opts{log_path_default}.'/'.$opts{application_log};
$opts{specification} //= 'testsequence.ini';                                        # May be changed to initialization
$opts{test_sequence} //= 'basic_sequence.seq';

open (my $cmph, ">", $opts{log} )   ||  die " Cannot create log $opts{log}";        # Open Compile  log file
printf $cmph "Input %s\n\n", $opts{specification};
printf $cmph "Line# Specification input                           WARNING description\n";
$opts{compile_fh}   =   $cmph;

if  (      defined $opts{flush}) { 
    flush_test_sequence (   \%opts                                                  # Input     Command line Options
                        ,   \%defines                                               # Input     Command line Defines
                        ,   \%memorymap                                             # Output    MemoryMap define boundaries, specifics
                        ,   \%testspecification  );                                 # Output    Test Sequence Specification
} 
elsif (  defined $opts{workbook} ) {
    
}
elsif (  defined $opts{list} )  {
    #list_wrapper        (   \%opts  );                                              # list      modules
}
elsif (  defined $opts{find} )  {
    find_wrapper        (   \%opts  );
}
elsif (  defined $opts{lint} )  { 
    lint_test_sequence  (   \%opts  );                                              # Lint      Remove comment lines, enforce homogenity, increase robustness
}
elsif (  defined $opts{seek} )  { 
    seek_file_pattern   (   \%opts  );
}
elsif (  defined $opts{open} )  { 
    open_binary_files   (   );                                                      # Experimental code
}
elsif (  defined $opts{map}  )  { 
    map_subdirectory    (   );                                                      #           Extract subdirectory structures
}
elsif (  defined $opts{maps} )  { 
    map_subroutines     (   );                                                      #           Extract subroutine implementations
}
elsif (  defined $opts{help} )  { 
    online_help         (   \%opts  );                                              # Online    help
}
elsif (  defined $opts{test} )  {
    switch ( $opts{test} ) {
        case m/\bxmle\b/        {   test_xmle();                        }
        case m/\bjson\b/        {   test_json( \%opts );                }           # Experimental
        else                    {   not_supported($opts{test},'test');  }
    }#switch
}
elsif ( defined $opts{create} ) {
    testing (   \%opts  );
}
else                            { 
    user_help();                                                                    # User      help
}
exit 0; # Main Exit
#=================================================================================================================================
# End of main()
#
# Subroutine implementation
#
#=================================================================================================================================

sub     find_wrapper  {
        my  (   $opts_ref   )   =   @_;
        my $i = ${$opts_ref}{indent};                                               # indentation
        my $p = ${$opts_ref}{indent_pattern};                                       # indentation pattern
        my $n = subroutine('name');                                                 # name of subroutine
        printf "%*s%s()\n\n", $i,$p,$n;
        if  ( defined ${$opts_ref}{modules} )   {                                   # reference to anonymous array
            printf  "%*s%s\n",$i,$p,'Searching for installed modules';
        } 
        else  {
            printf  "%*s%s\n",$i,$p,'No search term implemented';
        }
}#sub   find_wrapper


sub   online_help{
      my    (   $opts_ref       )   = @_;                                                                   # Input     Reference to %opts

      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # Leading Whitespace

      printf "\n";
      printf " ... SYNOPSYS :: Post Process Coverage Report Generator %s\n",${$opts_ref}{program};
      printf "\n";
      printf "     USAGE    :: %s %s\n",${$opts_ref}{program}
                                       ,${$opts_ref}{version};
      printf "\n";
      printf "%*s%s --workbook=<FILE>.xlsx\n",17,$p,${$opts_ref}{program};
      printf "\n";
      printf "%*s%s\n" ,$i,$p,'OPTIONS  ::';
      printf "%*s%s\n" ,25,$p,'worksheet    =   <NAME>  default setting sheet1';
      printf "%*s%s\n" ,25,$p,'column       =      <A>  default setting A';
      printf "%*s%s\n" ,25,$p,'row          =      <1>  default setting 1';
      printf "%*s%s\n" ,25,$p,'debug        =   <sub1,sub2,sub3 .. >';

      printf "%*s --wb=<FILE>.xlsx --ws=\n",25,$p;
      printf "\n";
      printf "\n";
      printf "     Debugging ::\n";
      printf "\n";
      printf "     <%s>  --workbook=<FILE> | & tee ./log.out\n",${$opts_ref}{program};
      printf "                 --help=debug\n";
      printf "                 --debug=<SUB>   make any subroutine observable\n";
      printf "\n";
      printf "\n";
      printf "                    Debugging debugging features :: \n";
      printf "                  --dbg0          make debug features observable high level\n";
      printf "                  --dbg1          make debug features observable low  level\n";
      printf "\n";
      printf "\n";
      printf "     Author    %s\n",${$opts_ref}{owner};
      printf "     Synpatics Confidential Tool, IoT-Group                   Copyright, San Jose 2019\n";
      printf "\n";
      exit(0);
}#sub help


sub   user_help {
      printf "\n";
      printf " ... USAGE    :: %s %s\n",$opts{program}
                                       ,$opts{version};
      printf "     Type     :: %s --help for more information\n",$opts{program};
      printf "\n";
}#sub user_help


sub   file_type {
      my    (   $file_name  )   = @_;
      return    ( -T $file_name )? 'text   '
            :   ( -B $file_name )? 'binary ' : 'unknown';
}#sub file_type

# End of program test.pl
