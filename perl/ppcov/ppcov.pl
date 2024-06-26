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
#use File::Find::Rule;                                                              # Not available
use Cwd                     qw  /   abs_path
                                    getcwd
                                    cwd             /;                              # Current working directory
 
#use Padwalker;                                                                     # Not available/installed
#use Log::Log4perl   qw  (:easy);                                                   # Not avaiable
 
#use autodie;                                                                       # available
use Excel::Writer::XLSX;                                                            # available         Spreadsheet::WriteExcel
#use Spreadsheet::ParseExcel;                                                       # available .xls
use Spreadsheet::ParseXLSX;                                                         # available .xlsx
#use Spreadsheet::WriteExcel;                                                       # available .xls
use Spreadsheet::XLSX;                                                              # reading   .xlsx
#use Spreadsheet::Read;                                                             # Not available
#use Package::Stash;                                                                # available
#use Pod::Usage;                                                                    # available
#use DateTime;                                                                      # Not used
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
                            	        ListModules         /;                      # Allows you to select subs from CLI
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
 
Readonly my $BOUNDARY_1K    =>  1024;                                               # 1K byte boundary
Readonly my $BOUNDARY_4K    =>  4096;                                               # 4K byte boundary
Readonly my $KBYTE          =>  1024;                                               # 1k byte
Readonly my $MBYTE          =>  1024 * $KBYTE;                                      # 1M byte
Readonly my $GBYTE          =>  1024 * $MBYTE;                                      # 1G byte
Readonly my $LARBOUNDARY    =>     0 * $GBYTE;                                      #    0x0000_0000
Readonly my $UARBOUNDARY    =>     4 * $GBYTE;                                      # 4G byte physical address boundary
 
Readonly my $WORDSIZE       =>     4;                                               #  4 byte   or 32 bit
Readonly my $CACHELINE      =>    64;                                               # 64 byte cacheline size
 
Readonly my $SIGN           =>      qr  { [+-] }xms;
Readonly my $DIGITS         =>      qr  { \d+ (?: [.] \d*)? | [.] \d+ }xms;
Readonly my $EXPO           =>      qr  { [eE] $SIGN? \d+ }xms;
 
Readonly my $KEYWORD        =>      qr  { \b\w+\b }xms;
Readonly my $PREAMBLE       =>      qr  {  0?x?   }xi;                              # Hexpreamble
Readonly my $NIBBLE         =>      qr  { [0-9A-F_] }xmsi;
Readonly my $COMMENT        =>      qr  { [#].* }xmsi;                              # Trailing comment, End of line comment
 
Readonly my $SYSTEM         =>      qr  { SI|JEDEC|ICE }xms;                        # Normative Organizations
Readonly my $BINARY         =>      qr  { Ki|Mi|Gi|Ti|Pi|Ei|Zi|Yi }xms;             # Binary prefix
Readonly my $UNITS          =>      qr  { bit|byte|s|Hz|m|g }xms;                   # SI base units F|C|K temperature
Readonly my $PREFIX         =>      qr  { Y|Z|E|P|T|G|M|k|K|m|u|n|p|f|a|y|z }xms;   # SI prefix 10^18 to 10^-18 range NOTE :: micro is substitute w/ [u] for muy
#Readonly my $PREFIX        =>      qr  { [YZEPTGMkKmunpfayz] }xms;                 # SI prefix 10^18 to 10^-18 range NOTE :: micro is substitute w/ [u] for muy
Readonly my $FLOAT          =>      qr  { ($SIGN?) ($DIGITS) ($EXPO?) }xms;         # Because I looked a day for an error of k vs K, uppercase K is included for robustness
Readonly my $DATAWORD       =>      qr  { $PREAMBLE?$NIBBLE+ }xms;                  # Hexdata & Numbers
Readonly my $MEASURE        =>      qr  { $PREFIX?$UNITS }xms;
 
# For simple, not nested XML strings
# and not for packed XML strings - no TAG analysis for nested XML elements
 
#Readonly my $TAG_OPEN       =>      qr  { [<]|[<][/]|[<][?] };                     # Generalization not all permutations are valid XOR
Readonly my $TAG_OPEN       =>      qr  { <([/]|[?])?  };                           # Generalization not all permutations are valid XOR
Readonly my $TAG_NAME       =>      qr  { \B\w+   };                                # A welformed XML tag is [<]\D\w+, to capture them all errors are permissable in parsing
Readonly my $TAG_CLOSE      =>      qr  { [>]|[/][>]|[?][>] };                      # Generalization not all permutations are valid XOR
Readonly my $ANAME          =>      qr  { \b\w+  };
Readonly my $AVALUE         =>      qr  { ['].*[']|["].*["]  }xms;                  # single or double quoted string
Readonly my $XML_ATTRIBUTE  =>      qr  { $ANAME\B[=]\B$AVALUE  }xms;               # N0 space in XML Attribute specification
Readonly my $XML_CONTENT    =>      qr  { [^><]+    }xms;                           # Any character Inside opening and closing XML TAG
 
Readonly my $XML_STARTTAG   =>      qr  { $TAG_OPEN                                 # [<]
                                          $TAG_NAME\s+
                                          $XML_ATTRIBUTE*\s*                        # Optional XML attribute, or multiples, NO withspace between last attribute and closing tag
                                          $TAG_CLOSE            }xms;               # [/][>] self closing
 
Readonly my $XML_ENDTAG     =>      qr  { $TAG_OPEN                                 # [<]   [<][/]   [<][?]
                                          $TAG_NAME
                                          $TAG_CLOSE    }xms;                       # [>]   [/][>]   [?][>]
 
 
#Readonly my $XML_ELEMENT    =>      qr  {   ($XML_STARTTAG)?                        # Closing TAG for nested XML elements
#                                            ($XML_CONTENT)?                         # XML elements could be empty
#                                            ($XML_ENDTAG)?      }xms;               # XML self closing element
#==== new xml
 
#eadonly my $TAGN           =>      qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]+ }xms;        # XML Tag name
Readonly my $TAGN           =>      qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]* }xms;        # XML Tag name
 
#eadonly my $XMLAN          =>      qr  {   \b\w+                   }xms;           # XML Attribute name
Readonly my $XMLAN          =>      qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]* }xms;        # XML Attribute name
 
#Readonly my $XMLAV         =>      qr  {   ['].*[']|["].*["]       }xms;           # XML Attribute value single or double quoted string
#Readonly my $XMLAV         =>      qr  {   ['][^']*[']|["][^"]*["] }xms;           # XML Attribute value single or double quoted string
Readonly my $XMLAV          =>      qr  { (?|['][^']*['] | ["][^"]*["]) }xms;       # XML Attribute value single or double quoted string
Readonly my $XMLA           =>      qr  {   \s+ $XMLAN [=] $XMLAV   }xms;           # XML Attribute
 
Readonly my $XML_ELEMENT    =>      qr  {   [^><]+                  }xms;           # Any character Inside opening and closing XML TAG
 
Readonly my $XMLE           =>      qr  {   [<]\B$TAGN\b                            # XML opening tag
                                            ($XMLA*)\s*[>]                          # w/ optional XML attribute
                                            $XML_ELEMENT                            # XML element data
                                            [<][/]$TAGN [>]         }xms;           # XML closing tag matching
Readonly my $XML_NEO        =>      qr  {   [<]($TAGN\b)                            # XML nested element opening tag
                                            ($XMLA*)[>]             }xms;           # w/ optional XML attribute
 
#Readonly my $XML_NEO        =>      qr  {   [<]($TAGN\b)                            # XML nested element opening tag
#                                            (.*)[>]                 }xms;           # w/ optional XML attribute
 
 
#Readonly my $XML_NEC       =>      qr  {   [<][/](.*)[>]           }xms;           # XML nested element closing tag
Readonly my $XML_NEC        =>      qr  {   [<][/]$TAGN[>]          }xms;           # XML nested element closing tag
Readonly my $XMLE_ST        =>      qr  {   [<]$TAGN\s+.*[/][>]$    }xms;           # XML self terminating elememt
#Readonly my $XMLE_ST       =>      qr  {   [<]($TAGN)\s+           }xms;           # XML self terminating elememt
#                                           $XMLA*[/][>]            }xms;           # w/ optinal XML tag but - without closing tag
#                                           $XMLA*\s*[/][>]         }xms;           # w/ optinal XML tag but - without closing tag
Readonly my $XML_PRO        =>      qr  {   [<][?](.*)[?][>]        }xms;           # XML Prolog
Readonly my $XML_COM        =>      qr  {   [<][!][-][-]
                                            (.*)[-][-][>]           }xms;
 
printf "%5s%s = %s\n",'','IO buffering before', $|;
$|++;
printf "%5s%s = %s\n",'','IO buffering after ', $|;

my %defines;                                                                        # Command line defines
#my @keyword = qw(   addresssize baseaddress block_range databussize );             # Recognized keywords
my %memorymap;                                                                      # Top Memory Map
my %testspecification;                                                              # Test specification derived from input
my @testsequence;                                                                   # Test sequence of instructions output
my $error_log       = 'error.log';                                                  # log    trace file reporting errors
 
my %opts    =   (   default_base        =>  'binary',                               # decimal 1000 vs binary 1024
                    progress_log        =>  'run.log',                              # log       progress phases of program              !! Can't be turned off, aka run.log
                    default_compile_log =>  'tsg.log',                              # default   Compile logfile
                    owner               =>  'Lutz Filor',                           # Author    Maintainer
                    call                =>  join (' ', @ARGV),                      # Capture   command line input 
                    program             =>  $0,                                     # Script    Name
                    version             =>  $VERSION,                               # Script    Version
                    log_path_default    =>  'logs',                                 # Default   logging path appendix for each trace
                    subs                =>  [   qw  (   debug
                                                        DebugControl
                                                        check_command_line
                                                        flush_test_sequence
                                                        parse_init
                                                        observe_extraction
                                                        valid_init
                                                        store_init
                                                        compile_sequence
                                                        scan_sequence
                                                        writing_sequence
                                                        comment_line
                                                        convert_baseaddress
                                                        convert_blockrange
                                                        convert_databussize
                                                        convert_reserve
                                                        is_subset
                                                        map_subdirectory
                                                        map_subroutines
                                                        write_array_to_file
                                                        initialize
                                                        new
                                                        extract_array
														extract_hash 
                                                        process_instances
                                                        get_references
                                                        get_subsection
                                                        get_attribute
                                                        get_accesspath
                                                        get_zrecord
                                                        get_section
                                                        get_headers
                                                        get_objlst
                                                        get_record
                                                        get_values
                                                        get_zdata
                                                        get_vpair
                                                        grep_data
														build_table
														build_aoi_table
														insert_worksheet
														get_list
                                                        get_span
                                                        test_json
                                                        list_ref
                                                        get_uri
                                                        merge_data
														extraction
														write_workbook
														revise_workbook
														deepclone
														discard_logs
														validate_setup
														overwrite_setup
														_printf_scalar
														_printf_scalar2
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
                );# %opts
 
#################################################################################################################################
#
# main entry
#
#=================================================================================================================================
my      ($s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst) = localtime;
open    (my $proh, ">$opts{progress_log}") ||  die " Cannot create log $opts{progress_log}";   # Open Progress log file
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

                'coverage|cover=s'      =>  \$opts{coverage},                       # Input     .html file "legacy.html"                          
            );                                                                      # Command Line Processor                              

printf STDERR "\n";                                                                 # Spacer to command line
#DebugFeatures      (   \%opts      );                                              # Disabled for silencing terminal
DebugControl        (   \%opts      );                                              # Tuning debuggi
debug               (   '','debug'  ) if debug('debug');                            # debug(subr=name,phase=set/debug/probe
check_command_line  (   \%opts      ) if debug('check_command_line');               # Break the chicken and egg problem
$opts{log}           //= $opts{default_compile_log};
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

	discard_logs    ( $opts{silent},												# turn off reporting
					  qw (  logs/log_zrecords
                            logs/log_instances
                            logs/log_loctable
                            logs/log_rectable
                            logs/log_loc_data
                            logs/log_rec_data
                            logs/log_spans
                            logs/log_loc_info
                            logs/log_rec_info
                            logs/log_headers
                            logs/log_hits
							logs/log_instinfo	)   );

    $opts{ws}{setup}{name}	//= 'Setup';                                            # Worksheet Setup tab
    $opts{ws}{cspec}{name}	//= 'Coverage_Spec';									# Worksheet Specification tab
    $opts{ws}{cspec}{ch1}	//= 'Block/Area of Validation';							# columnhead1
    $opts{ws}{cspec}{ch2}	//= 'Coverage Hierarchy/Instance';						# columnhead2

    $opts{message}  =  'Excel input file ::'; 
    report_param    ( \%opts, qw (message workbook) );                              # Input parameter

	file_exists		( $opts{workbook} );											# Guard against typos et all 
	
    #list( \@INC );                                                                 # Library include path
    my  $parser     =   Spreadsheet::ParseXLSX->new();
    my  $workbook   =   $parser->parse( $opts{workbook} );                          # from      file
    my  $bookcopy   =   deepcopy_workbook  ( $workbook, \%opts );

    my  $sheetname  =   $opts{ws}{cspec}{name};                                     # Select worksheet tab "Coverage_Spec"
    my  $col1       =   $opts{ws}{cspec}{ch1};										# columnhead1
    my  $col2       =   $opts{ws}{cspec}{ch2};										# columnhead2
    my  $tgt_blk_r  =   extract_array	( $bookcopy,$sheetname,$col1 );				# PPCOV::Excel::XLSX
    my  $tgt_inst_r =   extract_array	( $bookcopy,$sheetname,$col2 );				# PPCOV::Excel::XLSX
    my  $instances  =   process_instances ( $tgt_blk_r, $tgt_inst_r  );				# PPCOV::Datapath

	$opts{blocks}	=	$tgt_blk_r;													# preservation redundant
	$opts{inst_raw} =	$tgt_inst_r;											    # preservation redundant
	$opts{instances}=	$instances;
	
    my  $worksheet  =   $opts{ws}{setup}{name};										# Select Worksheet tab "Setup"
    my	$setup 		=	extract_hash( $bookcopy,$worksheet, 0, 1,\%opts );          # PPCOV::Excel::XLSX
    
	validate_setup	(	$setup 		);												# PPCOV::Application::Prog
    $opts{setup}	=	$setup;	

	overwrite_setup (	$setup		);												# PPCOV::Application::Prog
    #list_ref ( \%opts, { name => 'AppOptions',} );
	
    my  $html       =   read_html   (   \%opts   );                                 # PPCOV::Archive::Index::HTML

    my  $references =   get_references  ( $instances, $html );                      # PPCOV::Archive::JSON::JSON fix me
	#list_ref ( $references, { name => 'refernces',} );
    my  $attributes =   get_attribute   ( $references );                            # PPCOV::Archive::JSON::JSON fix me
    #list_ref ( $attributes, { name => 'attributes',} );
	
    my  $absolute_p =   $opts{setup}{final}{path};                                  # path_to_coverage
    #printf "%*s%s = %s\n",5,'','Path to the Zarchive',$absolute_p;
    my  $access_path=   get_accesspath  ( $attributes                               # z###.json, zRecord
                                        , $absolute_p );                            # PPCOV::Datapath
    #list_ref ( $access_path, { name => 'access_path',} );

    my  $zrecords   =   get_record      ( $access_path,'TOTAL');                    # PPCOV::Archive::JSON::JSON
    list_ref ( $zrecords, { name => 'zRecords',}     );
    #list_ref ( $bookcopy, { name => 'bookcopy',}    );


	my $scopes		=	[	qw	( Scope	TOTAL	)	];								# PPCOV::DataPrep::Staging
	my $raw_data	=	extraction	(	$zrecords									# { $instance x table x cells }
									,	$scopes		);								# PPCOV::DataPrep::Staging
	list_ref ($raw_data, { name => 'raw_data extracted',}	);
	
    #my $row_picker	=	build_picker(	$row_definition );							# PPCOV::DataPrep::Staging
	#list_ref ( $row_picker, { name => 'row_picker'	);

	my $cpit_header	=	build_cpit_header();
	my $cpit_picker	=	build_cpit_picker();
    list_ref ($cpit_header, { name	 => 'CPI header',
			                  reform => 'ON'}		);

	my $cpi_table	=	build_table	(	$raw_data
									,	$cpit_header								# column header for CPIT
									,	$cpit_picker	);							# coverage_progress_indicator_table
									
	list_ref ( $cpi_table, { name	=> 'CPI table',
							 reform	=> 'ON',		}	);

    printf "\n\n";

	### my $aoi_tab	= build_aoi_table	(	$tgt_blk_r
	### 								,	$tgt_inst_r
	### 								,	$raw_data	);

    my $rev_book =  insert_worksheet(	$bookcopy
									,   $cpi_table
									,   \%opts    );

	#list_ref ( $rev_book, { name	=> 'CPI table',
	#   					 reform	=> 'ON',		}	);
	
	list_ref ( $rev_book, { name	=> 'Revised Book',
							reform	=> 'ON'			}	);
	
	my $rev_name =  filename_generator(   \%opts    );
	my $wbk_name = full_wbkpath( $setup, $rev_name );
	printf	"%*s%s : %s\n",5,'','FULL name',$wbk_name;

	write_workbook	(	$rev_book
					,	$wbk_name 
					,	\%opts		);

    #my $msg = sprintf ("%*s%s\n\n",5,'',"WARNING hard stop in $0 for debugging");
    #print BLINK BOLD BLUE $msg, RESET;
	#exit;
					
	revise_workbook	(	$opts{workbook}
					,	$rev_book													# revised workbook,
					,	\%opts		);
	
	#list_ref ( $rev_book, *rev_book );
    ### #my  $zrecord    =   get_record      ( $access );                           # PPCOV::Datapath
    ### #list ( $zrecord ,   'zRecord'   );
    ### #my  $scope      =   'TOTAL';
    ### #my  $zdata      =   get_zdata       ( $scope, $zrecord );
    ### #list_ref ( $zdata   ,  { name => 'zdata',} );
    ### #printf  "%5s%s\n", '', $record;
    ### #my  $file       =   ${$access}[0][0];
    ### #printf  "%5s%s%s\n",'','Filename ',$file;
    ### iterate_worksheets( $workbook   );                                              # extract   data
    ### #list( \@INC );
}
elsif (  defined $opts{list} )  {
    list_wrapper        (   \%opts  );                                              # list      modules
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


sub   iterate_worksheets    {
      my    (   $book_r                                                             # Spreadsheet::ParseXLSX->new();
            ,   $opts_ref   )   =   @_;
                $opts_ref   //= \%opts;

      my $book  =   [];                                                             # deep copy for terminal rendering
      my $book_c=   [];                                                             # deep copy of shreadsheet
                
      printf "%5s%s %s\n", '','Document   :', $book_r->get_filename();
      printf "%5s%s %s\n", '','#worksheet :', $book_r->worksheet_count();

      #             readout_worksheet   ( $book_r );                                # study case
      $book_c   =   deepcopy_workbook   ( $book_r,$opts_ref );                      # deep copy of worksheet
      $book     =   extract_for_display ( $book_r );                                # 2D terminal data display

      #post_workbook     (   $book   );                                             # terminal  output
      filename_generator( $opts_ref );                                              # target    output filename
      #insert_worksheet  (   $book_c,
      #                  ,   $sheet_ref                                             #
      #                  ,   $opts_ref );
      copy_workbook     (   $book_c );                                              # file      output
}#sub iterate_worksheets


sub     extract_for_display {                                                       # unformated readout of workbook data
        my  (   $book_r     )   =   @_;
        my $book  =   [];                                                           # deep copy for terminal rendering
        for my $sheet ( $book_r->worksheets()  ) {
              printf "%5s%s %s\n"     , '','#worksheet :', $sheet->get_name();
              my ( $row_min, $row_max ) = $sheet->row_range();
              my ( $col_min, $col_max ) = $sheet->col_range();
              
              my $blatt   = [];                                                     # sheet data
              my $tab     = [];                                                     # tab name
              my $format  = [];                                                     # column width calculation
              for my $col ( $col_min .. $col_max ) {
                  my @spalte;
                  my $width = 0;
                  for my $row ( $row_min .. $row_max ) {
                      my $cell_i = $sheet->get_cell ( $row, $col );                 # cell information
                      my $cell_v;
                      if ( $cell_i ) {
                          $cell_v = $cell_i->value();                               # cell value
                          my $tmp    = length ( $cell_v );
                          $width = ( $width > $tmp )? $width : $tmp;                # determine max width
                      } else {
                          $cell_v = '';
                      }
                      push (@spalte, $cell_v);
                  }#for all rows
                  push (@{$blatt}, [ @spalte ]);
                  push (@{$format}, $width);
              }#for all columns
              push (@{$tab}, $sheet->get_name());
              push (@{$tab}, $blatt);
              push (@{$tab}, $format);
              push (@{$book},$tab);
        }#for all sheets
        return $book;                                                               # reference to arrary of array
}#sub   extract_for_display


sub     post_workbook {
        my    (   $book_r
              ,   $opts_ref   )   =   @_;
                  $opts_ref   //= \%opts;
        my $i = ${$opts_ref}{indent};                                               # left side indentation
        my $p = ${$opts_ref}{indent_pattern};                                       # indentation_pattern
        my $n =  subroutine('name');                                                # identify the subroutine by name
        printf STDERR "%*s%s()\n\n", $i,$p,$n;
        if ( ref($book_r) =~ m/ARRAY/ ) {
           printf STDERR "%*s %s %s %s\n",$i,$p,$n,'parameter is',ref $book_r;
           foreach my $t ( @{$book_r} ) {
              printf STDERR "\n";
              printf STDERR "%*s %s %s\n"    ,$i,$p,'tab name', $t->[0];
              my  $b_ref = $t->[1];                                                 # reference to blatt
              my  $w_ref = $t->[2];                                                 # reference to format
              my  @colum = @{$b_ref};
              my  $n_row = scalar @{$colum[0]};                                     # number of columns
              my  $n_col = $#{$w_ref};
              printf STDERR "%*s %s %s\n",$i,$p,'number of col', $n_col;
              printf STDERR "%*s %s %s\n",$i,$p,'number of row', $n_row;
              for my $row   ( 0 .. $n_row-1 ) {
                  printf  STDERR "%*s|",$i,$p;
                  for my $index ( 0 .. $n_col-1 ) {
                        printf STDERR "%*s ",${$w_ref}[$index],$colum[$index][$row];
                  }#for
                  printf STDERR "|\n";
              }#for
           }# tabs
        }#if NO GUARD - TYPE is ARRAY
}#sub   post_workbook


#sub     insert_worksheet    {
#        my  (   $book_r                                                             #
#            ,   $cov_r
#            ,   $opts_ref   )   =   @_;
#        my $i = ${$opts_ref}{indent};                                               # left side indentation
#        my $p = ${$opts_ref}{indent_pattern};                                       # indentation_pattern
#        my $n =  subroutine('name');												# identify sub by name
#        if ( ref($book_r) =~ m/ARRAY/ ) {
#            my $worksheet_name = sheetname_generator();
#            printf  "%*s%s %s\n",$i,$p,'Sheetname',$sheet;
#            #my $data = format_data ( $cov_r, $opts_ref );
#        } else {
#            my $msg 
#            = sprintf ("\n%*s%s\n",5,''
#                ,"WARNING $n() not ARRAY reference");
#            print BLINK BOLD RED $msg, RESET;
#        }
#}#sub   insert_worksheet


sub     format_data {
        my  (   $cov_r  
            ,   $opts_ref   )   =   @_;
        my $i = ${$opts_ref}{indent};                                               # left side indentation
        my $p = ${$opts_ref}{indent_pattern};                                       # indentation_pattern
        my $n =  subroutine('name');												# identify sub by name
        printf  "\n%5s%s() \n",'',$n;# if( debug($n));
        if ( (ref $cov_r) =~ m/HASH/ )  {
            my $w   =   maxwidth([keys %{$cov_r}]);
            foreach my $instance ( keys %{$cov_r} ) {								# instance & attribute are correlate
                my $data = ${$cov_r}{$instance}{raw}{TOTAL};
                printf "%*s%*s = %s\n",$i,$p,$w,$instance,$data;
            }#for all instances
        } else {
            my $msg = sprintf ("%*s%s\n\n",5,'',"WARNING $n() NO Hash reference");
            print BLINK BOLD RED $msg, RESET;
        }# Warning       
}#sub   format_data


sub     copy_workbook   {
        my  (   $book_r
            ,   $opts_ref   )   =   @_;
                $opts_ref   //= \%opts;
        my  $i = ${$opts_ref}{indent};                                              # left side indentation
        my  $p = ${$opts_ref}{indent_pattern};                                      # indentation_pattern
        my  $output     = ${$opts_ref}{output};                                     # target output file.xlsx
        my  $workbook   = Excel::Writer::XLSX->new( $output );                      # Step 1
        $workbook->set_properties(
               title    => 'IoT - Testcoverage Report',
               author   => 'Lutz Filor',
               manager  => 'Ravi Kalyanaraman',
               company  => 'Synaptics',
               comments => 'Created w/ Perl lib Excel::Writer::XLSX',
        );
        
        if ( ref($book_r) =~ m/ARRAY/ ) {
            foreach my $t ( @{$book_r} ) {
                printf STDERR "%*s %s %s\n"    ,$i,$p,'tab name', $t->[0];
                my $worksheet = $workbook->add_worksheet($t->[0]);
                $worksheet->write_col(0,0,$t->[1]);
            }# for each table worksheet
        }#if NO GUARD - TYPE is ARRAY
}#sub   copy_workbook


sub   list  {
      my    (   $a_ref                                                              # list reference
            ,   $msg                                                                # message
            ,   $opts_ref   )   =   @_;
                $opts_ref   //= \%opts;                                             # default definition
      my $s = length($#{$a_ref});                                                   # format counter 
      my $i = ${$opts_ref}{indent};                                                 # left side indentation
      my $p = ${$opts_ref}{indent_pattern};                                         # indentation_pattern
      my $n =  subroutine('name');                                                  # identify the subroutine by name
      printf "\n";
      printf "%*s%s::\n",$i,$p,$msg if ( defined $msg );
      while (my ($c, $e) = each @{$a_ref}) {                                        # $e entries
        chomp $e;                                                                   # remove new line character
        printf "%*s(%*s) %s\n",$i,$p,$s,$c+1,$e;                                    # if( debug($n) )
      }#while
}#sub list


sub   test_coverage   {
      my    (   $opts_ref   )   =   @_;
      $opts_ref //= \%opts;                                                         # default definition
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $f = ${$opts_ref}{workbook};
      my $n = subroutine('name');
      printf "%*s%s %s is %s\n\n", $i,$p,'workbook', $f, file_type($f);
      my $lm = sprintf "%*s%s %s", $i,$p,'file name', $f;                           # message
      push ( @{${$opts_ref}{tmp}} , $lm);                                           # capture message      system "unzip -oq  $f -d XML";
      my @ff = `find ./XML -type f`;
      my @dd = `find ./XML -mindepth 1 -type d `;
      ${$opts_ref}{cnt} = 0;
      foreach my $fn ( @ff ) {
         chomp($fn);
         printf "%*s%s is %s\n", $i,$p,$fn,file_type($fn);                          # list file name
         $lm = sprintf "%*s%s is %s" , $i,$p,$fn,file_type($fn);                    # file name
         push ( @{${$opts_ref}{tmp}} , $lm);                                        # capture message
         ${$opts_ref}{cnt} ++;                                                      # loop counter
         read_xml_file ( $fn) if $fn =~ m/.xml$/xms;                                # (?|.xml|.rels)$
         #read_rels_file( $fn) if $fn =~ m/.rels$/xms;
      }# list all files
      printf "\n";# if( debug($n));
      write_array_to_file(${$opts_ref}{tmp} ,'logs/parse_xlsx.log');
      write_array_to_file(${$opts_ref}{tmp2},'logs/parse_xmlf.log');
      write_array_to_file(${$opts_ref}{tmp3},'logs/parse_xmls.log');
      write_array_to_file(${$opts_ref}{tmp4},'logs/parse_xmle.log');
}#sub test_coverage


sub   not_supported {
      my    (   $key                                                                # mandatory setting
            ,   $target                                                             # mandatory setting
            ,   $opts_ref   )   =   @_;
                $opts_ref       //= \%opts;                                         # default setting
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      printf "%*s%s is not supported by %s\n\n", $i,$p,$key,$target;
      my $n = subroutine('name');                                                   # name of subroutine

}#sub not_supported


sub   test_xmle {
      my    (   $opts_ref   )   =   @_;
                $opts_ref       //= \%opts;                                         # default setting
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');                                                   # name of subroutine
      my $m;                                                                        # message
      my $t;                                                                        # text
      my $f = "%*s%s :: %s";                                                        # format
      ${$opts_ref}{file} //= 'xmles_long.xml';
      printf "%*s%s()\n\n", $i,$p,$n;
      printf "%*s%s :: %s\n", $i,$p,'input',${$opts_ref}{file};
      my @xmle = read_utf8( ${$opts_ref}{file} );
      printf "%*s%s elements\n",$i,$p,$#xmle+1;
      foreach my $e (@xmle) {
          chomp $e;
          switch ( $e ) {
              case  m{  $XML_PRO  }xms { $t = 'XML Prolog'; }
              case  m{  $XML_NEC  }xms { $t = 'Nested XML-e closing tag';}
              case  m{  $XMLE_ST  }xms { $t = 'Self terminated XML element';}
              case  m{  $XMLE     }xms { $t = 'Regular XML element';}
              case  m{  $XML_NEO  }xms { $t = 'Nested XML-e opening tag';}
              else                     { $t = 'XMLE not covered yet'; }
          }#switch
          $m = sprintf $f,$i,$p,$e,$t;
          printf "%s\n", $m;
      }#foreach
}#sub test


sub   seek_file_pattern     {
      my    (   $opts_ref   )   =   @_;
      my $ts    =   ${$opts_ref}{input};
      my $cts   =   ${$opts_ref}{output};
      my $i     =   ${$opts_ref}{indent};
      my $p     =   ${$opts_ref}{indent_pattern};
      my $prea  =   ${$opts_ref}{preamble};
      my $file  =   ${$opts_ref}{seek};
      my $n     =   subroutine('name');
      printf "%*s%s()\n",$i,$prea,$n;
      if (  -e $file  ) {
            open ( my $flist,"<",$file) || die "Can't open $file : $!";
            my @ff = <$flist>;                                                                          # list of target files
            close   ( $flist );
            my $c;
            foreach my $f ( @ff ){
                printf "\n";
                chomp($f);
                $c++;
                printf "%*s%*s %s\n",$i,$p,3,$c,$f;
                sleep 2;
                parse_file( $f );
            }#for all files
      }#if target list exists
      printf "%*s%s() ... done\n",$i,$p,$n;
}#sub seek_file_pattern


sub   parse_file    {
      my    (   $file
            ,   $opts_ref   )   = @_;

                $opts_ref               //= \%opts;                                                     # default setting
                ${$opts_ref}{path}      //= '/sswork/gf22/niue1z1/lfilor/wa1/vsys';                     # default setting
                ${$opts_ref}{pattern}   //= '$system(';                                                 # default setting
                ${$opts_ref}{colar}     //= 3;                                                          # default setting

      my $ts    =   ${$opts_ref}{input};
      my $cts   =   ${$opts_ref}{output};
      my $i     =   ${$opts_ref}{indent};
      my $p     =   ${$opts_ref}{indent_pattern};
      my $path  =   ${$opts_ref}{path};
      my $ptrn  =   ${$opts_ref}{pattern};
      my $colar =   ${$opts_ref}{colar};
         $file  =~  s/.\//\//;                                                                          # strip [.] in file name
      my $f     =   $path.$file;
      my $n     =   subroutine('name');
      printf "%*s%s = %s\n",$i,$p,'Set Colar',$colar;
      if (  -e $f  ) {
            open ( my $fh,"<",$f) || die "Can't open $f : $!";
            my $lc;
            my @ll = <$fh>;                                                                             # list of target files
            close   ( $fh );
            #printf "%*s%s : %s\n",$i*2,$p,'Size of File',$#ll;
            foreach my $l ( @ll ){
                $lc++;
                chomp($l);
                #if ( $l =~ m/(?!\/\/)system/    )   {
                if ( $l =~ m{   [^/]+   system[(]  }xms    )   {
                    printf "%*s%*s %s\n",$i*2,$p,4,$lc,$l;
                    print_snippet('collect',$lc );
                }#match
                #printf "%*s%s\n",$i*2,$p,$l;#  if ($l =~ m/$ptrn/);
            }#foreach line in file
            print_snippet('print',$colar, \@ll);
      } else {
          printf  "%*s%s doesn't exist\n",$i*2,'',$f,
      }#file handling
}#sub parse


sub   print_snippet {
      my    (   $cntrl
            ,   $arg1
            ,   $arg2
            ,   $opts_ref   )   = @_;
                $opts_ref               //= \%opts;                                                     # default setting

      state     @catch;
      my        %collage;

      my $i     =   ${$opts_ref}{indent};
      my $p     =   ${$opts_ref}{indent_pattern};

      if    (   $cntrl  =~  m/collect/xms   ) {
            push  ( @catch, $arg1);                                                                     # collect all core lines
      } elsif ( $cntrl  =~  m/print/xms     ) {
            my $colar = $arg1;
            my @file  = @{$arg2};
            foreach my $line  (@catch)    {
                my $start = ($line-$colar <       0 ) ?       0 : $line-$colar;
                my $finish= ($line+$colar >  $#file ) ?  $#file : $line+$colar;
                for ( my $l=$start; $l<=$finish; $l++) {  $collage{$l} = 'print';
                }#assemble collage
            }#for each target
            my $ll = 0;
            foreach my $line (sort { $a <=> $b } keys %collage) {
                printf "\n" if ($ll+1 < $line);
                $ll = $line;
                printf "%*s%*s %s\n",$i*2,$p,4,$line,$file[$line];
            }#print collage in order
            @catch = ();                                                                                # implicit  clear @catch for next catch
            printf "\n";                                                                                # space
      } elsif ( $cntrl  =~  m/reset/xms     ) {                                                         # explicit  reset @catch for next catch
            @catch = ();
      } else {
            # WARN if debug
      }# This statement shall not be reached
}#sub print_snippet


sub   lint_test_sequence    {
      my    (   $opts_ref   )   = @_;
            ${$opts_ref}{input}         //= ${$opts_ref}{lint};                                         # 'basic_test.seq';
            ${$opts_ref}{output}        //= 'pruned.seq';
            ${$opts_ref}{lintlog}       //= 'logs/lint.log';                                            # maybe disabled if not needed
            ${$opts_ref}{lintprogress}  //= 'logs/tsg.log';                                             # tool log

      my $i     =   ${$opts_ref}{indent};
      my $p     =   ${$opts_ref}{indent_pattern};
      my $prea  =   ${$opts_ref}{preamble};
      my $n     =   subroutine('name');
      my $lnr;
      my $test  =   ${$opts_ref}{input};

      my @pruned;                                                                                       # output

      ${$opts_ref}{disgarded}   =   [];                                                                 # logging
      ${$opts_ref}{progress}    =   [];                                                                 # logging

      push ( @{${$opts_ref}{disgarded}}, sprintf "%s %s\n",'LINT : ', $test);
      printf "%*s%s()\n",$i,$prea,$n;
      printf "\n";
      printf "%*s%s : %s\n", $i,$p,'tmp Test Sequence', ${$opts_ref}{input};                            # command line input --lint=input.seq
      printf "%*s%s : %s\n", $i,$p,'tmp Test Sequence', ${$opts_ref}{output};                           # pruned.seq
      printf "%*s%s : %s\n", $i,$p,'Lint tsg log file', ${$opts_ref}{disgarded};                        # logs/lint.log
      printf "%*s%s : %s\n", $i,$p,'Tool tsg log file', ${$opts_ref}{progress};                         # logs/tsg.log
      printf "\n";
      if ( -e $test ) {
            extract_format ( $opts_ref, $test);
            open ( my $sequence,"<",$test) || die "Can't open $test : $!";
            my @lines = <$sequence>;
            foreach my $line (@lines){
                chomp $line; $lnr++;
                next if comment_line  ( $opts_ref, $line, $lnr );                                       # Handel comment lines and white space
                next if illegal_cmnd  ( $opts_ref, $line, $lnr );
                $line = trim_line     ( $opts_ref, $line, $lnr );                                       # remove formatting
                push ( @pruned, $line );
            }# prune sequence
            printf "%*s%s : %s\n", $i,$p, 'preprocessed TestName', ${$opts_ref}{output};
            write_textfile (  ${$opts_ref}{output},       \@pruned                );
            write_textfile (  ${$opts_ref}{lintlog},      ${$opts_ref}{disgarded} );
            write_textfile (  ${$opts_ref}{lintprogress}, ${$opts_ref}{progress}  );
      } else {
            printf  "     Can't find test sequence input file $test\n";
            printf  "     Terminate execution\n\n";
            warn    "     Can't find test sequence input file $test\n";
            exit 1;
      }# Terminate simulation when file not found
      printf "%*s%s() ... done\n",$i,$p,$n;
}#sub lint_test_sequence


sub   write_textfile {
      my    (   $file_name
            ,   $log_ref    )   = @_;
      open(my $logh,'>:encoding(UTF-8)', $file_name );
      foreach my $line ( @{$log_ref} ) {
            printf $logh "%s\n",$line;
      }#write out
      close(  $logh );
}#sub write_logfile


#     textfile -> array_ref
sub   read_textfile {
      my    (   $file_name
            ,   $a                                                                                          # array referenc3e
            ,   $opts_ref   )   = @_;
                $opts_ref   //= \%opts;

      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      if (-e $file_name) {
            open( my $file,"<",$file_name) || die "Can't open $file_name : $!";
            @{$a} = <$file>;                                                                                # slurp file --> @array
            close  ( $file );
      } else {
         printf "%*s%s\n",$i,$p,'WARNING : File %s not found',$file_name;
         exit 1;
      }# file not exits
}#sub read_textfile


sub   view_list     {
      my    (   $ar
            ,   $msg
            ,   $opts_ref   )   = @_;
                $opts_ref   //= \%opts;                                                                     # default interface
      my $i     =   ${$opts_ref}{indent};
      my $p     =   ${$opts_ref}{indent_pattern};
      my $w     =   length($#{$ar});
      my $c;
      printf "\n";
      printf "%*s%s:\n", $i,$p,$msg;
      foreach my $entry (@{$ar}) {
          printf "%*s%*s %s\n",$i,$p,$w,++$c,$entry;
      }#list them all
      printf "\n";
}#sub view_listy


sub   flush_test_sequence   {
      my    (   $opts_ref                                                                                   # Input     Reference to %opts w/ commandline input
            ,   $defs_ref
            ,   $mmap                                                                                       # Input     Reference to memory map
            ,   $tseq_ref   )   = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      my $file_name = ${$opts_ref}{specification};
      my %spec;
      my $lnr;
      printf "%*s%s()++\n",$i,$p,$n if( debug($n));
      if ( defined ${$opts_ref}{specification}  ){
        if (-e $file_name) {
            open ( my $spec,"<",$file_name) || die "Can't open $file_name : $!";
            my @lines = <$spec>;
            foreach my $line (@lines){
                chomp $line; $lnr++;
                ${$opts_ref}{line}   =   $line;
                #printf "%s\n", $line;
                next if comment_line  ( $opts_ref, $line, $lnr );                                           # Handel comment lines and white space
                parse_init ( $opts_ref, $line      , $lnr );                                                # Extract information from FILE.ini
                valid_init ( $opts_ref, $tseq_ref  , $lnr );                                                # Convert information into Specification
                store_init ( $opts_ref, $tseq_ref  );                                                       # Store   information
                printf "\n";
            }#all lines
            close( $spec );
            compile_sequence( $opts_ref, $defs_ref, $tseq_ref );                                            # Compile sequence of instructions
            writing_sequence( $opts_ref, $defs_ref );                                                       #
        } else {
                warn "     Can't find Specification input file $file_name\n";
         }#
      }#if specification
}#sub flush_test_sequence


sub   extract_format {
      my    (   $opts_ref
            ,   $file_name  )   = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $lnr;
      my $ci = 1;                                                                                           # column index
      my $c;                                                                                                # comment detect
      open ( my $file,"<",$file_name) || die "Can't open $file_name : $!";
      my @lines = <$file>;
      close ( $file );
      ${$opts_ref}{format}{$file_name} = [];                                                                # reference to a files format information
      foreach my $line (@lines){
          chomp $line;
          $lnr++; $c=0;                                                                                     # line count, comment reset
          ${${$opts_ref}{format}{$file_name}}[0] = ( defined ${${$opts_ref}{format}{$file_name}}[0] )
                                                 ?   ${${$opts_ref}{format}{$file_name}}[0] :  0;
          ${${$opts_ref}{format}{$file_name}}[0] = ( ${${$opts_ref}{format}{$file_name}}[0] > length ($line) )
                                                 ?   ${${$opts_ref}{format}{$file_name}}[0] : length ($line);
          $c += 1 if ( $line =~ m{^$  }x    );
          $c += 1 if ( $line =~ m{^[/]{2} }x);
          $c += 1 if ( $line =~ m{^[#]}x    );

          next if $c;

          #printf "%*s%*s: %s\n",$i,$p,4,$lnr,$line;
          $line =~ s/ \h+/ /g;                                                                              # horizontal whitespace
          $line =~ s/^\s+|\s+$//g;                                                                          # trim
          #printf "%*s%*s: %s\n",$i,$p,4,$lnr,$line;
          my @columns = split (/ /, $line);
          $ci = 1;
          foreach my $col (@columns) {
                ${${$opts_ref}{format}{$file_name}}[$ci] = ( defined ${${$opts_ref}{format}{$file_name}}[$ci] )
                                                         ?   ${${$opts_ref}{format}{$file_name}}[$ci] :  0;
                ${${$opts_ref}{format}{$file_name}}[$ci] = ( ${${$opts_ref}{format}{$file_name}}[$ci] > length ($col) )
                                                         ?   ${${$opts_ref}{format}{$file_name}}[$ci] : length ($col);
                $ci++;
          }#foreach
      }#
      $ci = 0;
      foreach my $width ( @{${$opts_ref}{format}{$file_name}} ) {
        printf "%*s%s[%2s] : %s\n", $i,$p,'Column',$ci, ${${$opts_ref}{format}{$file_name}}[$ci];
        $ci++;
      }#
      printf "\n\n";
}#sub extract_format


sub   trim_line {
      my    (   $opts_ref
            ,   $line
            ,   $lnr        )   = @_;
            #${$opts_ref}{output_format}  //= 'crunshed';
            ${$opts_ref}{output_format}  //= 'right_aligned';
            #${$opts_ref}{output_format}   //= 'left_aligned';

      $line =~ s/ \h+/ /g;                                                                                  # horizontal whitespace
      $line =~ s/^\s+|\s+$//g;                                                                              # trim
      switch ( ${$opts_ref}{output_format} ) {
            case    m/\bcrunched\b/         { return $line;         }                                       # crunched     not aligned
            case    m/\bright_aligned\b/    { $line = align( $line,'right');}                               # tabellized right aligned
            case    m/\bleft_aligned\b/     { $line = align( $line,'left' );}                               # tabellized  left aligned
            else                            { return $line;         }                                       # default case is crunched
      }#switch
      return $line;
}#sub trim_line


sub   comment_line {
      my    (   $opts_ref
            ,   $line
            ,   $lnr        )   = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      my $f = ${$opts_ref}{input};                                                                          # file name
      my $s = ${${$opts_ref}{format}{$f}}[0];                                                               # line size max
      my $c = 0;

      $c += 1 if ( $line =~ m{^$  }x    );
      $c += 1 if ( $line =~ m{^[/]{2} }x);
      $c += 1 if ( $line =~ m{^[#]}x    );

      if ($c >= 1) {
        printf "%*s%s( line# %3s)\n",$i,$p,$n, $lnr if( debug($n));
        printf "%4s %s\n",$lnr,$line  if( debug($n));
        my $msg = sprintf "%4s %-*s : %s",$lnr,$s,$line,'Comment line' ;
        push ( @{${$opts_ref}{disgarded}}, sprintf "%4s %*s",$lnr,$s,$line );
        push ( @{${$opts_ref}{progress}} , $msg );
        return 1;
      } else {
        return 0;
      }# is comment line
}#sub comment_line


sub   align {
      my    (   $line
            ,   $format
            ,   $opts_ref   )   = @_;
                $opts_ref   //= \%opts;

      my @columns = split( / /, $line);
      switch ( $format ) {
          case m/\bright\b/     { $line = wt($line, $RIGHT); }
          case m/\bleft\b/      { $line = wt($line, $LEFT);  }
          else                  {   }                                                                       # no default case defined
      }#switch
      return $line;
}#sub align


sub   wt    {                                                                                               # write table
      my    (   $line
            ,   $align
            ,   $opts_ref   )   = @_;
                $opts_ref   //= \%opts;

      my @columns   = split( / /, $line);
      my $file_name = ${$opts_ref}{input};
      my $row;
      my $ci = 1;
      foreach my $col ( @columns ) {
            my $width = $align * ${${$opts_ref}{format}{$file_name}}[$ci];
            $row .= sprintf ("%*s ",$width, $col );
            $ci++;
      }#foreach
      printf "%s\n", $row;
      return $row;
}#sub wt

sub   illegal_cmnd  {
      my    (   $opts_ref
            ,   $line
            ,   $lnr        )   = @_;
      my $msg;
      my ($c, $a1, $a2);

      my $f = ${$opts_ref}{input};                                                                          # file name
      my $s = ${${$opts_ref}{format}{$f}}[0];                                                               # line size max

      if (  $line  =~  m{^\s*   ($KEYWORD)                                # <== Keyword
                          #\s+   ($DATAWORD)                               # <== DATA and or ADDR
                          #\s*   ($DATAWORD)?                              # <== DATA
                        }x                ) {                             # regex
            ( $c, $a1, $a2) = ( $1, $2, $3 );
      #     printf "%s %s %s", $c, $a1, $a2;                              # debugging
      } else {
            # WARNING -- if total garbage skip line
      }# read test sequence file line by line

      if ( $c ~~ @{${$opts_ref}{instructions}} ) {
          $msg = sprintf "%4s %-*s : %s",$lnr,$s,$line,'  Valid instruction' ;
          push ( @{${$opts_ref}{progress}} , $msg );
          return $FALSE;
      } else {
          push ( @{${$opts_ref}{disgarded}}, sprintf "%4s %-*s\n",$lnr,$s,$line );
          $msg = sprintf "%4s %-*s : %s",$lnr,$s,$line,'Invalid instruction' ;
          push ( @{${$opts_ref}{progress}} , $msg );
          return $TRUE;
      }
}#sub illegal_cmnd


sub   compile_error {
      my    ( $msg
            , $opts_ref     )   = @_;
      $opts_ref   //=   \%opts;
      my $lfh       =   ${$opts_ref}{compile_fh};                       # compile log file handle
      printf $lfh "",
}#sub  compile_error


sub   illegal_metric {
      my    ( $msg
            , $opts_ref     )   = @_;
      $msg      //= 'illegal metric';
      $opts_ref //= \%opts;

      my $i1      = 17;
      my $i       = ${$opts_ref}{indent};
      my $line    = ${$opts_ref}{line};
      my $lnr     = ${$opts_ref}{linenumber};
      my $lfh     = ${$opts_ref}{compile_fh};                           # compile log file handle
      my $p       = ${$opts_ref}{indent_pattern};
      printf $lfh "%*s %s",$i,$lnr,$line;
      printf $lfh "%*s *ERROR %s\n",$i,$p,$msg;
      ${$opts_ref}{warnings}++;                                         # increase/raise WARNING count
}#sub illegal_metric


sub   illegal_prefix {
      my    ( $msg
            , $opts_ref     )   = @_;
      $msg      //= 'illegal prefix';
      $opts_ref //= \%opts;
      my $i       = ${$opts_ref}{indent};
      my $line    = ${$opts_ref}{line};
      my $lfh     = ${$opts_ref}{compile_fh};                           # compile log file handle
      my $lnr     = ${$opts_ref}{linenumber};
      my $p       = ${$opts_ref}{indent_pattern};
      printf $lfh "%*s %-*s",$i,$lnr,40,$line;                          # artificial align 40 line length
      printf $lfh "%*s *ERROR %s\n",$i,$p,$msg;
      ${$opts_ref}{warnings}++;                                         # increase/rasie WARNING count
}#sub illegal_prefix


sub   warning {
      my    ( $msg
            , $opts_ref     )   = @_;
      $msg      //= 'Unknown Warning';
      $opts_ref //= \%opts;
      my $i       = ${$opts_ref}{indent};
      my $line    = ${$opts_ref}{line};
      my $lfh     = ${$opts_ref}{compile_fh};                           # compile log file handle
      my $lnr     = ${$opts_ref}{linenumber};
      my $p       = ${$opts_ref}{indent_pattern};
      printf $lfh "%*s %-*s",$i,$lnr,40,$line;                          # artificial align 40 line length
      printf $lfh "%*s *ERROR %s\n",$i,$p,$msg;
      ${$opts_ref}{warnings}++;
}#sub warning


sub   parse_init {
      my    (   $opts_ref                                               # command line reference
            ,   $line                                                   # line
            ,   $lnr        )   = @_;                                   # line-number
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                             # white space
      my $n = subroutine('name');

      ${$opts_ref}{warnings}    = 0;                                    # reset  warnings for each line
      ${$opts_ref}{metric}      = '';                                   # reset  metric
      ${$opts_ref}{prefix}      = '';                                   # reset  prefix
      ${$opts_ref}{unit}        = '';                                   # reset  unit

      ${$opts_ref}{linenumber}  = $lnr;                                 # store <file>.ini lnr

      printf "%*s%s()\n",$i,$p,$n   if( debug($n));
      printf "%4s %s\n" ,$lnr,$line if( debug($n));

      if ( $line =~  m{^  ($KEYWORD)                                    # <== Keyword
                      \s+ ($DATAWORD)                                   # <== DATA and or ADDR
                      \s* ($MEASURE)?                                   # increase readability w/ x-modifier
                      }x                      )                         # regex
      {
          ${$opts_ref}{keyword}   =   $1;
          ${$opts_ref}{keyword}   =~  s/[ ]//;                          # remove leading and trailing white space
          ${$opts_ref}{dataword}  =   $2;
          ${$opts_ref}{metric}    =   $3;

          my $hexa  =   (   ${$opts_ref}{keyword}                       # keyword determins the base of DATAWORD
                        ~~  ${$opts_ref}{default_hexadecimal}   )
                        ?   $TRUE   : $FALSE;

          ${$opts_ref}{default_base}                                    # default base for magnification
          =     (   ${$opts_ref}{keyword}
                ~~  ${$opts_ref}{default_hexadecimal}  )
                ?   'binary'    :   'decimal';                          # 1024 vs 1000

          # ${$opts_ref}{default_base} depending on keyword ???

          if ( defined ${$opts_ref}{dataword}  ) {
                printf "%*s%s"  , $i,$p
                                , ${$opts_ref}{dataword} if( debug($n));
                if (${$opts_ref}{dataword}  =~ m{   ($PREAMBLE)?        # optional  preamble <0x>
                                                    ($NIBBLE+)          # mandatory unit
                                                }x )
                {
                    ${$opts_ref}{value}     =   $2;
                    ${$opts_ref}{value}     =~  s/_//;                  # Remove group separator
                    ${$opts_ref}{value}     =   ($hexa)                 # MAX Vale === 0xFFFF_FFFF
                                            ?   hex ${$opts_ref}{value} # Value is hexadec by default
                                            :       ${$opts_ref}{value};# Value is decimal by default
                    printf " = %s Success"  ,${$opts_ref}{value} if( debug($n));
                }#extract value form string
                else {
                }# Fail extraction
                printf "\n" if( debug($n));
          } else {
                # WARNING - NO value extrcted
          }

          # base is 1000 for common prefix and 1024 for binary prefix, but magnitude is the same
          #
          if ( defined ${$opts_ref}{metric} ) {
              ${$opts_ref}{metric}            =~  s/K/k/;               # allow user error for robustness
              printf "%*s%s"  ,$i,$p
                              ,${$opts_ref}{metric}   if( debug($n) );
              if (${$opts_ref}{metric} =~ m{  ($PREFIX)?                # optional  prefix
                                              ($UNITS)                  # mandatory unit
                                            }x )
              {
                  ${$opts_ref}{unit}            =   $2;                 #
                  ${$opts_ref}{prefix}          =   $1;
###               ${$opts_ref}{magnitude}       =   (${$opts_ref}{prefix} =~ m/Y/   ) ?  8  # Yotta is the largest supported prefix    1000^8
###                                             :   (${$opts_ref}{prefix} =~ m/Z/   ) ?  7  # Zetta is supported prefix                1000^7
###                                             :   (${$opts_ref}{prefix} =~ m/E/   ) ?  6  # Eta   is supported prefix                1000^6
###                                             :   (${$opts_ref}{prefix} =~ m/P/   ) ?  5  # Peta                                     1000^5
###                                             :   (${$opts_ref}{prefix} =~ m/T/   ) ?  4  # Tera                                     1000^4
###                                             :   (${$opts_ref}{prefix} =~ m/G/   ) ?  3  # Giga                                     1000^3
###                                             :   (${$opts_ref}{prefix} =~ m/M/   ) ?  2  # Mega                                     1000^2
###                                             :   (${$opts_ref}{prefix} =~ m/k/   ) ?  1  # kilo                                     1000^1
###                                             :   (! defined ${$opts_ref}{prefix} ) ?  0  #                                    1 === 1000^0
###                                             :   (${$opts_ref}{prefix} =~ m/m/   ) ? -1  # milli
###                                             :   (${$opts_ref}{prefix} =~ m/u/   ) ? -2  # micro
###                                             :   (${$opts_ref}{prefix} =~ m/n/   ) ? -3  # nano
###                                             :   (${$opts_ref}{prefix} =~ m/p/   ) ? -4  # pico
###                                             :   (${$opts_ref}{prefix} =~ m/f/   ) ? -5  # femto
###                                             :   (${$opts_ref}{prefix} =~ m/a/   ) ? -6  # atto  is supported prefix
###                                             :   (${$opts_ref}{prefix} =~ m/z/   ) ? -7  # zetto is supported prefix
###                                             :                                       -8; # yotto is the smalles supported prefix
                  ${$opts_ref}{prefix}        //=   '';                                     # default setting
                  ${$opts_ref}{magnitude}       =   (${$opts_ref}{prefix} eq 'Y'    ) ?  8  # Yotta is the largest supported prefix    1000^8
                                                :   (${$opts_ref}{prefix} eq 'Z'    ) ?  7  # Zetta is supported prefix                1000^7
                                                :   (${$opts_ref}{prefix} eq 'E'    ) ?  6  # Eta   is supported prefix                1000^6
                                                :   (${$opts_ref}{prefix} eq 'P'    ) ?  5  # Peta                                     1000^5
                                                :   (${$opts_ref}{prefix} eq 'T'    ) ?  4  # Tera                                     1000^4
                                                :   (${$opts_ref}{prefix} eq 'G'    ) ?  3  # Giga                                     1000^3
                                                :   (${$opts_ref}{prefix} eq 'M'    ) ?  2  # Mega                                     1000^2
                                                :   (${$opts_ref}{prefix} eq 'k'    ) ?  1  # kilo                                     1000^1
                                                :   (${$opts_ref}{prefix} eq ''     ) ?  0  #                                    1 === 1000^0
                                                :   (${$opts_ref}{prefix} eq 'm'    ) ? -1  # milli
                                                :   (${$opts_ref}{prefix} eq 'u'    ) ? -2  # micro
                                                :   (${$opts_ref}{prefix} eq 'n'    ) ? -3  # nano
                                                :   (${$opts_ref}{prefix} eq 'p'    ) ? -4  # pico
                                                :   (${$opts_ref}{prefix} eq 'f'    ) ? -5  # femto
                                                :   (${$opts_ref}{prefix} eq 'a'    ) ? -6  # atto  is supported prefix
                                                :   (${$opts_ref}{prefix} eq 'z'    ) ? -7  # zetto is supported prefix
                                                :                                       -8; # yotto is the smalles supported prefix
                  printf      " : %s %s =  %s\n"  ,${$opts_ref}{prefix}
                                                  ,${$opts_ref}{unit}
                                                  ,${$opts_ref}{magnitude}    if( debug($n));
              } else {
                   #WARNING - SI unit not recognized
              }
          } else {
             ${$opts_ref}{metric}            //=   '';
             ${$opts_ref}{prefix}            //=   '';
             ${$opts_ref}{unit}              //=   '';
             ${$opts_ref}{magnitude}         //=   '';
          }
          printf "%*s%s %s %s+++++++\n" ,$i,$p
                                        ,${$opts_ref}{keyword}
                                        ,${$opts_ref}{dataword}
                                        ,${$opts_ref}{metric}       if( debug($n));
      }#value assignment
      else {
          printf "--\n" if( debug($n));
          ${$opts_ref}{keyword}     =   $1;
          ${$opts_ref}{value}       =   $2;
          ${$opts_ref}{metric}      =   $3;
          if ( $line =~  m{   ($KEYWORD)      # <== Keyword
                          \s+ ($DATAWORD)     # <== ADDR or DATA
                          \s+ ($MEASURE)?     # increase readability w/ x-modifier
                          }x ) {
                ${$opts_ref}{keyword}   =   $1;
                ${$opts_ref}{value}     =   $3;
                ${$opts_ref}{metric}    =   $4;
          }#parse a second time
      }# parse again
}#sub parse_init


sub   observe_extraction {
      my    (   $opts_ref   )   = @_;
      $opts_ref //= \%opts;                                                             # default setting
      my $n       =  subroutine('name');
      if( debug($n) ){
          printf "%*s%s()\n", 5,'',$n;
          printf "%*s<%-*s>%*s %*s\n", 5,''
                                ,12,${$opts_ref}{keyword}
                                ,14,${$opts_ref}{dataword}
                                , 5,${$opts_ref}{metric};
      }#
}#sub observe_extraction

#sub   convert_addressspace { ...
#}#sub convert_addressspace


sub   convert_blockrange {
      my    (   $opts_ref
            ,   $tseq_ref   )   = @_;
                $opts_ref   //= \%opts;                                                 # default setting
                $tseq_ref   //= \%testspecification;

      my $i             =  ${$opts_ref}{indent};
      my $p             =  ${$opts_ref}{indent_pattern};                                # ${$opts_ref}{padding_pattern}
      my $n             =  subroutine('name');
      my $unit          =  ${$opts_ref}{unit};                                          # input unit
      my $prefix        =  ${$opts_ref}{prefix};                                        # input prefix
      my $data_units    =  ${$opts_ref}{units_of_data_size};                            # [ qw ( bit byte        ) ]
      my $legal_prefix  =  ${$opts_ref}{legal_data_prefixes};                           # [ qw ( Y Z E P T G M k ) ]
      my $uscale        = (${$opts_ref}{metric}         =~ m/byte/  )   ?   1 :    8;
      my $base          = (${$opts_ref}{default_base}   =~ m/binary/)  ? 1024 : 1000;   # base       2**10     10**3
      my $mscale        =  $base ** ${$opts_ref}{magnitude};                            # magnification -8 .. 0 .. 8
      push (@{$legal_prefix}, '');                                                      # Add empty string, in search for better solution

      my $wordsize      = ${$tseq_ref}{databussize}{basevalue};
         $wordsize    //= $WORDSIZE;                                                    # Default 32 bit

      illegal_metric() unless (is_subset( [$unit],   $data_units   ));
      illegal_prefix() unless (is_subset( [$prefix], $legal_prefix ));

      warning('Data Bus Size undefined')
      unless ( defined ${$tseq_ref}{databussize}{basevalue} );                          # Word size undefined

      ${$opts_ref}{baseunit}    = 'byte';                                               # internal/preferred unit
      ${$opts_ref}{basevalue}   = ${$opts_ref}{value} * $mscale;                        # internal/preferred value scaled to magnitude
      ${$opts_ref}{basevalue}  /= $uscale;                                              # internal/preferred value scaled to unit

      warning('Not Word Aligned')        if ( ${$opts_ref}{basevalue} % $wordsize );    # Word aligned
      warning('Not 1K Boundary Aligned') if ( ${$opts_ref}{basevalue} % $BOUNDARY_1K ); # 1K Boundary aligned
      warning('Not 4k Boundary Aligned') if ( ${$opts_ref}{basevalue} % $BOUNDARY_4K ); # 4K Boundary aligned

      if ( debug($n) ) {
          printf "%*s%s()\n",$i,$p,$n;
          printf "%*s%s [%s] ",$i*2,$p,'unit', $unit;
          printf "Is Subset Data Units\n"     if      (is_subset( [$unit], $data_units ));
          printf "Is NOT Subset Data Units\n" unless  (is_subset( [$unit], $data_units ));
          printf "%*s%s [%s] ",$i*2,$p,'prefix ', $prefix;
          printf "Is legal  Prefix  \n"   if      (is_subset( [$prefix], $legal_prefix ));
          printf "Is illegal  Prefix  \n" unless  (is_subset( [$prefix], $legal_prefix ));
      }#debugging

}#sub convert_blockrange


sub   convert_reserve {                                                                 # address
      my    (   $opts_ref
            ,   $tseq_ref   )   = @_;
                $opts_ref   //= \%opts;                                                 # default setting
                $tseq_ref   //= \%testspecification;                                    # default setting,

      my $i             =  ${$opts_ref}{indent};
      my $p             =  ${$opts_ref}{indent_pattern};                                # ${$opts_ref}{padding_pattern}
      my $n             =  subroutine('name');
      my $unit          =  ${$opts_ref}{unit};                                          # input unit
      my $prefix        =  ${$opts_ref}{prefix};                                        # input prefix
      my $data_units    = [];  push (@{$data_units}  , '');                             # Empty String Set
      my $legal_prefix  = [];  push (@{$legal_prefix}, '');                             # Empty String Set
      my $addr          = ${$opts_ref}{value};
      my $wordsize      = ${$tseq_ref}{databussize}{basevalue};
         $wordsize    //= $WORDSIZE;                                                    # Default 32 bit

      ${$opts_ref}{baseunit}    = 'byte';                                               # ??? address implies [byte]
      ${$opts_ref}{basevalue}   = $addr;

      illegal_metric() unless (is_subset( [$unit],   $data_units   ));                  # NO METRIC
      illegal_prefix() unless (is_subset( [$prefix], $legal_prefix ));                  # NO PREFIX

      warning('out of range')            unless (   $addr >= $LARBOUNDARY
                                                &&  $addr <= $UARBOUNDARY );            # Address Range check
      warning('Data Bus Size undefined')
      unless ( defined ${$tseq_ref}{databussize}{basevalue} );                          # Word size undefined

      warning('Not Word Aligned')        if     (   $addr % $wordsize );                # Word aligned

      if ( debug($n) ) {
          printf "%*s%s()\n",$i,$p,$n;
          printf "%*s%-*s [%10s] byte\n",     $i,$p,25,'Wordsize', $wordsize;
          printf "%*s%-*s [%10x] \n",         $i,$p,25,'Lower Address Boundry', $LARBOUNDARY;
          printf "%*s%-*s [%10x] \n",         $i,$p,25,'Upper Address Boundry', $UARBOUNDARY-1;
          printf "%*s%-*s [%10x] \n",         $i,$p,25,'Exclude Address      ', $addr;
          printf "%*s%s [%s]",                $i,$p,25,'unit', $unit;
          printf "Is     Subset Data Units\n" if     (is_subset( [$unit],   $data_units   ));
          printf "Is NOT Subset Data Units\n" unless (is_subset( [$unit],   $data_units   ));
          printf "%*s%s [%s]",                $i,$p,25,'prefix', $prefix;
          printf "Is   legal  Prefix  \n"     if     (is_subset( [$prefix], $legal_prefix ));
          printf "Is illegal  Prefix  \n"     unless (is_subset( [$prefix], $legal_prefix ));
          printf "%*s%-*s [%10x] \n",         $i,$p,25,'WARNINGS             ', ${$opts_ref}{warnings};
      }# debugging

      if ( ${$opts_ref}{warnings} == 0 ) {
            # ${$opts_ref}{memorymap}   reference to %memorymap
            ${${$opts_ref}{memorymap}}{$addr}{addr}     =   $addr;
            ${${$opts_ref}{memorymap}}{$addr}{reserved} =   'reserved';                 # Exclude ADDR in MEMORYMAP
      }# exclude address from memory map/address space
}#sub convert_reserve


sub   convert_baseaddress {
      my    (   $opts_ref
            ,   $tseq_ref   )   = @_;
                $opts_ref   //= \%opts;                                                 # default setting
                $tseq_ref   //= \%testspecification;

      my $i             =  ${$opts_ref}{indent};
      my $p             =  ${$opts_ref}{indent_pattern};                                # ${$opts_ref}{padding_pattern}
      my $n             =  subroutine('name');
      my $unit          =  ${$opts_ref}{unit};                                          # input unit
      my $prefix        =  ${$opts_ref}{prefix};                                        # input prefix
      my $data_units    = [];  push (@{$data_units}  , '');                             # Empty String Set
      my $legal_prefix  = [];  push (@{$legal_prefix}, '');                             # Empty String Set
      my $addr          = ${$opts_ref}{value};
      my $wordsize      = ${$tseq_ref}{databussize}{basevalue};
         $wordsize    //= $WORDSIZE;                                                    # Default 32 bit
      my $msg1          = ( defined ${$tseq_ref}{databussize}{basevalue})
                        ? '    defined':'not defined';
      my $Undefined_DBS = 'databussize undefined !! Use default 32 bit';

      ${$opts_ref}{baseunit}    = 'byte';                                               # ??? address implies [byte]
      ${$opts_ref}{basevalue}   = $addr;

      illegal_metric() unless (is_subset( [$unit],   $data_units   ));                  # NO METRIC
      illegal_prefix() unless (is_subset( [$prefix], $legal_prefix ));                  # NO PREFIX

      warning($Undefined_DBS)   unless (defined ${$tseq_ref}{databussize}{basevalue} );
      warning('out of range')   unless (   $addr >= $LARBOUNDARY
                                       &&  $addr <= $UARBOUNDARY );                     # Address Range check
      warning('Data Bus Size undefined') unless (defined ${$tseq_ref}{databussize} );   # Word size undefined
      warning('Not        Word Aligned') if     (          $addr % $wordsize       );   # Word aligned
      warning('Not 1K Boundary Aligned') if     (          $addr % $BOUNDARY_1K    );   # 1K Boundary aligned
      warning('Not 4k Boundary Aligned') if     (          $addr % $BOUNDARY_4K    );   # 4K Boundary aligned

      if ( debug($n) ) {
          printf "%*s%s()\n",$i,$p,$n;
          printf "%*s%-*s  %10s  \n",             $i*2,$p,25,'Databussize',$msg1;
          printf "%*s%-*s [%10s] byte\n",         $i*2,$p,25,'Wordsize', $wordsize;
          printf "%*s%-*s [%10x] \n",             $i*2,$p,25,'Lower Address Boundry', $LARBOUNDARY;
          printf "%*s%-*s [%10x] \n",             $i*2,$p,25,'Upper Address Boundry', $UARBOUNDARY-1;
          printf "%*s%-*s [%10x] \n",             $i*2,$p,25,'Baseaddress          ', $addr;
          printf "%*s%s [%s]" ,                   $i*2,$p,'unit', $unit;
          printf "%Is     Subset Data Units\n"    if      (is_subset( [$unit],   $data_units   ));
          printf "Is NOT Subset Data Units\n"     unless  (is_subset( [$unit],   $data_units   ));
          printf "%*s%s [%s]\n"                 , $i*2,$p,'prefix', $prefix;
          printf "Is   legal  Prefix  \n"    , $i*2,$p if      (is_subset( [$prefix], $legal_prefix ));
          printf "%*sIs illegal  Prefix  \n"    , $i*2,$p unless  (is_subset( [$prefix], $legal_prefix ));
          printf "%*s%-*s [%10x] \n",             $i*2,$p,25,'WARNINGS             ', ${$opts_ref}{warnings};
      }# debugging
      ${$opts_ref}{valid} = (${$opts_ref}{warnings} == 0)? 'valid':'invalid';
}#sub convert_baseaddress


sub   convert_databussize {
      my    (   $opts_ref
            ,   $tseq_ref   )   = @_;
                $opts_ref   //= \%opts;                                                 # default setting
                $tseq_ref   //= \%testspecification;

      my $i             =  ${$opts_ref}{indent};
      my $p             =  ${$opts_ref}{indent_pattern};                                # ${$opts_ref}{padding_pattern}
      my $n             =  subroutine('name');
      my $unit          =  ${$opts_ref}{unit};                                          # input unit
      my $prefix        =  ${$opts_ref}{prefix};                                        # input prefix
      my $data_units    =  ${$opts_ref}{units_of_data_size};                            # [ qw ( bit byte        ) ]
      my $legal_prefix  =  ${$opts_ref}{legal_data_prefixes};                           # [ qw ( Y Z E P T G M k ) ]
      my $uscale        = (${$opts_ref}{metric}         =~ m/byte/  )  ?    1 :    8;
      my $base          = (${$opts_ref}{default_base}   =~ m/binary/)  ? 1024 : 1000;   # base       2**10     10**3
      my $mscale        =  $base ** ${$opts_ref}{magnitude};                            # magnification -8 .. 0 .. 8
      push (@{$legal_prefix}, '');                                                      # Add empty string, in search for better solution

      illegal_metric() unless (is_subset( [$unit],   $data_units   ));                  # NO METRIC
      illegal_prefix() unless (is_subset( [$prefix], $legal_prefix ));                  # NO PREFIX

      if ( debug($n) ) {
          printf "%*s%s()\n",$i,$p,$n;
      }# debugging
      ${$opts_ref}{valid} = (${$opts_ref}{warnings} == 0)? 'valid':'invalid';
}#sub convert_databussize


sub   valid_init {
      my    (   $opts_ref
            ,   $tseq_ref
            ,   $lnr        )   = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      my $warn = 0;
      my %entry;
      my $base;

      if( debug($n) ) {
          printf "%*s%s()\n",$i,$p,$n;
          printf "%*s<%-*s>%*s %*s\n",$i,$p
                                     ,12,${$opts_ref}{keyword}
                                     ,14,${$opts_ref}{dataword}
                                     , 5,${$opts_ref}{metric};
      }# debugging

      switch ( ${$opts_ref}{keyword} ) {                                                                     # Not working, use Switch not installed
            case    m/\baddresssize\b/  { observe_extraction($opts_ref); }
            case    m/\baddressspace\b/ { observe_extraction(); }
            case    m/\bbaseaddress\b/  { observe_extraction();
                                          convert_baseaddress();}
            case    m/\bblock_range\b/  { observe_extraction();
                                          convert_blockrange(); }
            case    m/\bdatabussize\b/  { observe_extraction();
                                          convert_databussize();}
            case    m/\breserved\b/     { convert_reserve();    }
            else                        { warning('unknown keyword');    }
      }#switch

      if ( ${$opts_ref}{keyword} ~~ @{${$opts_ref}{keywords}} ) {
           if        (${$opts_ref}{keyword} =~ m/addresssize/ ){
                 warning('illegal metric') unless (${$opts_ref}{metric} ~~ [ qw (bit byte) ]);
           } elsif   (${$opts_ref}{keyword} =~ m/addressspace/ ){
                 warning('illegal metric') unless (${$opts_ref}{unit}   ~~ [ qw (bit byte) ]);
                 warning('illegal_prefix') unless (${$opts_ref}{prefix} ~~ [qw ( E P T G M k )]);
                 if  (${$opts_ref}{unit}  ~~ [ qw (bit byte) ]) {
                     if  (${$opts_ref}{prefix} ~~ [qw ( E P T G M k ) ] ) {
                         printf  "%*s%*s prefix\n",5,'',17,${$opts_ref}{prefix};
                     } else {
                         illegal_prefix();
                     }
                     # prefered byte
                     ${$opts_ref}{value}  >>=  3 if  (${$opts_ref}{metric} =~ m/bit/);

                     if ( ${$opts_ref}{value} == 0) {
                     } else {
                     }#
                 } else {
                     illegal_metric();
                 }# right metric
           } elsif   (${$opts_ref}{keyword} =~ m/baseaddress/ ){
           } elsif   (${$opts_ref}{keyword} =~ m/block_range/ ){                 # convert_blockrange
           } elsif   (${$opts_ref}{keyword} =~ m/databussize/ ){
                 if  (${$opts_ref}{metric}  ~~ [ qw (bit byte) ]) {
                     if  (   ${$opts_ref}{prefix} ~~ [qw ( E P T G M k ) ]
                         ||  ${$opts_ref}{prefix} !~ m// ) {
                         $base = (${$opts_ref}{default_base} =~ m/binary/)?1024:1000;
                         my $scale = $base**${$opts_ref}{magnitude};
                         printf "%*s%*s %s\n",$i,$p,-17,'base'       ,$base;
                         printf "%*s%*s %s\n",$i,$p,-17,'prefix'     ,${$opts_ref}{prefix};
                         printf "%*s%*s %s\n",$i,$p,-17,'magnitude'  ,${$opts_ref}{magnitude};
                         printf "%*s%*s %s\n",$i,$p,-17,'scale2base' ,$scale;
                         ${$opts_ref}{basevalue} = ${$opts_ref}{value} * $scale;
                         ${$opts_ref}{baseunit}  = 'byte';
                     } else {
                         illegal_prefix();
                         $warn += 1;
                     }# pref
                     my $unitscale = (${$opts_ref}{metric} =~ m/byte/) ? 1 : 8;  # Prefered unit
                     ${$opts_ref}{basevalue}    /= $unitscale;
                     ${$opts_ref}{metric}    = 'byte' if( ${$opts_ref}{metric} =~ m/bit/ );
                 } else {
                     illegal_metric();
                 }# right metric
           } elsif   (${$opts_ref}{keyword} =~ m/wordaligned/ ){
                 if  (${$opts_ref}{metric}  ~~ [ qw (bit byte) ]) {
                     # preferable byte
                 } else {
                     illegal_metric();
                 }# right metric
           } elsif   (${$opts_ref}{keyword} =~ m/blk_boundry/ ){
                 if  (${$opts_ref}{metric}  ~~ [ qw (bit byte) ]) {
                     #preferable byte
                 } else {
                     illegal_metric();
                 }# right metric
           } elsif   (${$opts_ref}{keyword} =~ m/reserved/ ){                    # convert_reserved
           } elsif   (${$opts_ref}{keyword} =~ m/mask/ ){
           }# check keyword
      } else {
          warning('unknown keyword');
          #printf "%*s%-*s unknown keyword\n", 5,'',17,${$opts_ref}{keyword};
          $warn += 1;
      }# unknown keyword
      ${$opts_ref}{valid}     = ($warn > 0) ? 'invalid' : 'valid';
}#sub valid_init


sub   store_init {                                                                                          # Store valid parameter only
      my    (   $opts_ref
            ,   $tseq_ref   ) = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      printf "%*s%s()\n",$i,$p,$n   if( debug($n));
      my %entry;
      my $keyword           =   ${$opts_ref}{keyword};                                                      # reference of object aka base_address
      $entry{valid}         =   ${$opts_ref}{valid};                                                        # valid vs invalid
      $entry{keyword}       =   ${$opts_ref}{keyword};                                                      # object to be initialized
      $entry{basevalue}     =   ${$opts_ref}{basevalue};                                                    # value w/out prefix and preferred unit
      $entry{baseunit}      =   ${$opts_ref}{baseunit};                                                     # preferred unit

      $entry{value}         =   ${$opts_ref}{value};
      $entry{dataword}      =   ${$opts_ref}{dataword};                                                     # raw data (formated human readable)
      $entry{metric}        =   ${$opts_ref}{metric};                                                       # raw composed prefix & unit
      $entry{unit}          =   ${$opts_ref}{unit};
      $entry{comment}       =   ${$opts_ref}{comment};
      my $s = keys %entry;
      my $t = 'Size of Entry';
      printf "%*s%s = %s entries\n",$i,$p,$t,$s if( debug($n));
      # overwriting only if valid
      ${$tseq_ref}{$keyword}  = \%entry if ($entry{valid} !~ m/invalid/ );
}#sub store_init


sub   compile_sequence{
      my    (   $opts_ref
            ,   $defs_ref
            ,   $tseq_ref       )   = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      printf "%*s%s()\n",$i,$p,$n if( debug($n));
      my $s = keys %{$tseq_ref};
      my $t = 'Size of Initialization';
      printf "%*s%s = %s entries\n",$i,$p,$t,$s if( debug($n));
      if  (   defined $opts{scan}    ) {                                                                    # coverage is a seperate analysis
          scan_sequence (   $opts_ref, $tseq_ref    );
      }
}#sub compile_sequence


sub   scan_sequence{
      my    (   $opts_ref
            ,   $tseq_ref       )   = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      my $c = 0;
      my $A = [ qw (baseaddress block_range databussize ) ];
      my $B = [ keys %{$tseq_ref} ];

      if ( debug($n) ) {
            printf "%*s%s()\n",$i,$p,$n;
            foreach my $item ( @{$B} ) {
                $c++;
                printf "%*s%3s %*s :: %*s\n"  ,$i,$p,$c
                                              ,13,$item
                                              ,12,${$tseq_ref}{$item}{basevalue};
            }#foreach keyword
            my %mmap =   %{${$opts_ref}{memorymap}};
            my $s = keys %{${$opts_ref}{memorymap}};
            printf "%*s%s %s\n" ,$i,$p,'Memory Map', $s;
            printf "\n";
            foreach my $addr ( keys %{${$opts_ref}{memorymap}} ) {
                printf "%*s %x :: %x\n", $i,$p,$addr, ${${$opts_ref}{memorymap}}{$addr}{addr};
                printf "%*s %x :: %s\n", $i,$p,$addr, ${${$opts_ref}{memorymap}}{$addr}{reserved};
            }#foreach reserved
      }# debugging

      $c =  0;  # Reset counter
      if ( is_subset( $A, $B) ){                                                                            # A is subset of B
          printf "%*s%s\n"  ,$i,$p,'All conditions meet for scan_sequence()';
          my $base   = ${$tseq_ref}{baseaddress}{basevalue};            # [byte]
          my $step   = ${$tseq_ref}{databussize}{basevalue};            # [byte]
          my $range  = ${$tseq_ref}{block_range}{basevalue};            # [byte]
          my $cmd    = qw ( WRITE );
          my $boundry= $base + $range;
          my $data   = impulse  ( $step );                              # WORDSIZE
          for ( my $addr = $base; $addr < $boundry; $addr += $step) {
              my $line = sprintf "%*s %08x %08x", 10,$cmd, $addr, $data;
              $c++;
              if ( defined  ${${$opts_ref}{memorymap}}{$addr}{reserved} ) {
                my $lineC = sprintf "%*s %08x %8s", 10, '', $addr, 'RESERVED';
                push @{${$opts_ref}{testsequence}}, $lineC;
                printf $proh "%4s%s\n", $c,$lineC;
                # NOTHING be done with RESERVED ADDRESSES - excluded from sequence
              } else {
                push @{${$opts_ref}{testsequence}}, $line;
                printf $proh "%4s%s\n", $c,$line;
                ${$tseq_ref}{sequence}{$addr}{addr}   = $addr;
                ${$tseq_ref}{sequence}{$addr}{data}   = $data;
              }
          }#
      }# if all informatio complete
}#sub 


sub   is_subset {                                                                                           # Set A is subset of Set B
      my    ( $A                                                                                            # Set A is a reference
            , $B    ) = @_;                                                                                 # Set B is a reference
      my $not_part = 0;
      my $found_it = 0;
      my $n = subroutine('name');
      printf "%*s%s()\n",5,'',$n       if( debug($n) );
      foreach my $elementA ( @{$A} ) {
          $found_it = 0;
          printf "%*sElement A : <%s> is subset of\n",5,'', $elementA if( debug($n) );
          foreach my $elementB ( @{$B} ) {
             #$found_it += ($elementA =~ m/$elementB/) ? $TRUE : $FALSE;                                    # PERL language breakdown on empty strings
              $found_it += ($elementA eq   $elementB ) ? $TRUE : $FALSE;
              printf "%*sElement B : <%s> %s\n",5,'',  $elementB
                                                    , ($elementA eq $elementB ) ? '+': '-'
                                                    if( debug($n) );
                                                   #, ($elementA =~ m/$elementB/) ? '+': '-';
          }# test if element a is part of Set B
          $not_part += ($found_it) ? $FALSE : $TRUE;
      }# test if ALL elements of Set A are part of Set B
      return ($not_part)? $FALSE : $TRUE;
}#sub is_subset


sub   impulse {                                                                                             # generating vectors
      my (  $size
         ,  $unit   )   = @_;   # supports bit and byte
      $unit //= 'byte';         # default and prefered value
      my $response  = 0;
      my $range     = ($unit =~ m/bit/) ? $size : $size<<3;
      for ( my $i = 0; $i < $range; $i++) {
          $response <<= 1;
          $response  += 1;
      }#
      return $response;
}#sub impulse


sub   writing_sequence{
      my    (   $opts_ref
            ,   $defs_ref       )   = @_;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      printf "%*s%s()\n",$i,$p,$n if( debug($n));
      ${$opts_ref}{seq} //= 'basic_test.seq';
      printf "%*s%s : %s\n", $i,$p, 'TestSequenceName', ${$opts_ref}{seq};
      open(my $seqh,'>:encoding(UTF-8)',${$opts_ref}{seq});
      foreach my $line ( @{${$opts_ref}{testsequence}} ) {
         printf $seqh "%s\n",$line;
      }#
      close(  $seqh );
}#sub writing_sequence

sub   check_command_line{
      my    (   $opts_ref                                                                                   # Input     Reference to %opts w/ commandline input
            ,   $defs_ref       )   = @_;

      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                                 # ${$opts_ref}{padding_pattern}

      printf "%*s%s()\n",$i,$p,subroutine('name') if( defined ${$opts_ref}{dbg} );

      if ( defined ${$opts_ref}{subs}    ) {
          printf "%*s%s :: %s\n",$i,$p,'Subroutines','list';
          foreach my $entry (@{${$opts_ref}{subs}}   ){
              printf "%*s%s\n",$i+4,$p,$entry;
          }#foreach
      }#if

      if ( defined ${$opts_ref}{keywords}    ) {
          printf "%*s%s :: %s\n",$i,$p,'Keywords','list';
          foreach my $entry (@{${$opts_ref}{keywords}}   ){
              printf "%*s%s\n",$i+4,$p,$entry;
          }#foreach
      }#if
}#sub check_command_line


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


##################################################################################################################################
# Experimental code
#


sub   open_binary_files {
      my    (   $opts_ref   )   = @_;
      $opts_ref //= \%opts;                                                         # default definition
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $f = ${$opts_ref}{open};                                                   # filename
      my $n = subroutine('name');                                                   # subroutine_name
      my $d = 'XML/[Content_Types].xml';                                            # doc directory
      my $lc= 0;
      my @xml;                                                                      # .xml file content
      my @xmle;                                                                     # XML element array
      printf "%*s%s()\n",$i,$p,$n;
      #printf "%*s%s %s\n", $i,$p,'file name', $f;
      printf "%*s%s %s is %s\n", $i,$p,'file name', $f, file_type($f);
      system "unzip $f -d XML";

      printf "\n";
      open_xlsx_file ();

      write_array_to_file(${$opts_ref}{tmp} ,'logs/parse_xlsx.log');
      write_array_to_file(${$opts_ref}{tmp2},'logs/parse_xmlf.log');
      write_array_to_file(${$opts_ref}{tmp3},'logs/parse_xmls.log');
      write_array_to_file(${$opts_ref}{tmp4},'logs/parse_xmle.log');

      printf "\n\n";
      system "find ./XML -type f | xargs zip Derivative.xlsx";
      #find . -type f | xargs zip ../Derivative.xlsx
}#sub open_binary_files


sub   open_xlsx_file {                                                             # packed document type
      my    (   $opts_ref   )   = @_;
      $opts_ref //= \%opts;                                                         # default definition
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $f = ${$opts_ref}{open};
      my $n = subroutine('name');
      my $lc= 0;
      my @xml;                                                                      # .xml file content
      my @xmle;                                                                     # XML element array
      ${$opts_ref}{tmp}     = [];                                                   # parsing xlsx doc
      ${$opts_ref}{tmp2}    = [];                                                   # parsing XML files
      ${$opts_ref}{tmp3}    = [];                                                   # parsing XML string
      ${$opts_ref}{tmp4}    = [];                                                   # parsing XML element
      printf "\n\n";
      printf "%*s%s()\n",$i,$p,$n;
      printf "%*s%s %s\n", $i,$p,'file name', $f;
      my $lm = sprintf "%*s%s %s", $i,$p,'file name', $f;                           # message
      push ( @{${$opts_ref}{tmp}} , $lm);                                           # capture message
      printf "\n";

      #system "unzip $f -d XML";

      my @ff = `find ./XML -type f`;
      my @dd = `find ./XML -mindepth 1 -type d `;

      printf "\n\n";
      printf "All directories :\n";
      push ( @{${$opts_ref}{tmp}},"\n");
      push ( @{${$opts_ref}{tmp}},"All directories :\n");
      foreach my $fn ( @dd ) {
         chomp($fn);
         printf "%*s%s\n", $i,$p,$fn  if( debug($n) );
         $lm = sprintf "%*s%s", $i,$p,$fn;                                          # directory name
         push ( @{${$opts_ref}{tmp}}, $lm);                                         # capture message
      }# list all directories

      printf "\n\n";
      printf "All files :\n";
      push ( @{${$opts_ref}{tmp}},"\n");
      push ( @{${$opts_ref}{tmp}},"All files :\n");
      foreach my $fn ( @ff ) {
         chomp($fn);
         printf "%*s%s is %s\n", $i,$p,$fn,file_type($fn);                          # list file name
         $lm = sprintf "%*s%s is %s" , $i,$p,$fn,file_type($fn);                    # file name
         push ( @{${$opts_ref}{tmp}} , $lm);                                        # capture message
      }# list all files

      push ( @{${$opts_ref}{tmp}},"\n\n");                                          # capture message
      printf "\n\n";
      ${$opts_ref}{cnt} = 0;
      foreach my $fn ( @ff ) {
         chomp($fn);
         ${$opts_ref}{cnt} ++;                                                      # loop counter
         read_xml_file ( $fn) if $fn =~ m/.xml$/xms;
         read_rels_file( $fn) if $fn =~ m/.rels$/xms;
      }# for all files of the document

      printf "\n\n";
      #system "find ./XML -type f | xargs zip Derivative.xlsx";
      #find . -type f | xargs zip ../Derivative.xlsx
}#sub open_xlsx_file


sub   read_xml_file {
      my    (   $f
            ,   $opts_ref   )   = @_;
                $opts_ref //= \%opts;                                               # default definition
      $f  //= 'XML/[Content_Types].xml';                                            # ??? what is the purpose of this ?
      my $n = subroutine('name');
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $c = ${$opts_ref}{cnt};
      my $lm= sprintf "\n\n%*s(%2s)%s %s",$i,$p,$c,$f,'FILE content :';             # log message                       FIX ME

      printf "\n\n"  if( debug($n) );
      printf "%*s%s  --\n",$i,$p,$f if( debug($n) );                                # file name
      push ( @{${$opts_ref}{tmp}},  $lm);                                           # capture message
      push ( @{${$opts_ref}{tmp2}}, $lm);
      push ( @{${$opts_ref}{tmp3}}, $lm);                                           # XML string
      push ( @{${$opts_ref}{tmp4}}, $lm);

      open (my $fh,'<:encoding(UTF-8)',"$f")
      || die " Cannot open file $f";                                                # Part of the document
      my @xml=<$fh>;                                                                # Read file into array
      close (  $fh );

      @xml = preserve_space ( @xml );                                              # preserve and compact xml string

      my $lc    = 0;
      for my $line ( @xml) {
            $lc++;
            chomp $line;                                                            # ^M is preserved
            printf "%*s%*s: %s\n",$i,$p,4,$lc,$line if( debug($n) );                # print XML array line
            $lm = sprintf "%*s%*s: %s",$i,$p,4,$lc,$line;
            push ( @{${$opts_ref}{tmp}} , $lm);                                     # teardown
            push ( @{${$opts_ref}{tmp2}}, $lm);                                     # parsing
            push ( @{${$opts_ref}{tmp3}}, $lm);                                     # experimental
      }#for
      printf "\n\n"  if( debug($n) ); 
      $lc = 0;
      for my $line ( @xml) {
            printf "%*s%*s: %s",$i,$p,4,$lc,$line  if( debug($n) );
            print_xml_string($line);
      }#
      #print_xml_string($xml[1]);
      return @xml;
}#sub read_xml_file


sub   preserve_space {
      my    (   @arr    ) = @_;
      my @xmli;                                                                     # internal xml packed array

      $xmli[0] = $arr[0];                                                           # copy xml Prolog
      if ( $#arr == 1 )  {
          $xmli[1] = $arr[1];
      } elsif ( $#arr > 1) {
          my $xml_str_tmp = join '', @arr[1..$#arr];                                # gluing the array together
          $xml_str_tmp =~ s/\x0d\x0a/&#xD;&#xA;/g;                                  # preserve CR,LF in XML string
          $xmli[1] = $xml_str_tmp;
      }#
      return @xmli;
}#sub preserve_space


sub   print_xml_string  {
      my    (   $xmls                                                               # avoid processing, keep the string
            ,   $opts_ref   )   = @_;
      $opts_ref //= \%opts;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $n = 0;                                                                    # nested level, root

         $xmls  =~ s/></>><</g;                                                     # create a sacrifice
      my @xmle  =  split (/></, $xmls);

      parse_xml_element( \@xmle,'tmp3');
      push ( @{${$opts_ref}{tmp3}}, '');                                            # Line spacer
      parse_xmle( \@xmle,'tmp5');                                                   # Experimental
      return @xmle;
}#sub print_xml_string


sub   parse_xml_element {
      my    (   $xmle_ref
            ,   $tmp
            ,   $opts_ref   )   = @_;
      $opts_ref //= \%opts;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $n = 1;
      for my $xmle ( @{$xmle_ref} ) {
          chomp ($xmle);
          #printf "%*s(%s)++\n",$i,$p,$xmle;                                        # Silenced

          #push ( @{${$opts_ref}{$tmp}}, "\n" );
          push ( @{${$opts_ref}{$tmp}},sprintf "%*s(%s)",$i,$p,$xmle);
          push ( @{${$opts_ref}{tmp2}},sprintf "%*s(%s)",$i,$p,$xmle);              # Track XML elements
          push ( @{${$opts_ref}{tmp4}},sprintf "%*s(%s)",$i,$p,$xmle);              # Parse XML elements, identification

          $n++;
          if ( $xmle =~   m{^\s*(<(?|/|\?)?)                                        # XML Start TAG begin
                            #   ([_a-zA-Z:]+)                                       # Forgot numbers and colon
                            #   ([a-zA-Z][_a-zA-Z:0-9]+)                            # XML tag name, single character tags
                                ([a-zA-Z][_a-zA-Z:0-9]*)                            # XML tag name
                              (\s(\w+=".+")?)?                                      # XML attribute, multiple attributes
                                ((?|/|\?|)? >)                                      # XML Start TAG end
                                ([^<]+)?                                            # XML elememt
                                (</\1>)?                                            # XML End TAG
                           }xms          ) {
                push( @{${$opts_ref}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAG open',$1);
                push( @{${$opts_ref}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAG name',$2);
                push( @{${$opts_ref}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML Attribut',(defined $4)?$4:'none');           # if undef no Attribute
                push( @{${$opts_ref}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAGclose',$5);
                push( @{${$opts_ref}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML Element ',(defined $6)?$6:'empty');
                push( @{${$opts_ref}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAG end ',(defined $7)?$7:'skipped');
          }# match
          $n--;
      }#for
}#sub parse_xml_element


sub   parse_xmle {
      my    (   $xmle_ref                                                           # XML element array
            ,   $tmp
            ,   $opts_ref   )   = @_;
      $opts_ref //= \%opts;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $n = 0;                                                                    # level of nested XML element
      my $t;                                                                        # text
      my $f = "%*s%s :: %s";                                                        # format
      my $msg;                                                                      # formatted message
      my @nxmle;
      push( @{${$opts_ref}{$tmp}}, '' );                                            # vertical spacer
      for my $e ( @{$xmle_ref} ) {                                                  # foreach element
          chomp $e;
          switch ( $e ) {
              case  m{  $XML_PRO  }xms { $t = 'XML Prolog'; }
              case  m{  $XML_NEC  }xms { $t = 'Nested XML-e closing tag';}
              case  m{  $XMLE_ST  }xms { $t = 'Self terminated XML element';}
              case  m{  $XMLE     }xms { $t = 'Regular XML element';}
              case  m{  $XML_NEO  }xms { $t = 'Nested XML-e opening tag';}
              else                     { $t = 'XMLE not covered yet'; }
          }#switch
          $n-- if $t =~ m/closing/;
          $m = sprintf $f,$i+$n*4,$p,$e,$t;
          push( @{${$opts_ref}{$tmp}}, $msg );
          $n++ if $t =~ m/opening/;
      }#for
}#sub parse_xmle


sub   write_array_to_file {
      my    (   $a_ref                                                                                # tmp arry buffer
            ,   $file_name
            ,   $opts_ref       )   = @_;
                $opts_ref       //= \%opts;
                $file_name      //= 'tmp.txt';
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                             # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      printf "%*s%s()\n",$i,$p,$n if( debug($n));
      printf "%*s%s : %s\n", $i,$p, 'TestSequenceName', $file_name;
      open(my $fh,'>:encoding(UTF-8)',$file_name);
      foreach my $line ( @{$a_ref} ) {
         printf $fh "%s\n",$line;
      }#
      close( $fh );
}#sub write_arry


sub   map_subdirectory   {
      my    (   $opts_ref   )   = @_;
                $opts_ref   //= \%opts;
      my $i = ${$opts_ref}{indent};
      my $p = ${$opts_ref}{indent_pattern};                                                             # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      my $d = ${$opts_ref}{map};                                                                        # sub-directory path
      printf "%*s%s()\n",$i,$p,$n               if( debug($n));
      printf "%*s%s%s\n",$i,$p,'map : ',$d      if( debug($n));
}#sub map_subdirectory


sub   map_subroutines   {
      my    (   $opts_ref   )   = @_;
                $opts_ref               //= \%opts;                                                     # default setting

              ${$opts_ref}{maps}        //= 'tsg.pl';                                                   # self reporting
      my $i = ${$opts_ref}{indent};                                                                     # Indentation from the left edge
      my $p = ${$opts_ref}{indent_pattern};                                                             # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      my $s = ${$opts_ref}{maps};                                                                    # script name
      my @l;                                                                                            # @lines
      my @o;                                                                                            # @list
      printf "%*s%s()\n",$i,$p,$n               if( debug($n));
      printf "%*s%s%s\n",$i,$p,'map : ',$s      if( debug($n));
      if ( -e $s )  {
            read_textfile( $s    , \@l );
            @o = picklist( '^sub \s* (\w+)', \@l );
            view_list( \@o, 'List of subroutines');
      } else {
            my $msg = sprintf "WARNING :: Script %s not found !!", $s;
            printf "%*s%s\n\n", $i,$p,$msg;
            exit 1;
      }
}#sub map_subroutines


sub   picklist {
      my (   $pattern
         ,   $aref      )    = @_;
      my @target_list;
      foreach my $line (@{$aref}) {
         if ( $line =~ m/$pattern/xms ) {
             push (@target_list, $1);
         } else {
             #WARN
         }
      }#foreach
      return @target_list;
}#sub picklist


sub   file_type {
      my    (   $file_name  )   = @_;
      return    ( -T $file_name )? 'text   '
            :   ( -B $file_name )? 'binary ' : 'unknown';
}#sub file_type

#
