#!/tools/sw/perl/bin/perl -w

# Author    Lutz Filor
# Phone     408 807 6915
#
# Purpose   Analysis AHB-tracker trace files, bandwidth, latency, transaction profile
#
# Revision  VERSION     DATE            Description
# ================================================================================================
# History   1.01.01     09/10/2018      Parsing trace files
#           1.01.02     09/14/2018      First   report file, build data structure first check in
#                                       Min, Max, Average
#           1.01.03 -   09/21/2018      Refactor parsing, analysis, reporting second check in
#                                       split -> REGEX, Header parsing, Parsing.log
#           1.01.04 -   09/24/2018      Add and fix payload analysis, timebase, beat unaligned
#                                       Next ADDR transfer report before concurrent DATA transfer
#           1.01.05 -   09/25/2018      Add transfer analysis, transfer, beat, WAIT states, IDLE,
#                                       and concealed ADDR transfers
#           1.01.06     09/26/2018      Refactor latency analysis
#                                       Refactoring latency_analysis()
#                                       Accounting  1st DATA, Last Data latency
#       3   1.01.07     09/27/2018      Update analysis report
#                                       Debugging   latency analysis()
#                                       Refactoring bandwidth analysis()
#       4   1.01.08     09/28/2018      Document transfer pointer list/data structure
#                                       Refactor    build command/data object()
#                                       Create      elaborate_tracefile()
#       5   1.02.01     10/01/2018      Add Command line interface
#                                       Revise      Analysis Report 
#       6   1.02.02     10/01/2018      Refactor    transaction_analysis(),
#                                       refactor    report_transaction()
#       7   1.02.03     10/02/2018      Develop     timebased windowing trace input file
#           1.02.04     10/03/2018      Debugging   timebased windowing trace input file
#                                                   add default total trace
#           1.02.05     10/04/2018      Insert new  commandline control, change parameter list
#                                       Refactor    elaborate_tracefile()
#                                       Refactor    initialize_payload_analysis(), reformat logs
#                                       Refactor    bandwidth_analysis()
#           1.02.06     10/05/2018      Refactor    transaction_analysis()
#                                       Refactor    transfer_analysis()
#                                       Refactor    analysis_report()
#                                       Remove      protocol_trace_analysis()
#                                       Remove      test_AHB_hash() ->  transaction_analysis()
#                                       Remove      deprecated data structure %ahb_anal
#                                       Remove      deprecated data structure %ahb_band
#                                       Remove      deprecated data structure %ahb_latency
#       8   1.03.01     10/08/2018      Fix buffer stop in latency_analysis(),
#                                                          bandwidth_analysis()
#       9   1.03.02     10/08/2018      Command line interpretation, directory globbing
#           1.03.03     10/10/2018      Control flow for multiple interation 
#           1.03.04     10/11/2018      Debug       avoid global variable access from subroutine()
#                                       Refactor    trace information hash
#                                       Refactor    pointer structure, remove hard pointer access
#                                                   Unified hash for all transfer pointer
#                       10/12/2018      Debugging   removing hard pointer access
#                                       Transaction Analysis windowed from <START> - <STOP>
#       10  1.04.01     10/15/2018      Improve     Maintenance
#                                       Insert buffered terminal output feature, for trace correlation
#                                       Insert buffered terminal output feature, for line correlation
#                                       Insert VERSION number into all log files
#                                       Capture Command line in progress log
#                                       Bug     Implicite analyze window from previous analysis
#       11  1.04.02     10/24/2018      Implement   debug feature
#                                       Sicence execution
#                                       Selective logging
#       12  1.04.03                     
#
# trace path /mnt/ussjf-asic2/workarea1/lkamired/niue1z1_tmp/lkamired/wa_performance/SIM/top      

my $VERSION = "1.04.02";

use strict;
use warnings;

use feature 'state';                                                                # Static local variables

use Readonly;
use Getopt::Long;
use File::Path      qw /make_path/;                                                 # Create directories
use File::Basename;                                                                 # Handle absolute file names
use Cwd             qw /abs_path
                        getcwd
                        cwd     /;                                                  # Current working directory

#use Padwalker;                                                                     # Not available/installed
#use Package::Stash;                                                                # available
#use Pod::Usage;                                                                    # available
#use DateTime;                                                                      # Not used

sub report;
sub parse_header;
sub calculate_payload;
sub elaborate_tracefile;
sub CreateLoggingPath;

Readonly my $DIGITS => qr { \d+ (?: [.] \d*)? | [.] \d+ }xms;
Readonly my $SIGN   => qr { [+-] }xms;
Readonly my $EXPO   => qr { [eE] $SIGN? \d+ }xms;
Readonly my $FLOAT  => qr { ($SIGN?) ($DIGITS) ($EXPO?) }xms;

my %defines;                                                                        # Command line defines
my %opts    =   (   dir_pattern         =>  'ahbfab',                               # Default name pattern for AHB trace points            <== !! Depending on Environment
                    file_pattern        =>  'ahb_beat.log',                         # Default name pattern for AHB traces                  <== !! Depending on Environment
                    progress_log        =>  'progress.log',                         # log     progress phases of program                    !! Can't be turned off, aka run.log
                    error_log           =>  'error.log',                            # log     dedicated parsing errors,                     !! Can't be turned off
                    trace_default       =>  'trace.log',                            # Default logname for logging input trace files
                    parse_default       =>  'parser.log',                           # Default logname for parsing input trace file
                    build_default       =>  'build.log',                            # Default logname for building trace transaction/transfer list
                    transfer_default    =>  'transfer.log',                         # Default logname for transfers, type (IDLE,ADDR,DATA,BUSY) and duration
                    transferlist_default=>  'pointer.log',                          # Default logname for transfer list
                    payload_default     =>  'payload.log',                          # Default logname for payload analysis initialize_payload_analysis()
                    transaction_default =>  'transaction.log',                      # Default logname for transaction analysis, by direction, type and size
                    transaction2_default=>  'transaction2.log',                     # Default logname for transactio2 analysis, by direction, type and size via pointer
                    latency_default     =>  'latency.log',                          # Default logname for latency     analysis, ( from, to ) window
                    bandwidth_default   =>  'bandwidth.log',                        # Default logname for bandwidth   analysis, ( from, to ) window
                    window_default      =>  'window.log',                           # Default logname for determine the trace window within the trace file
                    address_default     =>  'address.log',                          # Default logname for address coverage analysis, accumulative
                    report_default      =>  'analysis.rpt',                         # Default logname for analysis report
                    coverage_default    =>  'coverage.rpt',                         # Default logname for coverage report
                    errlog_default      =>  'error.log',                            # Default logname for reporting on input trace file errors
                    owner               =>  'Lutz Filor',                           # Maintainer
                    call                =>  join (' ', @ARGV),                      # Capture command line
                    program             =>  $0,                                     # Script    Name
                    version             =>  $VERSION,                               # Script    Version
                    report_path_default =>  'ahb_tracker_analysis',                 # Default report path root
                    log_path_default    =>  'logs',                                 # Default logging path appendix for each trace
                   #report_dir          =>  'run',                                  # Default subdir  for analysis reports                <== !! Default is a sub structure 
                   #trace_dir           =>  [],                                     # Temporary List  of  files in directory 
                   #trace_dirs          =>  [],                                     # Temporary List  of  directories  w/ files in directories
                   #trace_file          =>  [],                                     # Temporary List  of  files on command line
                );

my %transfer_pointer;                                                               # Unified pointer state of AHB transfer list                            
my @traces;                                                                         # Trace file list
my @trace_dir;                                                                      #
my @trace_dirs;                                                                     #                                                               to be deprecated
my %Trace;                                                                          # Trace  file header information
my %ahb_transfer_new;                                                               #        AHB transfer    analysis new
my %ahb_latency_new;                                                                #        AHB latency     analysis new/refactored
my %ahb_bandwidth_new;                                                              #        AHB bandwidth   analysis new/refactored
my %ahb_transaction_new;                                                            #        AHB transaction analysis new/refactored
my %ahb_transaction2_new;                                                           #        AHB transaction analysis new/refactored
my %ahb_address_new;                                                                #        AHB address     coverage   analysis
my %AHB_hash;                                                                       # LEGACY    Trace file transfer information                     to be deprecated
                                                                                    # access AHB command transfers via time stamp

my $error_log       = 'error.log';                                                  # log    trace file reporting errors
#################################################################################################################################

#|             6127040 ps|             6132066 ps|RD-DATA   | 84D5214C |  3/ 4 | -- | 00000000 |  OKAY  | ---- | ------- | - | ---------- |
#|             6132066 ps|             6137066 ps|WR-NONSEQ | 84D52332 | ----- | 16 | -------- |  ----  |INCR16|    1    | 8 |           0|
#|             6132066 ps|             6137066 ps|RD-DATA   | 84D52150 |  1/ 4 | -- | 00000000 |  OKAY  | ---- | ------- | - | ---------- |
#|             6137066 ps|             6142066 ps|WR-DATA   | 84D52332 |  2/16 | -- | ..A3.... |  OKAY  | ---- | ------- | - | ---------- |
#                                                                         ....
#|             6206870 ps|             6211870 ps|WR-DATA   | 84D52340 | 16/16 | -- | ......EE |  OKAY  | ---- | ------- | - | ---------- |
#|             6211870 ps|             6216946 ps|WR-DATA   | 84D52341 | 17/16 | -- | ....48.. |  OKAY  | ---- | ------- | - | ---------- |
#|             6216946 ps|             6221846 ps|RD-NONSEQ | 84D52248 | ----- | 16 | -------- |  ----  |INCR16|    4    | 4 |           0|
#|             6221846 ps|             6226746 ps|RD-DATA   | 84D52248 |  1/16 | -- | 00000000 |  OKAY  | ---- | ------- | - | ---------- |

#################################################################################################################################

#
# main entry
#
#=================================================================================================================================
my   ($s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst) = localtime;
open (my $proh, ">$opts{progress_log}")  ||  die " Cannot create log $opts{progress_log}";   # Open Progress log file

GetOptions  (   'help|h|?'              =>  \&help,                                 # Usage Information
                #'address_coverage|ac'  =>  \&addr_cov,                             # --        testing address coverage
                'address_coverage|ac'   =>  \$opts{coverage},                       # --        testing address coverage
                'debug'                 =>  \$opts{debug},                          # Turn      ON LOGGING
                'info'                  =>  \$opts{info},                           # Report    trace file information => window (Open, Close) 
                'from|s=i'              =>  \$opts{START},                          # Specify   Start time, overwrite default
                'until|e=i'             =>  \$opts{STOP},                           # Specify   End   time, overwrite default
                'report_dir|o=s'        =>  \$opts{report_dir},                     # Overwrite Output      default name of report directory
                'trace_dir|dir|d=s'     =>  \$opts{trace_dir},                      # Specify   directory w/ trace files
                'trace|t|f=s'           =>  \$opts{trace_file},                     # Specify   trace file
                'trace_dirs=s'          =>  \$opts{trace_dirs},                     # Specify   all project trace files
                'debug_trace|dbg1'      =>  \$opts{debug_trace},                    # Debug buffered STDERR file correlation, START here
                'debug_line|dbg2'       =>  \$opts{debug_line},                     # Debug buffered STDERR line correlation, Tbd not implemented
                'debug_logs|dbg3'       =>  \$opts{debug_logs},                     # Debug writeout logfiles for all steps, deep debug
                'logging|log=s@'        =>  \$opts{logs},                           # Turn      ON selective LOGGING
                'defines=s'             =>  \%defines,
            );                                                                      # Command Line Processor

DebugControl(   \%opts  );                                                          # Tuning debugging

if ((   ( defined $opts{trace_file}                         )
   ||   ( defined $opts{trace_file} && defined $opts{info}  )
   ||   ( defined $opts{trace_dir}                          )
   ||   ( defined $opts{trace_dirs}                         ))   
   &&   (!defined $opts{coverage}                           )   )                   # coverage is a seperate analysis
{   # 
    # Parsing   AHB trace file
    # Building   2D directed graph/list of AHB (ADDR, DATA) transfers
    #
    if ( defined $opts{debug_trace} ) {
        printf "\n";
        printf " ... set up bandwidth analysis ...\n";
    }#debugging

    check_environment           (   \%opts                                          # Input     Command Line Options
                                ,   \@traces                                        # Output    List of trace files w/ information
                                ,   \@trace_dirs    );                              #           Deprecated aka not used

    analyze_tracefiles          (   \%opts                                          # Input     Command Line Options
                                ,   \@traces                                        #           List of trace files w/ information
                                ,   \%Trace                                         #           Hash of trace header information        from global to local
                                ,   \%transfer_pointer  );                          #           Hash of pointer of AHB transfer list    from global to local
                               
    printf " ... bandwidth analysis ... done\n" if ( defined $opts{debug_trace} );
    printf "\n";                                                                    # None maskable spacer to the next command line

    exit 0; # Main Exit
} elsif (      defined $opts{coverage}      )                                       # Testing   address coverage
{
    printf "\n";
    printf " ... set up coverage analysis ...\n";
    addr_cov    (   \%opts                                                          # Input     Command Line Options
                ,   \@traces                                                        #           List of trace files
                ,   \@trace_dirs                                                    #           List of List w/ trace files
                ,   \%Trace                                                         #           Trace header information
                ,   \%transfer_pointer                                              #           Hash of pointer into AHB transfer list 
                ,   \%ahb_address_new       );                                      #           Hash of address coverage analysis
    printf " ... set up coverage analysis ... done\n";
    exit 0;
} else {
    printf "\n";
    printf "%s Version %s\n", $0, $VERSION;
    printf "    Type <--help> for more information\n", $0;
    printf "\n";

   # 
   # Debugging negative command line condition
   #
   #printf "%*s%s %s\n",10,'','trace_file   ',( defined $opts{trace_file})?'    defined':'not defined'; 
   #printf "%*s%s %s\n",10,'','trace_dirs   ',( defined $opts{trace_dirs})?'    defined':'not defined'; 
   #printf "%*s%s %s\n",10,'','trace_dir    ',( defined $opts{trace_dir} )?'    defined':'not defined'; 
   #printf "%*s%s %s\n",10,'','information  ',( defined $opts{info}      )?'    defined':'not defined'; 
    exit 0;

}


if ( defined $opts{info} ) {
    report_info                 (  \%Trace                                          # Trace   information from file header
                                ,  \%transfer_pointer                               # Pointer information
                                ,  \%opts               );                          # Command line options
    # exit;                                                                         # Exit    after info report
}#

#=================================================================================================================================
# End of main() 

#
# Subroutine implementation
#
#=================================================================================================================================

sub   elaborate_tracefile {
      my ( $trace_header_ref                                                        # Trace information
         , $ptr_ref                                                                 # transaction trace pointer
         , $opts_ref      ) = @_;                                                   # command line arguments

      my $parh;                                                                     # file handle parsing
      my $buih;                                                                     # file handle buiding
      my $tracefile   = ${$opts_ref}{trace_file};
      my $parselog    = ${$opts_ref}{parse};
      my $buildlog    = ${$opts_ref}{build};
      my $transaction = 0;

      printf $proh "\n";
      if ( defined ${$opts_ref}{debug_trace} ) {
            printf STDERR" ... %s\n", ${$opts_ref}{trace_file};
      }# Enable STDERR output correlation with systen errors

      printf $proh " ... opening TraceFile      %s\n", ${$opts_ref}{trace_file};    # $filename;
      printf $proh "     reading TraceFile\n";

      open ( my $TRACE, "<$tracefile") || die " Can not open input $tracefile";     # Open trace file
      my @LINES = <$TRACE>;                                                         # Slurp trace file into array
      my $eof   = $.;                                                               # Last line number, w/ File record separator <\n>
      close ( $TRACE );                                                             # close trace file asap 

      printf $proh " ... closing TraceFile\n";

      if ( ${$opts_ref}{logging_parse} ) {
        printf $proh "     opening ParserLogFile  %s\n", $parselog;
        open ( $parh, ">$parselog")|| die " Can not create log $parselog";
        printf $parh  "%*s%*s: %s\n\n", 3,'', -8,'Trace',$tracefile;
      }#logging

      if ( ${$opts_ref}{logging_build} ) {
        printf $proh "     opening BuildLogFile   %s\n", $buildlog;
        open ( $buih, ">$buildlog")|| die " Can not create log $buildlog";
        printf $buih  "%*s%*s: %s\n\n", 5,'',-15,'Trace',$tracefile;
      }#logging

      for (my $i = 0; $i < $eof; $i++)
      {
          my $row      = $LINES[$i];                                                # next trace file line read
          my @COL;                                                                  # parsed/extracted line columns 
          chomp $row;
         
          if ( $i <=  9) {
              if ( ${$opts_ref}{logging_build} ) {
                printf $buih  " ... HEADER decoding\n" if ($i == 0);
              }#logging
              parse_header      (   $opts_ref                                       # Input     Command line reference/control
                                ,   $row                                            # Input     trace file row/line
                                ,   $i                                              #           row/line index/count
                                ,   $parh                                           #           file handle parse log  
                                ,   $trace_header_ref    );                         # Output    extracted trace file header information
              if ( ${$opts_ref}{logging_build} ) {
                    printf $buih  "     line :: %5s :: %s\n", $i, $row;
                    printf $buih  " ... HEADER decoding done\n" if ($i ==  9);
              }#logging
              printf $proh  "     HEADER decoding done\n" if ($i ==  9);
          }
          if ( $i >= 10) {
              if ( ${$opts_ref}{logging_build} ) {
                    printf $buih  " ... TABLE  decoding ... \n" if ($i == 10);
                    printf $buih  "     line :: %5s :: %s\n", $i, $row;
              }#logging
      
              parse_body        (   $opts_ref                                       # Input     Command line reference/control
                                ,   $row                                            # Input     trace file row/line
                                ,   $parh                                           #           file handle parse log  
                                ,   \@COL       );                                  # Output    extracted column data of transfer table rows
      
              if ( $COL[4] =~ /NONSEQ/ ) {                                          # PHASE Address
      
                  $AHB_hash{$COL[0]}                                                # hash of AHB command, w/ command ASSERT time as access keys
                  = build_command_obj   (   $opts_ref                               # Input     Command line reference/control
                                        ,   \@COL                                   # Input     addr transfers/AHB command objects, in double ptr list V.01.01.08
                                        ,   $ptr_ref                                #           Unified pointer reference V.01.03.04, consecutive analysis
                                        ,   $buih     );                            #           BuildLog file handle              
              }# NONSEQ aka address phase or command
      
              if ( $COL[4] =~ /DATA|BUSY/ ) {                                       # PHASE Data
                 
                  build_data_obj        (   $opts_ref                               # Input     Command line reference/control
                                        ,   \@COL                                   # Input     data transfers --> via AHB address/cmd transfers
                                        ,   $ptr_ref                                #           Unified pointer reference V.01.03.04, consecutive analysis
                                        ,   $buih       );                          #           file handle building log
              }# Data phase or Data
          }# process trace table $i >= 10
      }# for AHB trace tracker
      
      if ( ${$opts_ref}{logging_build} ) {
        printf $buih  " ... TABLE  decoding done\n";
        printf $proh  "     closing BuildLogFile   %s\n", $buildlog;
        close( $buih );
      }#logging
      if ( ${$opts_ref}{logging_parse} ) {
        close( $parh );
        printf $proh  "     closing ParserLogFile  %s\n", $parselog;
      }#logging
      printf $proh  "     TABLE  decoding done\n";
      printf $proh  " ... elaborate trace file done\n";
}#sub elaborate_tracefile


sub parse_header{
    my  (   $opts_ref                                                               # Input     Command line control
        ,   $row                                                                    # Input     row Tables have rows and columns
        ,   $lc                                                                     #           row/line count
        ,   $parh                                                                   #           file handle to parse log
        ,   $trace_header_ref  ) = @_;                                              # Output    extracted trace file header info

    #
    # Instance: uvm_test_top.top_env_i.ahbfab_env_i.mvc_ahb_mst_5_env_i.logger_handle_ahb
    #

    if ($lc == 0) {
        if ( $row =~ /^Instance:\s+([a-z0-9_.]+)/x ) {

            if ( ${$opts_ref}{logging_parse} ) {
                printf $parh "   Picked  : %s :: Header\n", $row;
                printf $parh "             Instance: %s\n", $1;
            }#logging
            ${$trace_header_ref}{tracefile}    =  $1;                               # extract trace filename
        } else {
            if ( ${$opts_ref}{logging_parse} ) {
                printf $parh "   Skipped : %s\n", $row;
            }#logging
        }
    }# parse first line

    #
    # AHB Clk Cycle = 5 ns; AHB Clk Frequency = 200.00 MHz; Data bus width = 32 bits
    #

    elsif ($lc == 1) {
        if ( $row =~ m{  ^(\w+)[ ]Clk[ ]Cycle    [ ]=[ ]($FLOAT)[ ] (ns|ps)         # <== Add Time base
                      ;[ ](\w+)[ ]Clk[ ]Frequency[ ]=[ ]($FLOAT)[ ](MHz|GHz)        # <== Add Frequency base
                      ;[ ] Data[ ]bus[ ]width    [ ]=[ ]  (\d+) [ ]   bits          # increase readability w/ x-modifier
                      }x ) 
        {
            if ( ${$opts_ref}{logging_parse} ) {
                printf $parh "   Picked  : %s\n", $row;
                printf $parh "%*s%s Clk Cycle = %s %s; %s Clk Frequency = %3.2f %s; Data bus width = %s bits\n"
                             ,13,'',$1, $2, $6, $7, $8, $12, $13;
            }#logging
            ${$trace_header_ref}{protocol}     =  $1;               # (AHB)
            ${$trace_header_ref}{period}       =  $2;               # (float)
            ${$trace_header_ref}{timebase}     =  $6;               # (ns|ps)
            ${$trace_header_ref}{redundant}    =  $7;               # (AHB)
            ${$trace_header_ref}{frequency}    =  $8;               # (float)
            ${$trace_header_ref}{freqbase}     = $12;               # (MHz|GHz)
            ${$trace_header_ref}{databus}      = $13;               # bit width
        }# regex
        else {
            $row =~ m{  ^(\w+)[ ]Clk[ ]Cycle    [ ]=[ ]($FLOAT)[ ] (ns|ps)
                     ;[ ](\w+)[ ]Clk[ ]Frequency[ ]=[ ]($FLOAT)[ ](MHz|GHz)
                     ;[ ] Data[ ]bus[ ]width    [ ]=[ ]  (\d+) [ ]   bits
                     }x ;
            if ( ${$opts_ref}{logging_parse} ) {
                printf $parh "   Skipped : %s\n", $row;
                printf $parh "%*s%s Clk Cycle = %s %s; %s Clk Frequency = %3.2f %s; Data bus width = %s bits\n"
                             ,13,'',$1, $2, $6, $7, $8, $12, $13;
                printf $parh "       \$1 : %s\n", $1;               # Protocol Period    (AHB)
                printf $parh "       \$2 : %s\n", $2;               #          FLOAT
                printf $parh "       \$3 : %s\n", $3;               #          Sign
                printf $parh "       \$4 : %s\n", $4;               #          Digits
                printf $parh "       \$5 : %s\n", $5;               #          Exponent
                printf $parh "       \$6 : %s\n", $6;               #          Timebase
                printf $parh "       \$7 : %s\n", $7;               # Protocol Frequency (AHB)
                printf $parh "       \$8 : %s\n", $8;               #          FLOAT
                printf $parh "       \$9 : %s\n", $9;               #          SIGN
                printf $parh "       \$10: %s\n", $10;              #          DIGITS
                printf $parh "       \$11: %s\n", $11;              #          Exponent
                printf $parh "       \$12: %s\n", $12;              #          Exponent
                printf $parh "       \$13: %s\n", $13;              # Databus  Width     (bit)        
            }#logging
        }#parse a second time
    }# parse second line
    else {
        printf $parh "   Skipped : %s\n", $row if ( ${$opts_ref}{logging_parse} );  # logging
    }#skipped lines or disregarded
}#sub parse_header

sub parse_body{
    my  (   $opts_ref                                                               # Input     Command line control
        ,   $row                                                                    # input     row/line from trace file
        ,   $parh                                                                   #           file handle to parse log
        ,   $a_ref   ) = @_;                                                        # output    extracted trace information

    # The commented code documents a failing regex and how to improve the parsing code, control and extract
    #if ( $LINES[$i] =~ m{\A                    # From  start of line beginning with <|>
    #if ( $row =~ m{#\A                         # From  start of line beginning with <|>
    #
    #              |\s+(\d+) ns                 # Column  2: Sample time HREADY Assert Time 
    #              |(\w+)\s+                    # Column  3: PHASE
    #              |\s([A-F0-9]{8})\s+          # Column  4: Address 32bit exact 8 Hex
    #              |\s([0-9\/\- ]+)             # Column  5: Beat number, extract string w/ subset char
    #              |\s([0-9-]+)                 # Column  6: LEN/Length, extract string w/ char subset
    #              |\s([A-F0-9\-\.])            # Column  7: DATA, text string       !! Not data
    #              |\s([A-F0-9\-)\s+            # Column  8: RESP/Response
    #              |(\w+)                       # Column  9: Burst Type SINGLE, WRAP4, INCR8 .. WRAP16
    #              |\s([0-9\-])\s               # Column 10: Burst Size, text string !! Not data
    #              |\s([A-F0-9]{1})             # Column 11: HPROT, Hex number
    #              |\s+([0-9\-]+)\s*|           # Column 12: HSEL, Slave index text string !! Not data
    #              \z                           # Until   end of line ending EOS                                      Shall match \A usage
    #
    #COL                     1                       2          3          4       5    6          7        8      9        10  11           12
    #|              620521 ns|              620531 ns|WR-NONSEQ | 3FF115E7 | ----- |  8 | -------- |  ----  |WRAP8 |    1    | 3 |           0|
    #|              625571 ns|              625581 ns|WR-NONSEQ | 3FF114F0 | ----- |  ? | -------- |  ----  |INCR  |    2    | 8 |           0|
    #|             6026708 ps|             6031684 ps|WR-NONSEQ | 84D522B8 | ----- | 16 | -------- |  ----  |INCR16|    4    | B |           0|
    if ( $row =~ m{^[|]\s+  (\d+)            [ ]  (ns|ps)   # Column  1: Assert time SEQ Assert Time                         <== Parsing Extention timebase
                    [|]\s+  (\d+)            [ ]  (ns|ps)   # Column  2: Sample time HREADY Assert Time                      <== Parsing Extention timebase
                    [|]     ([A-Z-]+)        [ ]+           # Column  3: PHASE
                    [|]\s   ([A-F0-9]{8})    [ ]+           # Column  4: Address 32bit exact 8 Hex literals
                    [|]\s   ([0-9/ ?-]{5})   [ ]            # Column  5: Beat number, extract string w/ char subset          <== Parsing Error [0-9\/\- ] class subset 
                    [|]\s+  ([0-9-?]+)       [ ]            # Column  6: LEN/Length , extract string w/ char subset          <== Parsing Error, \s+, missing ?
                    [|]\s   ([A-F0-9\-\.]{8})[ ]            # Column  7: DATA, text string       !! Not data
                    [|]\s+  ([\-A-Z]+)       [ ]+           # Column  8: RESP/Response
                    [|]\s*  ([-A-Z0-9]+)     [ ]*           # Column  9: Burst Type SINGLE, WRAP4, INCR8 .. WRAP16, ' ---- '
                    [|]\s+  ([0-9\-]+)       [ ]+           # Column 10: Burst Size, text string !! Not data
                    [|]\s   ([-A-F0-9]{1})   [ ]            # Column 11: HPROT, Hex number
                    [|]\s+  ([0-9\-]+)\s*    [|]            # Column 12: HSEL, Slave index text string !! Not data
                  }xmsi                                     #        Allow comment, multi line (^,$), New line (.), case insensitive
       ) {                                                  # Parenterize correctly the matching condition
            push   $a_ref, ( $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14 );       # Index no longer match the columns

            if ( ${$opts_ref}{logging_parse} ) {
                printf $parh "   Picked  : %s\n", $row;
                printf $parh "%*s"          , 13, '';                                    #                  Pre timebase tracking
                printf $parh "|%20s %s"     , $a_ref->[ 0],$a_ref->[ 1];                 #$1 Assert time;            $a_ref->[ 0]
                printf $parh "|%20s %s"     , $a_ref->[ 2],$a_ref->[ 3];                 #   Complettime             $a_ref->[ 1]
                printf $parh "|%-10s"       , $a_ref->[ 4];                              #Transfer                   $a_ref->[ 2]
                printf $parh "| %-8s "      , $a_ref->[ 5];                              #ADDR                       $a_ref->[ 3]
                printf $parh "| %5s "       , $a_ref->[ 6];                              #BEAT                       $a_ref->[ 4]
                printf $parh "| %2s "       , $a_ref->[ 7];                              #LEN                        $a_ref->[ 5]
                printf $parh "| %8s "       , $a_ref->[ 8];                              #DATA                       $a_ref->[ 6]  
                printf $parh "|%6s  "       , $a_ref->[ 9];                              #RESP                       $a_ref->[ 7]
                if ( $a_ref->[10] =~ m/[-]/){ printf $parh "| %s "    , $a_ref->[10];    #BURST TYPE                 $a_ref->[ 8]
                } else {                      printf $parh "|%-6s"    , $a_ref->[10]; }  #BURST TYPE                 $a_ref->[ 8]
                if ( $a_ref->[11] =~ m/[-]/){ printf $parh "| %7s "   , $a_ref->[11];    #BURST SIZE                 $a_ref->[ 9]
                } else {                      printf $parh "| %4s    ", $a_ref->[11]; }  #BURST SIZE                 $a_ref->[ 9]
                printf $parh "|%2s "        , $a_ref->[12];                              #HPROT                      $a_ref->[10]
                if ( $a_ref->[13] =~ m/[-]/){ printf $parh "| %s |\n" , $a_ref->[13];    #HSEL                       $a_ref->[11]
                } else {                      printf $parh "|%12s|\n" , $a_ref->[13]; }  #HSEL                       $a_ref->[11]
            }#logging
    } else {
           #
           # Debug code, catch the failure and parse again
           #
           $row =~ m{^[|]\s+(\d+)[ ](ns|ps)
                      [|]\s+(\d+)[ ](ns|ps)
                      [|]([A-Z-]+)          [ ]+
                      [|]\s([A-F0-9]{8})    [ ]+
                      [|]\s([0-9/ ?-]{5})   [ ]   # Column  5: Beat# 5 characters [? /0-9]
                      [|]\s+([0-9-?]+)      [ ]
                      [|]\s([A-F0-9\-\.]{8})[ ]
                      [|]\s+([\-A-Z]+)      [ ]+
                      [|]\s*([-A-Z0-9]+)    [ ]*  # Column  9: Burst Type SINGLE, WRAP4, INCR8 .. WRAP16, ' ---- '
                      [|]\s+([0-9\-]+)      [ ]+  # Column 10: Burst Size, text string !! Not data
                      [|]\s([-A-F0-9]{1})   [ ]   # Column 11: HPROT, Hex number
                      [|]\s+([0-9\-]+)\s*   [|] 

                    }ixms;
            if ( ${$opts_ref}{logging_parse} ) {
                printf $parh "   Skipped : %s\n", $row;
                printf $parh "       \$1 : %s\n", $1;
                printf $parh "       \$2 : %s\n", $2;
                printf $parh "       \$3 : %s\n", $3;
                printf $parh "       \$4 : %s\n", $4;
                printf $parh "       \$5 : %s\n", $5;
                printf $parh "       \$6 : %s\n", $6;
                printf $parh "       \$7 : %s\n", $7;
                printf $parh "       \$8 : %s\n", $8;
                printf $parh "       \$9 : %s\n", $9;
                printf $parh "       \$10: %s\n", $10;
                printf $parh "       \$11: %s\n", $11;             
                printf $parh "       \$12: %s\n", $12;             
                printf $parh "       \$13: %s\n", $13;             
                printf $parh "       \$14: %s\n", $14;
            }#logging
    }# tracefile parser
}#sub parse_body


sub build_command_obj {
    my  (   $opts_ref                                                                               # Input     Command line reference/control
        ,   $COL                                                                                    # Input     column array w/ parsed trace data
        ,   $ptr_ref                                                                                #           Pointer information into trace transfer list
        ,   $buih   ) = @_;                                                                         #           file handle to building log

    state $first_cmd   = 1;                                                                         # Exception handling for first command transaction

    my %command;                                                                                    # Create new cmd transfer obj:186
    my $ptr_cur_cmd = \%command;                                                                    # Pointer to command object/transaction

    if( ${$ptr_ref}{adr}{initialize} )  {                                                           # Set state variable
        $first_cmd                          =   1;
        ${$ptr_ref}{adr}{initialize}        =   0;
    }#if initialize;

    #=============================================================================================================
    #
    #   ----> ptr_fst_cmd           %AHB_hash
    #   ----> FIRST
    #                                                             ----------|
    #                                                             |         |
    #                                                             |         V                                                                 ptr_lst_data
    #                                            prev  ^          |   | ptr_fst_data                                                        | ptr_pre_data
    #                                                  |          |   |                                                                     |
    #                                                  |          |   V                                                                     V  
    #                             -------------------------       |
    #   ----> ptr_pen_cmd         |  previous cmd object  |       |
    #   ----> ANTEPENULTIMATE     |-----------------------|       |
    #                             |                       |     --------------------     --------------------     --------------------     --------------------
    #                             |                       |     | prev             |<----| prev             |<----| prev             |<----| prev             |
    #                             |                       |     |------------------|     |------------------|     |------------------|     |------------------|
    #                             |                       |     |                  |     |                  |     |                  |     |                  |
    #                             |-----------------------|     |                  |     |                  |     |                  |     |                  |
    #                             |               data    |---->|                  |     |                  |     |                  |     |                  |
    #                             |-----------------------|     |             next |---->|             next |---->|             next |---->|             next |----> ptr_fst_data 
    #                             |                       |     |------------------|     |------------------|     |------------------|     |------------------|     !ptr_lst_data
    #                             |                       |     |                  |                                                            ^
    #                             |-----------------------|     |             last |------------------------------------------------------------|    
    #                             |  next     cmd object  |     --------------------
    #                             -------------------------
    #                                |
    #                                |
    #                                V  next
    #                                            prev  ^
    #                                                  |
    #                                                  |
    #                             -------------------------     
    #   ----> ptr_pre_cmd         |  previous cmd object  |  
    #   ----> PREVIOUS            |-----------------------|    
    #   ----> PENULTIMATE         |                       |
    #                             |                       |
    #                             |                       |
    #                             |                       |
    #                             |                       |
    #                             |-----------------------|     
    #                             |               data    |----> undefined
    #                             |-----------------------|      
    #                             |                       |
    #                             |                       |
    #                             |-----------------------|    
    #                             |  next     cmd object  |
    #                             -------------------------
    #                                |
    #                                |
    #                                V  next
    #                                            prev  ^
    #                                                  |
    #                                                  |
    #                             -------------------------      
    #   ----> ptr_cur_cmd         |  previous cmd object  |   
    #   ----> CURRENT             |-----------------------|     
    #   ----> LAST/ULTIMATE       |                       |
    #                             |                       |
    #                             |                       |
    #                             |                       |
    #                             |                       |
    #                             |-----------------------|       
    #                             |               data    |----> undefined 
    #                             |-----------------------|      
    #                             |                       |
    #                             |                       |
    #                             |-----------------------|     
    #                             |  next     cmd object  |
    #   ----> ptr_lst_cmd         ------------------------- 
    #                                |
    #                                |
    #                                V  next
    #                                ptr_fst_cmd
    #
    #=============================================================================================================
   
    ${$ptr_ref}{adr}{last}                  = $ptr_cur_cmd;                                         # No look ahead, current ptr is last ptr
                                                                                                    #                The last ADDR transfere
    $command{assert}                        = $COL->[ 0];                                           # assertion  time / addr_assertion
    $command{complete}                      = $COL->[ 2];                                           # completion time / addr_sampling 
    $command{direction}                     = $COL->[ 4];                                           # direction  READ/WRITE  BUSY/DATA
    $command{addr}                          = $COL->[ 5];                                           # ADDRESS    aligned, unaligned
   #$command{beat_num}                      NA        6                                             # BEAT
    $command{burst_len}                     = $COL->[ 7];                                           # 1, 4, 8, 16, any >1
   #$command{data}                          NA        8                                             # DATA  strobed, ADDR transfer has no DATA associated
   #$command{response}                      NA        9                                             # Slave response
    $command{burst_type}                    = $COL->[10];                                           # SINGLE,INCR,INCR4,WRAP4,INCR8,WRAP8,INCR16,WRAP16
    $command{burst_size}                    = $COL->[11];                                           # 1, 2 or 4 Byte
    $command{hport}                         = $COL->[12];                                           # HPROT protection   CACHE,BUFFER,PRIVILEGE,OPCODE/DATA
   #$command{slave}                         = $COL->[13];                                           # Slave index

    if ( ${$opts_ref}{logging_build} ) {
        printf $buih  "%*s%s :: first command\n", 22, '', $first_cmd;
    }#logging

    if ( $first_cmd ) {
        ${$ptr_ref}{adr}{first}             = $ptr_cur_cmd;                                         # Set entry pointer first       Command
        ${$ptr_ref}{adr}{penultimate}       = $ptr_cur_cmd;                                         # Set       pointer penultimate Command
        ${$ptr_ref}{adr}{previous}          = $ptr_cur_cmd;                                         # Set       pointer previous    Command
        $command{prev}                      = ${$ptr_ref}{adr}{first};                              # points to itself prev == curr
        $command{next}                      = ${$ptr_ref}{adr}{first};                              # points to first  next == first 
        $first_cmd                          = 0;                                                    # Update SM parse AHB tracker
    } else {                                                                                        # first command
        ${${$ptr_ref}{adr}{previous}}{next} = ${$ptr_ref}{adr}{last};                               # Update     previous cmd obj next reference LAST/CURRENT
        $command{prev}                      = ${$ptr_ref}{adr}{previous};                           # Pointing   backward to PREVIOUS Command
        $command{next}                      = ${$ptr_ref}{adr}{first};                              # Initialize circular to FIRST    Command/pointer
        ${$ptr_ref}{adr}{penultimate}       = ${$ptr_ref}{adr}{previous};                           # Update     pointer penultimate  Command
        ${$ptr_ref}{adr}{previous}          = $ptr_cur_cmd;                                         # Update     pointer previous     Command
    }
    return $ptr_cur_cmd;                                                                            # Return pointer to current object
}#sub build_command_obj



sub build_data_obj{
    my  (   $opts_ref                                                                               # Input     Command line reference/control
        ,   $COL                                                                                    # Input     column array w/ parsed trace data
        ,   $ptr_ref                                                                                #           Pointer information into trace transfer list
        ,   $buih       ) = @_;                                                                     #           File handle to building log

    my %data_obj;                                                                                   # Create new current data transfer obj
    my $ptr_cur_dta = \%data_obj;                                                                   # Pointer to current data transfer obj

    #
    # $ptr_prv_cmd points to the LAST command/addr transfer, as it is the previous & current & last command !!
    #

    $data_obj{assert}         = $COL->[ 0]; #$line[0];                                              # assertion  time / data transfer assertion
    $data_obj{complete}       = $COL->[ 2]; #$line[1];                                              # completion time / data transfer completion
    $data_obj{phase}          = $COL->[ 4]; #$line[2];                                              # direction  READ/WRITE  phase   DATA/BUSY
    $data_obj{address}        = $COL->[ 5]; #$line[3];                                              # ADDRESS updated, select SLAVE, data strobe, warp
    $data_obj{beat_num}       = $COL->[ 6]; #$line[4];                                              # BEAT
   #$data_obj{burst_len}      NA        7                                                           # 1, 4, 8, 16, any >1
    $data_obj{data}           = $COL->[ 8]; #$line[6];                                              # DATA ( 1, 2, 4) Byte strobed via address
    $data_obj{response}       = $COL->[ 9]; #$line[7];                                              # Slave response OKAY/ERROR
   #$data_obj{burst_type}     NA       10                                                           # SINGLE,INCR,INCR4,WRAP4,INCR8,WRAP8,INCR16,WRAP16
   #$data_obj{burst_size}     NA       11                                                           # 1, 2 or 4 Byte
   #$data_obj{protection}     NA       12                                                           # HPROT protection   CACHE,BUFFER,PRIVILEGE,OPCODE/DATA
   #$data_obj{slave_index}    NA       13                                                           # Slave index

    #
    # The problem of concurrent DATA PHASE w/ ADDR PHASE of next command, creates "TWO" instead of ONE OT transactions
    # this leads to an incomplete occupied state machine, to identify the data phase as either LAST or FIRST transfer
    #
    
    if ( !defined ${${$ptr_ref}{adr}{previous}}{data} ) {

         if ( ${$opts_ref}{logging_build} ) {
            printf $buih  "%*s::             AHB address transfer phase detected\n", 22, '';
         }#logging

         if ( $data_obj{assert} == ${${$ptr_ref}{adr}{previous}}{assert} ) {
              if ( !defined ${${$ptr_ref}{adr}{penultimate}}{data} ) {

                   if ( ${$opts_ref}{logging_build} ) {
                        printf $buih "%*s:: penultimate AHB address transfer has no FIRST data phase detected\n",22,'';
                        printf $buih "%*s:: sequential  AHB data    transfer phase detected FIRST\n",22,'';
                        printf $buih " %*sDATA transfer assertion time : %8s ns\n", 24, '',$data_obj{assert};
                        printf $buih " %*sADDR transfer assertion time : %8s ns\n", 24, '',${${$ptr_ref}{adr}{penultimate}}{data};
                   }#logging

                   ${${$ptr_ref}{adr}{penultimate}}{data}                                           # update penultimate & previous last command pointer to
                   = $ptr_cur_dta;                                                                  # first/current data transaction
           
                   ${$ptr_ref}{dta}{first}                                                          # Store  first data pointer to
                   = $ptr_cur_dta;                                                                  # current/first data transaction
           
                   $data_obj{prev}                                                                  # update previous data object pointer 
                   = ${$ptr_ref}{dta}{first};                                                       # points to itself, first data object/transaction
           
                   $data_obj{next}                                                                  # Initial pointer to next     data object
                   = ${$ptr_ref}{dta}{first};                                                       # points circular to first    data object
                                                                                                    # to be  updated  w/ next     data object
           
                   $data_obj{last}                                                                  # Initial pointer to last     data object/transfer
                   = $ptr_cur_dta;                                                                  # with               current  data object
                     
                   ${$ptr_ref}{dta}{previous}                                                       # Store  pointer  to previous data object 
                   = ${$ptr_ref}{dta}{first};                                                       # points          to current  data object
              } else {# Insert SINGLE penultimate

                   if ( ${$opts_ref}{logging_build} ) {
                        printf $buih  "%*s:: penultimate AHB address transfer had    FIRST data phase detected\n",22,'';
                   }#logging

                   #
                   # $ptr_prv_dta, $ptr_lst_dta, $ptr_fst_dta are not updated - thus behave correctly sequential
                   # still pointing to the sequential DATA transfers of the second last/antepenultimate  AHB CMD
                   #

                   ${${$ptr_ref}{dta}{previous}}{next}                                              # Update/overwrite previous   data object next_pointer
                   = $ptr_cur_dta;                                                                  # with   pointer to current   data object/transaction

                   $data_obj{next}                                                                  # Initial pointer to next     data object next_pointer
                   = ${$ptr_ref}{dta}{first};                                                       # points circular to first    data object/transaction

                   $data_obj{prev}                                                                  # Store   pointer to previous data object/transaction
                   = ${$ptr_ref}{dta}{previous};                                                    # points          to previous data object/transaction

                   ${$ptr_ref}{dta}{previous}                                                       # Update  pointer to previous data object/transaction
                   = $ptr_cur_dta;                                                                  # with               current  data object/transaction
                   
                   ${$ptr_ref}{dta}{last}                                                           # Update  pointer to last     data object/transaction
                   = $ptr_cur_dta;                                                                  # with               current  data object/transaction

                   ${${$ptr_ref}{dta}{first}}{last}                                                 # Update  in the first data transfer, pointer LAST
                   = $ptr_cur_dta;                                                                  # with    pointer to last     data object/transaction
              }#Insert LAST ultimate
         } else {

                if ( ${$opts_ref}{logging_build} ) {
                    printf $buih "%*s:: sequential  AHB data    transfer phase detected FIRST\n"
                                 , 22, '';
                    printf $buih " %*sDATA transfer assertion time : %8s ns\n",24,''
                                 ,$data_obj{assert};
                    printf $buih " %*sADDR transfer assertion time : %8s ns\n",24,''
                                 ,${${$ptr_ref}{adr}{previous}}{assert};
                }#logging

                ${${$ptr_ref}{adr}{previous}}{data}                                                 # update previous&last command pointer to
                = $ptr_cur_dta;                                                                     # first/current data transaction
      
                ${$ptr_ref}{dta}{first}                                                             # Store  first data pointer to
                = $ptr_cur_dta;                                                                     # current/first data transaction
      
                $data_obj{prev}                                                                     # update previous data object pointer 
                = ${$ptr_ref}{dta}{first};                                                          # points to itself, first data object/transaction
      
                $data_obj{next}                                                                     # Initial pointer to next     data object
                = ${$ptr_ref}{dta}{first};                                                          # points circular to first    data object
                                                                                                    # to be  updated  w/ next     data object
      
                $data_obj{last}                                                                     # Initial pointer to last     data object/transfer
                = $ptr_cur_dta;                                                                     # with               current  data object
                  
                ${$ptr_ref}{dta}{previous}                                                          # Store  pointer  to previous data object 
                = ${$ptr_ref}{dta}{first};                                                          # points          to current  data object
         }# Insert FIRST
    } else {
           if ( ${$opts_ref}{logging_build} ) {
                printf $buih  "%*s:: sequential AHB data    transfer phase detected\n", 22, '';
           }#logging

           ${${$ptr_ref}{dta}{previous}}{next}                                                      # Update/overwrite previous   data object next_pointer
           = $ptr_cur_dta;                                                                          # with   pointer to current   data object/transaction

           $data_obj{next}                                                                          # Initial pointer to next     data object next_pointer
           = ${$ptr_ref}{dta}{first};                                                               # points circular to first    data object/transaction

           $data_obj{prev}                                                                          # Store   pointer to previous data object/transaction
           = ${$ptr_ref}{dta}{previous};                                                            # points          to previous data object/transaction

           ${$ptr_ref}{dta}{previous}                                                               # Update  pointer to previous data object/transaction
           = $ptr_cur_dta;                                                                          # with               current  data object/transaction
           
           ${$ptr_ref}{dta}{last}                                                                   # Update  pointer to last     data object/transaction
           = $ptr_cur_dta;                                                                          # with               current  data object/transaction

           ${${$ptr_ref}{dta}{first}}{last}                                                         # Update  in the first data transfer, pointer LAST
           = ${$ptr_ref}{dta}{last};                                                                # with    pointer to last     data object/transaction
    }# Insert SEQUENTIAL 
}#sub build_data_obj


sub initialize_latency_analysis {
    my ($a_ref) = @_;                                                                               # Reference to hash
    
    my $ridiculous = 1000000;

    #
    # This set was used for calculation including ADDR phase
    #

    ${$a_ref}{ALL}{minimum}     = $ridiculous;
    ${$a_ref}{ALL}{average}     = 0;
    ${$a_ref}{ALL}{maximum}     = 0;
    ${$a_ref}{ALL}{number}      = 0;

    ${$a_ref}{READ}{minimum}    = $ridiculous;
    ${$a_ref}{READ}{average}    = 0;
    ${$a_ref}{READ}{maximum}    = 0;
    ${$a_ref}{READ}{number}     = 0;

    ${$a_ref}{WRITE}{minimum}   = $ridiculous;
    ${$a_ref}{WRITE}{average}   = 0;
    ${$a_ref}{WRITE}{maximum}   = 0;
    ${$a_ref}{WRITE}{number}    = 0;

    #
    # First data transfer 
    #

    ${$a_ref}{1}{ALL}{minimum}  = $ridiculous;
    ${$a_ref}{1}{ALL}{average}  = 0;
    ${$a_ref}{1}{ALL}{maximum}  = 0;
    ${$a_ref}{1}{ALL}{number}   = 0;
    ${$a_ref}{1}{ALL}{total}    = 0;

    ${$a_ref}{1}{READ}{minimum} = $ridiculous;
    ${$a_ref}{1}{READ}{average} = 0;
    ${$a_ref}{1}{READ}{maximum} = 0;
    ${$a_ref}{1}{READ}{number}  = 0;
    ${$a_ref}{1}{READ}{total}   = 0;

    ${$a_ref}{1}{WRITE}{minimum}= $ridiculous;
    ${$a_ref}{1}{WRITE}{average}= 0;
    ${$a_ref}{1}{WRITE}{maximum}= 0;
    ${$a_ref}{1}{WRITE}{number} = 0;
    ${$a_ref}{1}{WRITE}{total}  = 0;

    # Last data transfer, complete burst

    ${$a_ref}{L}{ALL}{minimum}  = $ridiculous;
    ${$a_ref}{L}{ALL}{average}  = 0;
    ${$a_ref}{L}{ALL}{maximum}  = 0;
    ${$a_ref}{L}{ALL}{number}   = 0;
    ${$a_ref}{L}{ALL}{total}    = 0;

    ${$a_ref}{L}{READ}{minimum} = $ridiculous;
    ${$a_ref}{L}{READ}{average} = 0;
    ${$a_ref}{L}{READ}{maximum} = 0;
    ${$a_ref}{L}{READ}{number}  = 0;
    ${$a_ref}{L}{READ}{total}   = 0;

    ${$a_ref}{L}{WRITE}{minimum}= $ridiculous;
    ${$a_ref}{L}{WRITE}{average}= 0;
    ${$a_ref}{L}{WRITE}{maximum}= 0;
    ${$a_ref}{L}{WRITE}{number} = 0;
    ${$a_ref}{L}{WRITE}{total}  = 0;

    printf $proh "\n";
    printf $proh " ... initialzing latency analysis done !!\n";
}#sub initialize_latency_analysis


sub   initialize_transaction_analysis {
      my ( $a_ref ) = @_;                                                                           # Reference to hash -->  $ahb_anal ysis

      my @_list     =   ( "SINGLE", "INCR", "INCR4", "INCR8", "INCR16"
                        , "WRAP4", "WRAP8", "WRAP16", "total" );
      my @_dirs     =   ( "READ", "WRITE" );                                                        # direction
      my @_size     =   ( 1, 2, 4 );                                                                # byte
    
      foreach my $size (@_size) {
          foreach my $dir (@_dirs) {
              foreach my $trans (@_list) {
                  ${$a_ref}{transaction}{$trans}              = 0;
                  ${$a_ref}{transaction}{$dir}{$trans}        = 0;
                  ${$a_ref}{transaction}{$size}{$dir}{$trans} = 0;
              }# trans
          }# dirs
      }# size
      printf $proh " ... initialzing transaction analysis done !!\n";
}#sub initialize_transaction_analysis


sub   initialize_payload_analysis {
      my (  $trace_header_ref                                                                       # Trace   information from trace file h
         ,  $ptr_ref                                                                                # Pointer information into trace list
         ,  $opts_ref     ) = @_;                                                                   # Command line options

      my $payh;                                                                                     # File handle payload
      my $errh;                                                                                     # File handle error logging      
      my $transaction       = 0;
      my $totalbeat         = 0;
      my $data_beat         = 0;
      my $busy_beat         = 0;
      my $total_payload     = 0;
      my $write_payload     = 0;
      my $read_payload      = 0;

      my $cycle             = ${$trace_header_ref}{period};                                         # (float)
      my $tb                = ${$trace_header_ref}{timebase};                                       # =  $6; # (ns|ps)
      my $frequency         = ${$trace_header_ref}{frequency};                                      # (float)
      my $fb                = ${$trace_header_ref}{freqbase};                                       # (MHz|GHz)
      my $logfile           = ${$opts_ref}{payload};                                                # logfile name
      my $errlog            = ${$opts_ref}{errlog};
      my $buffer_stop       = ${$ptr_ref}{adr}{first};                                              # Set buffer stop pointer to the FIRST  pointer of Transfer List
      my $ptr_cur_cmd       = ${$ptr_ref}{adr}{first};                                              # Set iterate     pointer to the FIRST  pointer of Transfer List

      printf $proh  "\n";
      printf $proh  " ... initializing payload analysis\n";

      if ( ${$opts_ref}{logging_payload} ) {
            printf $proh  "     opening PayloadLogFile %s\n", $logfile;
            open ( $payh, ">$logfile")|| die " Can not create log $logfile";
      }#logging

      if ( ${$opts_ref}{logging_error} ) {
            printf $proh  "     opening ErrorLogFile %s\n", $errlog;
            open ( $errh, ">$errlog") || die " Can not create log $errlog";                         # Report errors trace file formats
            printf $errh  " %s\n"     , '='x80;
            printf $errh  " Tracefile : %s\n"             , ${$trace_header_ref}{tracefile};        
            printf $errh  " Script    : %s %s\n"          , $0, $VERSION;                           #  0  1, 2,    3,   4,    5,    6,    7,     8
            printf $errh  " Date      : %4s-%02s-%02s\n"  , 1900+$year,$mon,$cday;                  # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
            printf $errh  " Time      : %4s:%02s:%02s\n"  , $h, $m,$s;                              # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
            printf $errh  " Cycle     : %10s %s\n"        , $cycle, $tb;                            # Header timebase information
            printf $errh  " Frequency : %10s %s\n",       , $frequency, $fb;                        # Header frequency information
            printf $errh  " %s\n"     , '='x80;
      }#logging

      if ( ${$opts_ref}{logging_payload} ) {
           printf $payh " %s\n"     , '='x80;
           printf $payh " Tracefile : %s\n"             ,${$trace_header_ref}{tracefile};
           printf $payh " Logfile   : %s\n"             ,$logfile; 
           printf $payh " Script    : %s %s\n"          ,$0, $VERSION;                              #  0  1, 2,    3,   4,    5,    6,    7,     8
           printf $payh " Date      : %4s-%02s-%02s\n"  ,1900+$year,$mon,$cday;                     # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $payh " Time      : %4s:%02s:%02s\n"  ,$h, $m,$s;                                 # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $payh " Cycle     : %10s %s\n"        ,$cycle, $tb;                               # Header timebase information
           printf $payh " Frequency : %10s %s\n",       ,$frequency, $fb;                           # Header frequency information
           printf $payh " %s\n"     , '='x80;
      }#logging

      do {
          $transaction++;                                                                           # For   all transactions
          my $ptr_cur_dta = ${$ptr_cur_cmd}{data};                                                  # Set   pointer for data transfer           LOCAL pointer now !!
          my $ptr_fst_dta = ${$ptr_cur_dta}{prev};                                                  # Stop  criteria
          my $ptr_lst_dta = ${$ptr_cur_dta}{last};                                                  # Last  data transfer
          $totalbeat   = 0;                                                                         # Start count fresh for each transaction
          $data_beat   = 0;
          $busy_beat   = 0;

          if ( ${$opts_ref}{logging_payload} ) {
                printf $payh "%*s %s %10s\n",12,'','Transaction   :',$transaction;
                printf $payh "%*s %s %10s\n",12,'','Direction     :',${$ptr_cur_cmd}{direction};
                printf $payh "%*s %s %10s\n",12,'','Burst Type    :',${$ptr_cur_cmd}{burst_type};
          }#logging

          if ( ${$opts_ref}{logging_error} ) {
                printf $errh "%*s %s %10s\n",12,'','Transaction   :',$transaction;
                printf $errh "%*s %s %10s\n",12,'','Burst Type    :',${$ptr_cur_cmd}{burst_type};
          }#ErrorLogging

          do {
              if ( ${$ptr_cur_dta}{phase} =~ m/DATA/ ) {                                            # DATA, BUSY phase
                   $totalbeat++;                                                                    # ONLY  data transfer count as beats                      
                   $data_beat++;
                   if ( ${$opts_ref}{logging_payload} ) {
                        printf $payh "%*s %s %2s of %2s :: %s" ,30,'','transfer  '   
                                     ,$data_beat,$totalbeat,${$ptr_cur_dta}{phase};
                   }#logging
              }
              if ( ${$ptr_cur_dta}{phase} =~ m/BUSY/ ) {
                   $busy_beat++;                                                                    # A wait state is no BEAT, it is an extention
                   if ( ${$opts_ref}{logging_payload} ) {
                        printf $payh "%*s %s %2s of %2s :: %s" ,30,'','wait state'   
                                     ,$busy_beat,$totalbeat,${$ptr_cur_dta}{phase};
                   }#logging
              }

              if ( ${$opts_ref}{logging_payload} ) {
                   printf $payh " :: %s %s\n" ,'beat    ',${$ptr_cur_dta}{beat_num};
              }#logging

              my ($beat,$length) = split /\//, ${$ptr_cur_dta}{beat_num};
              if ( $beat != $data_beat ) {
                    if ( ${$opts_ref}{logging_error} ) {
                        printf $errh "%*s %s %2s vs %2s :: %s\n",30,'','Error Beat'                 ## Needs review VIP from Mentor has changed
                                     ,$data_beat,${$ptr_cur_dta}{beat_num},'reported';
                    }#ErrorLogging
              }#report trace error

              $ptr_cur_dta = ${$ptr_cur_dta}{next};                                                 # circular list points to the beginning
          }until ($ptr_cur_dta == $ptr_fst_dta);                                                    # If first is the last&only pointer, then the next is the first as well
 
          ${$ptr_cur_cmd}{transaction} = $transaction;                                              # Ordinal transaction number, for xref
          ${$ptr_cur_cmd}{burstlength} = $totalbeat;                                                # Last beat/data transfer/burst length 
          ${$ptr_cur_cmd}{payload}     = $totalbeat * ${$ptr_cur_cmd}{burst_size};                  # data transfered in burst
          $total_payload              += $totalbeat * ${$ptr_cur_cmd}{burst_size};
          $write_payload              += $totalbeat * ${$ptr_cur_cmd}{burst_size} if ( ${$ptr_cur_cmd}{direction} =~ m/WR/ );
          $read_payload               += $totalbeat * ${$ptr_cur_cmd}{burst_size} if ( ${$ptr_cur_cmd}{direction} =~ m/RD/ );
          
          if ( ${$opts_ref}{logging_payload} ) {
               printf $payh "%*s %s %10s byte/beat\n",12,'','Burst Size    :',${$ptr_cur_cmd}{burst_size};
               printf $payh "%*s %s %10s beat\n"     ,12,'','Burst Length  :',${$ptr_cur_cmd}{burstlength};
               printf $payh "%*s %s %10s byte\n"     ,12,'','Burst Payload :',${$ptr_cur_cmd}{payload    };
               printf $payh "\n";
          }#logging

          printf $errh "\n" if ( ${$opts_ref}{logging_error} );                                     # Error Logging Spacer
          
          $ptr_cur_cmd = ${$ptr_cur_cmd}{next};                                                     # Progress to next transaction/transfer AHB command
      } until ($ptr_cur_cmd == $buffer_stop );                                                      # Iterate  over entire transaction list

      if ( ${$opts_ref}{logging_payload} ) {
            printf $payh  "\n";
            printf $payh  "%*s %s %10s byte\n",12,'','Payload Total:',$total_payload;
            printf $payh  "%*s %s %10s byte\n",12,'','Payload Write:',$write_payload;
            printf $payh  "%*s %s %10s byte\n",12,'','Payload Read :',$read_payload;
            printf $proh  "     closing PayloadLogFile %s\n", $logfile;
            close( $payh );
      }#logging
  
      if ( ${$opts_ref}{logging_error} ) {
            printf $proh  "     closing ErrorLogFile %s\n", $errlog;
            close( $errh );
      }#ErrorLogging
      printf $proh  " ... initializing payload done\n";
}#sub initialize_payload_analysis

#
#     Analysis of transfers on a transaction by transfer basis
#     Each transaction is analyzed standalone, ADDR transfer concealment is not considered
#     Results are transaction based not accumulated
#

sub   transfer_analysis {
      my (  $trace_header_ref                                                                       # Input     Trace   information from trace file header
         ,  $ptr_ref                                                                                #           Pointer information into trace list
         ,  $opts_ref                                                                               #           Command line options
         ,  $transfer_ref      ) = @_;                                                              # Output    Transfer analysis

      my $trah;                                                                                     # File handle transfer
      my $logfile     = ${$opts_ref}{transfer};
      my $cycle       = ${$trace_header_ref}{period};                                               # (float)
      my $tb          = ${$trace_header_ref}{timebase};                                             # =  $6; # (ns|ps)
      my $frequency   = ${$trace_header_ref}{frequency};                                            # (float)
      my $fb          = ${$trace_header_ref}{freqbase};                                             # (MHz|GHz)
      my $transaction = 0;
      my $beat        = 0;

      printf $proh "\n";
      printf $proh " ... transfer analysis\n";
      if ( ${$opts_ref}{logging_transfer} ) {
        printf $proh "     opening    transfer log %s\n"  ,  $logfile;
        open ( $trah,">$logfile")|| die " Can not create log $logfile";                             # Are the bus transfers accounted for ? Mendatory
        printf $trah " %s\n"     , '='x80;
        printf $trah " Tracefile   : %s\n"           ,${$trace_header_ref}{tracefile};
        printf $trah "               %s\n"           ,${$opts_ref}{trace_file};
        printf $trah " Synopsis    : %s\n"           ,'Transfer Analysis, spanning single transfers';
        printf $trah " Logfile     : %s\n"           ,$logfile; 
        printf $trah " Script      : %s %s\n"        ,$0, $VERSION;                                 #  0  1, 2,    3,   4,    5,    6,    7,     8
        printf $trah " Date        : %4s-%02s-%02s\n",1900+$year,$mon,$cday;                        # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
        printf $trah " Time        : %4s:%02s:%02s\n",$h, $m,$s;                                    # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
        printf $trah " Cycle       : %10s %s\n"      ,$cycle, $tb;                                  # Header timebase information
        printf $trah " Frequency   : %10s %s\n",     ,$frequency, $fb;                              # Header frequency information
        printf $trah " %s\n"     , '='x80;
      }#logging
      
      my $IDLE_duration             = 0;                                                            # Checks and balances 
      my $ADDR_duration             = 0;                                                            # Checks and balances
      my $DATA_duration             = 0;                                                            # Checks and balances
      my $TIME_duration             = 0;                                                            # Checks and balances
      my $ptr_cur_cmd               =   ${$ptr_ref}{adr}{first};
      my $buffer_stop               =   ${$ptr_ref}{adr}{first};
      my $last_transfer_stop        = ${${$ptr_ref}{adr}{first}}{assert};                           # Wrong initialization, for calculation
      my $previous_transfer_stop    = ${${$ptr_ref}{adr}{first}}{assert};
      my $TIME_START                = ${$ptr_cur_cmd}{assert};                                      # Start of trace window, assert first transfer LOCAL ptr !!

      do {
          $transaction++;
          $beat = 0;
          # 
          # IDLE transfer is implicite in trace file and zero in back to back transactions
          # ADDR transfer might be concealed behind DATA transfers
          #
          # previous_transfer_stop   <  ${$ptr_cur_cmd}{assert} ==> IDLE not ZERO
          #                                                         ADDR not ZERO, Not consealed
          #
          # previous_transfer_stop  ==  ${$ptr_cur_cmd}{assert} ==> IDLE  == ZER0
          #                                                         ADDR not ZERO, Not consealed
          # previous_transfer_stop  ==  ${$ptr_cur_cmd}{complete} 
          # previous_transfer_stop   >  ${$ptr_cur_cmd}{assert} ==> IDLE  == ZERO
          #                                                         ADDR  == ZERO,     consealed behind DATA
          #                                                         ADDR  is consealed/hidden behind previous DATA
          
          if    ( ${$ptr_cur_cmd}{assert}  > $previous_transfer_stop ) {
                  ${$transfer_ref}{$transaction}{ADDR}{concealed}       = 'NOT';
                  ${$transfer_ref}{$transaction}{IDLE}{transferstart}   = $previous_transfer_stop;
                  ${$transfer_ref}{$transaction}{IDLE}{transferstop}    = ${$ptr_cur_cmd}{assert};
          }elsif( ${$ptr_cur_cmd}{assert} == $previous_transfer_stop ) {
                  ${$transfer_ref}{$transaction}{ADDR}{concealed}       = 'NOT';
                  ${$transfer_ref}{$transaction}{IDLE}{transferstart}   = $previous_transfer_stop;
                  ${$transfer_ref}{$transaction}{IDLE}{transferstop}    = $previous_transfer_stop;
          }elsif( ${$ptr_cur_cmd}{assert}  < $previous_transfer_stop ) {
                  ${$transfer_ref}{$transaction}{ADDR}{concealed}       = 'YES';
                  ${$transfer_ref}{$transaction}{IDLE}{transferstart}   = ${$ptr_cur_cmd}{assert};
                  ${$transfer_ref}{$transaction}{IDLE}{transferstop}    = ${$ptr_cur_cmd}{assert};
          }
          ${$transfer_ref}{$transaction}{ADDR}{transferstart}   = ${$ptr_cur_cmd}{assert};
          ${$transfer_ref}{$transaction}{ADDR}{transferstop }   = ${$ptr_cur_cmd}{complete};
          ${$transfer_ref}{$transaction}{IDLE}{duration}        = ${$transfer_ref}{$transaction}{IDLE}{transferstop}     
                                                                - ${$transfer_ref}{$transaction}{IDLE}{transferstart};
          ${$transfer_ref}{$transaction}{ADDR}{duration}        = ${$transfer_ref}{$transaction}{ADDR}{transferstop} 
                                                                - ${$transfer_ref}{$transaction}{ADDR}{transferstart};

          $previous_transfer_stop   = ${$ptr_cur_cmd}{complete};
          my $ptr_cur_dta           = ${$ptr_cur_cmd}{data};                                     # Set pointer to              data transfer also the first
          my $ptr_fst_dta           = ${$ptr_cur_dta}{prev};                                     # Initialize pointer to first data transfer
          my $ptr_lst_dta           = ${$ptr_cur_dta}{last};                                     # Initialize pointer to last  data transfer

          ${$ptr_cur_cmd}{AddrComp} = ${$ptr_cur_cmd}{complete} - ${$ptr_cur_cmd}{assert};

          #
          # Transfer analysis   - Each AHB transaction can has WAIT states, aka BUSY transfers
          #
          
          if ( ${$opts_ref}{logging_transfer} ) {
               printf $trah "%*s %s %10s\n"      ,14,'','Transaction:', $transaction;                                       
               printf $trah "%*s %s %10s %s %s\n",14,'','IdleTransfer', ${$transfer_ref}{$transaction}{IDLE}{duration}, $tb
                                                                      ,(${$transfer_ref}{$transaction}{IDLE}{duration} == 0)
                                                                      ? 'Back2Back'
                                                                      : 'IDLE';
               printf $trah "%*s %s %10s %s %s\n",14,'','AddrTransfer', ${$transfer_ref}{$transaction}{ADDR}{duration}, $tb
                                                                      ,(${$transfer_ref}{$transaction}{ADDR}{concealed} =~ m/NOT/)
                                                                      ? 'Transfer visible'
                                                                      : 'Transfer consealed';
          }#logging

          ${$transfer_ref}{$transaction}{BUSY}{duration}        = 0; # Implicite WAIT states, accounted explicite, initialized to ZERO
          ${$transfer_ref}{$transaction}{BUSY}{total}{duration} = 0; # Initialize WAIT states as ZERO
          do {
              #
              # The wait state or BUSY transfer comes before the DATA transfer complete
              #
              
              if ( ${$ptr_cur_dta}{phase} =~ m/BUSY/ ) {
                   my $wait_state = ${$ptr_cur_dta}{complete} - ${$ptr_cur_dta}{assert};                        # The trace protocol allows 1 or more WAIT state
                                                                                                                # being inserted, trace reports transfers not clock cycle
                   ${$transfer_ref}{$transaction}{BUSY}{$beat+1}{duration}  = $wait_state;                      # The wait state comes before the DATA transfer,
                   ${$transfer_ref}{$transaction}{BUSY}{total}{duration}   += $wait_state;                      # thus the wait state is associate w/ next beat
              }# BUSY beats, accounting for one or more WAIT states

              #
              # Only DATA transfers are beats, Trace protocol inserts/accounts expletice for WAIT states as BUSY cycles
              #

              if ( ${$ptr_cur_dta}{phase} =~ m/DATA/ ) {
                   $beat++;                                                                                     # Update data transfer beat count
                   #
                   # The first data transfer starts with the end of the ADDR transfer, 
                   # the first beat could be a BUSY transfer
                   #
                   if ( $previous_transfer_stop < ${$ptr_cur_dta}{assert} ) {                                   # There must have been a WAIT state
                        ${$transfer_ref}{$transaction}{DATA}{$beat}{transferstart} = $previous_transfer_stop;   # Trace protocol counts BUSY cycle, blurs beat count
                   } else {
                        ${$transfer_ref}{$transaction}{DATA}{$beat}{transferstart} = ${$ptr_cur_dta}{assert};   # extract transfer start
                   }# determin DATA transfer start with WAIT states
                   ${$transfer_ref}{$transaction}{DATA}{$beat}{transferstop}       
                   = ${$ptr_cur_dta}{complete};                                                                 # extract transfer stop
                   ${$transfer_ref}{$transaction}{DATA}{$beat}{duration} 
                   = ${$transfer_ref}{$transaction}{DATA}{$beat}{transferstop }
                   - ${$transfer_ref}{$transaction}{DATA}{$beat}{transferstart};

                   $previous_transfer_stop  = ${$ptr_cur_dta}{complete};                                        # Remember transaction completion Previous also Last
              }# DATA beats                                                                                     # Last transfer must be DATA transfer

              if ( ${$opts_ref}{logging_transfer} ) {
                   printf $trah "%*s %s %2s :: %5s",41,'','beat',$beat,${$ptr_cur_dta}{beat_num};
                   printf $trah "%*s %12s %s\n"    ,11,'', 
                                ${$ptr_cur_dta}{complete} - ${$ptr_cur_dta}{assert},$tb;                        # duration of transfer
                   printf $trah "%*s %s %12s %s\n",60,'','complete',${$ptr_cur_dta}{complete},$tb;
                   printf $trah "%*s %s %12s %s\n",60,'','assert  ',${$ptr_cur_dta}{assert}  ,$tb;
              }#logging

              $ptr_cur_dta = ${$ptr_cur_dta}{next};                                                             # circular list points to the beginning
          }until ($ptr_cur_dta == $ptr_fst_dta);                                                                # If first is the last&only pointer,
                                                                                                                # then the next is the first as well
          ${$transfer_ref}{$transaction}{ADDR}{length}          = $beat;                                        # Record the beat count of transaction, burst lenght
          ${$transfer_ref}{$transaction}{DATA}{total}{duration} = ${$transfer_ref}{$transaction}{DATA}{$beat}{transferstop }
                                                                - ${$transfer_ref}{$transaction}{ADDR}{transferstop };
          $last_transfer_stop                                   = ${$transfer_ref}{$transaction}{DATA}{$beat}{transferstop};

          if ( ${$opts_ref}{logging_transfer} ) {
               printf $trah "%*s %s %10s %s\n",14,'','BusyTransfer',${$transfer_ref}{$transaction}{BUSY}{duration},$tb;
               printf $trah "\n";
          }#logging

          #
          # For checks and balances, the total time visible on the BFM trace, should match the total trace window
          #
          
             $IDLE_duration                     
          += ${$transfer_ref}{$transaction}{IDLE}{duration};
          if ( ${$transfer_ref}{$transaction}{ADDR}{concealed} =~ m/NOT/) {
                  $ADDR_duration                
               += ${$transfer_ref}{$transaction}{ADDR}{duration};
          }# if ADDR transfer is visible and not concealed
             $DATA_duration                     
          += ${$transfer_ref}{$transaction}{DATA}{total}{duration};

          $ptr_cur_cmd = ${$ptr_cur_cmd}{next};                 # Iterate to the next transaction/transfer AHB command
      } until ($ptr_cur_cmd == $buffer_stop );                  # UNTIL LAST AHB command

      $TIME_duration  = $previous_transfer_stop - $TIME_START;  # Trace window period
  
      if ( ${$opts_ref}{logging_transfer} ) {
           printf $trah "\n";
           printf $trah "%*s %s %10s\n",8,'','Total   IDLE :',$IDLE_duration;
           printf $trah "%*s %s %10s\n",8,'','Visibal ADDR :',$ADDR_duration;
           printf $trah "%*s %s %10s\n",8,'','Visibal DATA :',$DATA_duration;
           printf $trah "%*s %s %10s\n",8,'','Trace Window :',$TIME_duration;
           close( $trah );
           printf $proh  "     closing    transfer log %s\n", $logfile;
      }#logging

      printf $proh  " ... transfer analysis done\n";
      printf $proh "\n";
}#sub initialize_transfer_analysis

#
# Latency analysis spans multiple transfers, not a single transfer
#

sub   latency_analysis{
      my (  $trace_header_ref                                                       # input     Trace   information from trace file header
         ,  $ptr_ref                                                                #           Pointer information into transfer list
         ,  $opts_ref                                                               #           Command line options
         ,  $transfer_ref                                                           #           Transfer analysis
         ,  $latency_ref      ) = @_;                                               # output    Latency  analysis, %ahb_latency_new

      my $lath;                                                                     # File handle latency
      my $logfile     =             ${$opts_ref}{latency};
      my $cycle       =     ${$trace_header_ref}{period};                           # (float)
      my $tb          =     ${$trace_header_ref}{timebase};                         # =  $6; # (ns|ps)
      my $frequency   =     ${$trace_header_ref}{frequency};                        # (float)
      my $fb          =     ${$trace_header_ref}{freqbase};                         # (MHz|GHz)
      my $ptr_cur_cmd =     ${$ptr_ref}{start};                                     # See       restrict_window() there is no START for DATA transfers
      my $buffer_stop =   ${${$ptr_ref}{stop}}{next};                               #           Transaction following the Last transaction, Ring structure  
      my $transaction =   ${${$ptr_ref}{start}}{transaction};

      my $duration;                                                                 # duration of each DATA transfer

      printf  $proh  " ... latency    analysis new\n";
      if ( ${$opts_ref}{logging_latency} ) {
           printf $proh "     opening    latency log %s\n"   ,  $logfile;
           open ( $lath,">$logfile")|| die " Can not create log $logfile";             # Are the bus transfers accounted for ? Mendatory
           printf $lath " %s\n"       , '='x80;
           printf $lath " Tracefile   : %s\n"           ,${$trace_header_ref}{tracefile};
           printf $lath "               %s\n"           ,${$opts_ref}{trace_file};
           printf $lath " Synopsis    : %s\n"           ,'Latency Analysis';
           printf $lath " Script      : %s %s\n"        ,$0, $VERSION;                                   #  0  1, 2,    3,   4,    5,    6,    7,     8
           printf $lath " Date        : %4s-%02s-%02s\n",1900+$year,$mon,$cday;                          # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $lath " Time        : %4s:%02s:%02s\n",$h, $m,$s;                                      # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $lath " Cycle       : %10s %s\n"      ,$cycle, $tb;                                    # Header timebase information
           printf $lath " Frequency   : %10s %s\n"      ,$frequency, $fb;                                # Header frequency information
           printf $lath " Start       : %10s %s\n"      ,${${$ptr_ref}{start}}{assert},$tb;
           printf $lath " Stop        : %10s %s\n"      ,${${$ptr_ref}{stop}}{assert} ,$tb;
           printf $lath " %s\n"       , '='x80;
           printf $lath "\n";
           printf $lath "START pointer %s\n",   ${$ptr_ref}{start};
           printf $lath "Transaction#  %s\n", ${${$ptr_ref}{start}}{transaction};
           printf $lath "Start time    %s\n", ${${$ptr_ref}{start}}{assert};
           printf $lath "\n";
           printf $lath "STOP  pointer %s\n",   ${$ptr_ref}{stop};
           printf $lath "Transaction#  %s\n", ${${$ptr_ref}{stop}}{transaction};
           printf $lath "Stop time     %s\n", ${${$ptr_ref}{stop}}{assert};
           printf $lath "\n";
      }#logging

      do {
          my ($direction, $ctype) = split /-/ , ${$ptr_cur_cmd}{direction};
          my $phase               = ($ctype eq 'NONSEQ') ? 'ADDR' : 'IDLE';                       # NONSEQ, IDLE, SEQ/DATA, BUSY        Recoding  ADDR
          my $cmd                 = ($direction eq 'RD') ? 'READ' : 'WRITE';                      # Encode    READ vs RD; WRITE vs WR   Recoding  READ / WRITE

          my $L                   = ${$transfer_ref}{$transaction}{ADDR}{length};                 # LAST beat
          my $concealed           = ${$transfer_ref}{$transaction}{ADDR}{concealed};
          if ( ${$opts_ref}{logging_latency} ) {
               printf $lath "%*s %s %10s\n"      ,12, '', 'Transaction:', $transaction;
               printf $lath "%*s %s %10s\n"      ,12, '', 'Direction  :', $cmd;
               printf $lath "%*s %s %10s beat\n" ,12, '', 'BurstLength:', $L;
               printf $lath "%*s %s %10s\n"      ,12, '', 'Addr Phase :', ($concealed =~ m/NOT/ )
                                                                        ? 'visible'
                                                                        : 'concealed';
          }#logging

          #
          # Warning the latency considers only DATA transfers including WAIT states or BUSY cycles
          # No ADDR phase is considered in this analysis
          #

          my $i_duration                   = ${$transfer_ref}{$transaction}{IDLE}{duration};
          ${$latency_ref}{IDLE}{total}    += $i_duration;
          ${$latency_ref}{IDLE}{number}   += 1            if ($i_duration > 0);
          # First DATA transfer latency
          my $f_duration                   = ${$transfer_ref}{$transaction}{DATA}{1}{duration};
          # Last  DATA transfer latency    :   duration of all  DATA transfers combined/total burst
          my $l_duration                   = ${$transfer_ref}{$transaction}{DATA}{$L}{transferstop}                        # Not a single transfer analysis
                                           - ${$transfer_ref}{$transaction}{ADDR}{transferstop};
          if ( ${$opts_ref}{logging_latency} ) {
               printf $lath "%*s %s %10s %s\n",12,'','ADDRtransfr:',${$transfer_ref}{$transaction}{ADDR}{duration}        ,$tb;
               printf $lath "%*s %s %10s %s\n",12,'','FirstData  :',$f_duration, $tb;
               printf $lath "%*s %s %10s %s\n",12,'','AdrPhaseCmp:',${$transfer_ref}{$transaction}{ADDR}{transferstart}   ,$tb;
               printf $lath "%*s %s %10s %s\n",12,'','LastDataCmp:',${$transfer_ref}{$transaction}{DATA}{$L}{transferstop},$tb;
               printf $lath "%*s %s %10s %s\n",12,'','DtaPhaseCmp:',$l_duration, $tb;
          }#logging

          #
          # First data transfer 
          #

          ${$latency_ref}{1}{ALL}{total}     += $f_duration;                                                    # ALL READ & WRITE
          ${$latency_ref}{1}{ALL}{number}    += 1;                                                              # ALL transaction
          ${$latency_ref}{1}{ALL}{minimum}    = $f_duration if (${$latency_ref}{1}{ALL}{minimum} >= $f_duration); 
          ${$latency_ref}{1}{ALL}{maximum}    = $f_duration if (${$latency_ref}{1}{ALL}{maximum} <= $f_duration);

          ${$latency_ref}{1}{$cmd}{total}    += $f_duration;
          ${$latency_ref}{1}{$cmd}{number}   += 1;                                                              # ALL READ, ALL WRITE
          ${$latency_ref}{1}{$cmd}{minimum}   = $f_duration if (${$latency_ref}{1}{$cmd}{minimum} >= $f_duration); 
          ${$latency_ref}{1}{$cmd}{maximum}   = $f_duration if (${$latency_ref}{1}{$cmd}{maximum} <= $f_duration); 

          #
          # Last  data transfer 
          #
 
          ${$latency_ref}{L}{ALL}{total}    += $l_duration;
          ${$latency_ref}{L}{ALL}{number}   += 1;
          ${$latency_ref}{L}{ALL}{minimum}   = $l_duration if (${$latency_ref}{L}{ALL}{minimum} >= $l_duration); 
          ${$latency_ref}{L}{ALL}{maximum}   = $l_duration if (${$latency_ref}{L}{ALL}{maximum} <= $l_duration);


          ${$latency_ref}{L}{$cmd}{total}   += $l_duration;
          ${$latency_ref}{L}{$cmd}{number}  += 1;
          ${$latency_ref}{L}{$cmd}{minimum}  = $l_duration if (${$latency_ref}{L}{$cmd}{minimum} >= $l_duration);
          ${$latency_ref}{L}{$cmd}{maximum}  = $l_duration if (${$latency_ref}{L}{$cmd}{maximum} <= $l_duration);

          printf $lath "\n" if ( ${$opts_ref}{logging_latency} );       # Spacer
          $ptr_cur_cmd = ${$ptr_cur_cmd}{next};                         # iterate to next transaction
          $transaction++;                                               # iterate to next transaction     
      } until ( $ptr_cur_cmd == $buffer_stop );

      ${$latency_ref}{1}{ALL  }{average} = ${$latency_ref}{1}{ALL  }{total} / ${$latency_ref}{1}{ALL  }{number};
      ${$latency_ref}{1}{READ }{average} = ${$latency_ref}{1}{READ }{total} / ${$latency_ref}{1}{READ }{number};
      ${$latency_ref}{1}{WRITE}{average} = ${$latency_ref}{1}{WRITE}{total} / ${$latency_ref}{1}{WRITE}{number};
          
      ${$latency_ref}{L}{ALL  }{average} = ${$latency_ref}{L}{ALL  }{total} / ${$latency_ref}{L}{ALL  }{number};
      ${$latency_ref}{L}{READ }{average} = ${$latency_ref}{L}{READ }{total} / ${$latency_ref}{L}{READ }{number};
      ${$latency_ref}{L}{WRITE}{average} = ${$latency_ref}{L}{WRITE}{total} / ${$latency_ref}{L}{WRITE}{number};

      if ( ${$opts_ref}{logging_latency} ) {
           printf $lath "%*s %s %10s\n",12,'','ALL   1st Number:',${$latency_ref}{1}{ALL  }{number};  
           printf $lath "%*s %s %10s\n",12,'','READ  1st Number:',${$latency_ref}{1}{READ }{number};  
           printf $lath "%*s %s %10s\n",12,'','WRITE 1st Number:',${$latency_ref}{1}{WRITE}{number}; 
           printf $lath "\n";
           printf $lath "%*s %s %10s\n",12,'','READ  1st Total :',${$latency_ref}{1}{READ }{total };  
           printf $lath "%*s %s %10s\n",12,'','WRITE 1st Total :',${$latency_ref}{1}{WRITE}{total }; 
           printf $lath "%*s %s %10s\n",12,'','ALL   Lst Number:',${$latency_ref}{L}{ALL  }{number};  
           printf $lath "%*s %s %10s\n",12,'','READ  Lst Number:',${$latency_ref}{L}{READ }{number};  
           printf $lath "%*s %s %10s\n",12,'','WRITE Lst Number:',${$latency_ref}{L}{WRITE}{number};
           #printf $lath "%*s %s %10s %s\n"   ,12, '', 'AdrPhaseCmp:', $tb;
           close( $lath );
           printf $proh  "     closing    latency log %s\n", $logfile;
      }#logging

      printf $proh  " ... latency    analysis new done\n";
}#sub latency_analysis


sub   bandwidth_analysis {
      my (  $trace_header_ref                                                                       # Input     Trace   information from trace file header
         ,  $ptr_ref                                                                                #           Pointer information into transfer/trace list
         ,  $opts_ref                                                                               #           Command line options
         ,  $transfer_ref                                                                           #           Transfer analysis
         ,  $bandwidth_ref                                                                          # Output    Bandwidth analysis   %ahb_bandwidth_new
         ,  $transaction_ref    ) = @_;                                                             #           Transaction analysis %ahb_transaction_new

      my $banh;                                                                                     # File handle bandwidth
      my $logfile     =           ${$opts_ref}{bandwidth};
      my $cycle       =   ${$trace_header_ref}{period};                                             # (float)
      my $tb          =   ${$trace_header_ref}{timebase};                                           # =  $6; # (ns|ps)
      my $frequency   =   ${$trace_header_ref}{frequency};                                          # (float)
      my $fb          =   ${$trace_header_ref}{freqbase};                                           # (MHz|GHz)
      my $ptr_cur_cmd =   ${$ptr_ref}{start};                                                       # Initialize starting point in transaction list 
      my $buffer_stop =   ${${$ptr_ref}{stop}}{next};                                               #            Transaction following the Last transaction, Ring structure  
      my $transaction =   ${${$ptr_ref}{start}}{transaction};

      printf $proh "\n";
      printf $proh " ... bandwidth  analysis new\n";
      if ( ${$opts_ref}{logging_bandwidth} ) {
           printf $proh "     opening    bandwidth log %s\n" ,  $logfile;
           open ( $banh,">$logfile")|| die " Can not create log $logfile";                             # Bandwidth log 

           printf $banh " %s\n"       , '='x80;
           printf $banh " Tracefile   : %s\n"           ,${$trace_header_ref}{tracefile};
           printf $banh "               %s\n"           ,${$opts_ref}{trace_file};
           printf $banh " Synopsis    : %s\n"           ,'Bandwidth Analysis';
           printf $banh " Script      : %s %s\n"        ,$0, $VERSION;                                #  0  1, 2,    3,   4,    5,    6,    7,     8
           printf $banh " Date        : %4s-%02s-%02s\n",1900+$year,$mon,$cday;                       # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $banh " Time        : %4s:%02s:%02s\n",$h, $m,$s;                                   # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $banh " Cycle       : %10s %s\n"      ,$cycle, $tb;                                 # Header timebase information
           printf $banh " Frequency   : %10s %s\n"      ,$frequency, $fb;                             # Header frequency information
           printf $banh " Start       : %10s %s\n"      ,${${$ptr_ref}{start}}{assert},$tb;
           printf $banh " Stop        : %10s %s\n"      ,${${$ptr_ref}{stop}}{assert} ,$tb;
           printf $banh " %s\n"       , '='x80;
           printf $banh "\n";
           printf $banh "START pointer %s\n",   ${$ptr_ref}{start};
           printf $banh "Transaction#  %s\n", ${${$ptr_ref}{start}}{transaction};
           printf $banh "Start time    %s\n", ${${$ptr_ref}{start}}{assert};
           printf $banh "\n";
           printf $banh "STOP  pointer %s\n",   ${$ptr_ref}{stop};
           printf $banh "Transaction#  %s\n", ${${$ptr_ref}{stop}}{transaction};
           printf $banh "Stop time     %s\n", ${${$ptr_ref}{stop}}{assert};
           printf $banh "\n";
      }#logging

      my $bytes_transfered = 0;
      my $bytes_read       = 0;
      my $bytes_write      = 0;

      my $total_time       = 0;
      my $total_idle       = 0;
      my $total_addr       = 0;
      my $total_data       = 0;
      my $total_busy       = 0;
                               
      do {
          my ($direction, $ctype) = split /-/ , ${$ptr_cur_cmd}{direction};                             # extract direction information
          my $payload             =             ${$ptr_cur_cmd}{payload};                               # extract payload [byte] information
          my $phase               = ($ctype eq 'NONSEQ') ? 'ADDR' : 'IDLE';                             # NONSEQ,   IDLE, SEQ/DATA, BUSY      Recoding  ADDR
          my $cmd                 = ($direction eq 'RD') ? 'READ' : 'WRITE';                            # Encode    READ vs RD; WRITE vs WR   Recoding  READ/WRITE
          my $idle                = ${$transfer_ref}{$transaction}{IDLE}{duration};                     # IDLE phase
          my $addr                = ${$transfer_ref}{$transaction}{ADDR}{duration};                     # ADDR phase
          my $data                = ${$transfer_ref}{$transaction}{DATA}{total}{duration};              # DATA phase
          my $busy                = ${$transfer_ref}{$transaction}{BUSY}{total}{duration};              #            WAIT  states
          my $L                   = ${$transfer_ref}{$transaction}{ADDR}{length};                       # LAST beat  Burst length
          my $concealed           = ${$transfer_ref}{$transaction}{ADDR}{concealed};                    # Visible/concealed ADDR phase

          if ( ${$opts_ref}{logging_bandwidth} ) {
               printf $banh "%*s %s %10s\n"  ,12, '', 'Transaction:', $transaction;
               printf $banh "%*s %s %10s\n"  ,12, '', 'Direction  :', $cmd;
               printf $banh "%*s %s %10s%s\n",12, '', 'BurstLength:', $L,' beat';
               printf $banh "%*s %s %10s\n"  ,12, '', 'Addr Phase :', ($concealed =~ m/NOT/ )
                                                                    ? 'visible'
                                                                    : 'concealed';
               printf $banh "%*s %s %10s\n"  ,12, '', 'IDLE Phase :', $idle  if (     $idle  > 0      );     # NOT Back2Back    commands
               printf $banh "%*s %s %10s\n"  ,12, '', 'ADDR Phase :', $addr  if ($concealed =~ m/NOT/ );     # No  interleaving commands
               printf $banh "%*s %s %10s\n"  ,12, '', 'DATA Phase :', $data  if (     $data  > 0      );     # Should be always true
               printf $banh "%*s %s %10s\n"  ,12, '', 'BUSY Phase :', $busy  if (     $busy  > 0      );     # In case of WAIT states
               printf $banh "\n"; # Spacer
          }#logging

          $total_time   += $idle + $data;
          $total_time   += $addr  if ($concealed =~ m/NOT/ );

          $total_idle   += $idle;
          $total_addr   += $addr  if ($concealed =~ m/NOT/ );
          $total_data   += $data;
          $total_busy   += $busy;

          ${$bandwidth_ref}{$cmd}{addr}     += $addr if ($concealed =~ m/NOT/ );
          ${$bandwidth_ref}{$cmd}{data}     += $data;
          ${$bandwidth_ref}{$cmd}{busy}     += $busy;
          ${$bandwidth_ref}{$cmd}{time}     += $addr if ($concealed =~ m/NOT/ );
          ${$bandwidth_ref}{$cmd}{time}     += $data;

          ${$bandwidth_ref}{ALL}{payload}   += $payload;
          ${$bandwidth_ref}{$cmd}{payload}  += $payload;
          
          $transaction++;
          $ptr_cur_cmd   = ${$ptr_cur_cmd}{next};
      } until ( $ptr_cur_cmd == $buffer_stop );

      ${$bandwidth_ref}{ALL}{totaltime} = $total_time;
      ${$bandwidth_ref}{ALL}{totalidle} = $total_idle;
      ${$bandwidth_ref}{ALL}{totaladdr} = $total_addr;
      ${$bandwidth_ref}{ALL}{totaldata} = $total_data;
      ${$bandwidth_ref}{ALL}{totalbusy} = $total_busy;
      
      if ( ${$opts_ref}{logging_bandwidth} ) {
           printf $banh "\n\n";
           printf $banh "%*s %s %10s %s\n" ,12, '', 'Total Time :',$total_time, $tb; 
           printf $banh "\n";
           printf $banh "%*s %s %10s %s\n" ,12, '', 'Total Idle :',$total_idle, $tb; 
           printf $banh "%*s %s %10s %s\n" ,12, '', 'Total Addr :',$total_addr, $tb; 
           printf $banh "%*s %s %10s %s\n" ,12, '', 'Total Data :',$total_data, $tb; 
           printf $banh "%*s %s %10s %s\n" ,12, '', 'Total Busy :',$total_busy, $tb; 
           printf $banh "\n";
           printf $banh "%*s %s %10s %s\n" ,12, '', 'Total Idle :',${$bandwidth_ref}{ALL}{totalidle}, $tb; 
           printf $banh "%*s %s %10s %s\n" ,12, '', 'READ  Time :',${$bandwidth_ref}{READ}{time}    , $tb;
           printf $banh "%*s %s %10s %s\n" ,12, '', 'READ  Busy :',${$bandwidth_ref}{READ}{busy}    , $tb;
           printf $banh "%*s %s %10s %s\n" ,12, '', 'WRITE Time :',${$bandwidth_ref}{WRITE}{time}   , $tb;
           printf $banh "%*s %s %10s %s\n" ,12, '', 'WRITE Busy :',${$bandwidth_ref}{WRITE}{busy}   , $tb;
           printf $banh "\n";
           printf $banh "%*s %s %10s %s\n" ,12, '', 'Payload    :',${$bandwidth_ref}{ALL}{payload}  ,'btye'; 
           printf $banh "%*s %s %10s %s\n" ,12, '', '   READ    :',${$bandwidth_ref}{READ}{payload} ,'btye'; 
           printf $banh "%*s %s %10s %s\n" ,12, '', '   WRITE   :',${$bandwidth_ref}{WRITE}{payload},'btye'; 
           close( $banh );
           printf $proh  "     closing    bandwidth log %s\n", $logfile;
      }#logging
      printf $proh " ... bandwidth  analysis new done\n";
}#sub bandwidth_analysis


sub   report_info {
      my ( $trace_header_ref                                                                        # Trace information
         , $ptr_ref                                                                                 # transaction trace pointer
         , $opts_ref      ) = @_;                                                                   # command line arguments

      my $cycle       = ${$trace_header_ref}{period};                                               # (float)
      my $tb          = ${$trace_header_ref}{timebase};                                             # =  $6; # (ns|ps)
      my $frequency   = ${$trace_header_ref}{frequency};                                            # (float)
      my $fb          = ${$trace_header_ref}{freqbase};                                             # (MHz|GHz)
      my $logfile     = ${$opts_ref}{window};
      my $transaction = 0;

      printf " ... initialize transfer analysis\n";
      printf " %s\n", '='x80;
      printf " Tracefile : %s\n"           , ${$trace_header_ref}{tracefile};
      printf "             %s\n"           , ${$opts_ref}{trace_file};
      printf " Logfile   : %s\n"           , $logfile; 
      printf " Script    : %s %s\n"        , $0, $VERSION;                                          #  0  1, 2,    3,   4,    5,    6,    7,     8
      printf " Date      : %4s-%02s-%02s\n", 1900+$year,$mon,$cday;                                 # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf " Time      : %4s:%02s:%02s\n", $h, $m,$s;                                             # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf " Cycle     : %10s %s\n"      , $cycle, $tb;
      printf " Frequency : %10s %s\n",     , $frequency, $fb;
      printf " %s\n", '='x80;
      
      ${$opts_ref}{from}  = ${${${$ptr_ref}{first}}}{assert} if ( !defined ${$opts_ref}{from}  );   # Set default
      ${$opts_ref}{until} = ${${${$ptr_ref}{last}}}{assert}  if ( !defined ${$opts_ref}{until} );   # Set default

      printf " TraceStart: %12s %s\n",${${${$ptr_ref}{first}}}{assert},$tb;
      printf " TraceEnd  : %12s %s\n",${${${$ptr_ref}{last }}}{assert},$tb;
      printf " Starting  : %12s %s\n",${$opts_ref}{from}              ,$tb;
      printf " Ending    : %12s %s\n",${$opts_ref}{until}             ,$tb;

      open (my $winh, ">$logfile")        || die " Can not create log $logfile";

      if ( ${$opts_ref}{from}   < ${${${$ptr_ref}{first}}}{assert} ) {
           printf " Starting time point out of bound to the lower side of trace window\n";
      }
      if ( ${$opts_ref}{from}   > ${${${$ptr_ref}{last }}}{assert} ) {
           printf " Starting time point out of bound to the upper side of trace window\n";
      }
      if ( ${$opts_ref}{until}  < ${${${$ptr_ref}{first}}}{assert} ) {
           printf " Ending   time point out of bound to the lower side of trace window\n";
      }
      if ( ${$opts_ref}{until}  > ${${${$ptr_ref}{last }}}{assert} ) {
           printf " Ending   time point out of bound to the upper side of trace window\n";
      }
      if ( ${$opts_ref}{until}  < ${$opts_ref}{from} ) {                                            # The start and end time would select just one Transfer
          printf  " Ending   time is earlier than the Starting time :: Contradiction !!\n";
      }
      
      my $stop_ptr   =   ${${$ptr_ref}{first}};                                                     # Set buffer stop pointer
      my $search_ptr =   ${${$ptr_ref}{first}};                                                     # Set search      pointer to the FIRST  pointer of Transfer List
      my $next_ptr   = ${${${$ptr_ref}{first}}}{next};                                              # Set lookahead   pointer to the NEXT   pointer of Transfer List

      do {
          #
          #  1) Transfer assertion is earlier   as   the START window
          #
          #  2) Transfer assertion is identical with the START window
          #
          #  3) Transfer assertion is past           the START window
          #
          $transaction++;
          printf $winh "%*s %s  %15s\n"  , 8,'', 'Transaction ', $transaction;
          printf $winh "%*s %s  %15s\n"  , 8,'', 'TransferTime', ${$search_ptr}{assert};
          printf $winh "%*s %s  %15s"    , 8,'', 'Pointer     ', $search_ptr;
          
          if (  ${$search_ptr}{assert}  == ${$opts_ref}{from}                                       # Set START       pointer as the BEGIN  pointer in Transfer List
                                                                                                    # specifically    if at      FIRST    and ULTIMARE    transfer
             ||(${$search_ptr}{assert}   < ${$opts_ref}{from} &&                                    #                 if between                any two   transfers
                ${$next_ptr  }{assert}   > ${$opts_ref}{from}   )                                   # specifically    if between ULTIMATE and PENULTIMATE transfer
             ) {   
                ${${$ptr_ref}{start}}    = $search_ptr;
                printf $winh "\t%s  %15s", 'STARTWINDOW ', ${${$ptr_ref}{start}};
          }
          if (  ${$search_ptr}{assert}  == ${$opts_ref}{until}                                      # Set END         pointer as the ENDING pointer in Transfer List
                                                                                                    # specifically    if at      ULTIMATE or at any other transfer
             ||(${$search_ptr}{assert}   < ${$opts_ref}{until} &&                                   #                 if between                any two   transfers
                ${$next_ptr  }{assert}   > ${$opts_ref}{until}   )                                  # specifically    if between ULTIMATE and PENULTIMATE transfer
             ) {
                ${${$ptr_ref}{stop}}     = $search_ptr;
                printf $winh "\t%s  %15s", 'STOP WINDOW ', ${${$ptr_ref}{stop}};                
          }
          printf $winh "\n";
          $search_ptr = ${$search_ptr}{next};
          $next_ptr   = ${$search_ptr}{next};                   #

      } until ($search_ptr == $stop_ptr );
      
      printf "%*sSTART pointer %s\n",5,'',${${$ptr_ref}{start}};
      printf "%*sSTOP  pointer %s\n",5,'',${${$ptr_ref}{stop}};
      
}#sub report_info


sub   restrict_window {
      my    (   $opts_ref                                                                           # Input     Command line options
            ,   $trace_header_ref                                                                   #           Trace   information from trace file header
            ,   $ptr_ref            )   = @_;                                                       # Output    Change  transaction trace pointer

      my $winh;
      my $logfile     = ${$opts_ref}{window};
      my $cycle       = ${$trace_header_ref}{period};                                               # (float)
      my $tb          = ${$trace_header_ref}{timebase};                                             # =  $6; # (ns|ps)
      my $frequency   = ${$trace_header_ref}{frequency};                                            # (float)
      my $fb          = ${$trace_header_ref}{freqbase};                                             # (MHz|GHz)
      my $transaction = 0;

      printf $proh  "\n";
      printf $proh  " ... restrict window ... \n";
      
      if ( !defined ${$opts_ref}{START}  ) {                                                        # IF NO COMMAND LINE OVERWRITE
            ${$opts_ref}{from}  = ${${$ptr_ref}{adr}{first}}{assert};                               # Set default   begin of trace file first assert
      } else {
            ${$opts_ref}{from}  = ${$opts_ref}{START};                                              # WARNING OVERWRITE from command line
      }
      if ( !defined ${$opts_ref}{STOP} ) {                                                          # IF NO COMMAND LINE OVERWRITE
            ${$opts_ref}{until} = ${${$ptr_ref}{adr}{last}}{assert};                                # Set default   end of trace file last assert
      } else {
            ${$opts_ref}{until} = ${$opts_ref}{STOP};                                               # WARNING OVERWRITE from command line
      }

      if ( ${$opts_ref}{logging_window} ) {
           printf $proh  "     opening WindowLogFile %s\n", $logfile;
           open ( $winh, ">$logfile") || die " Can not create log $logfile";
           printf $winh " %s\n", '='x90;
           printf $winh " Tracefile : %s\n"           ,${$trace_header_ref}{tracefile};             # This is the old reporting parameter redundance !!
           printf $winh "           : %s\n"           ,${$opts_ref}{trace_file};                    # This is the new driving parameter
           printf $winh " Logfile   : %s\n"           ,$logfile; 
           printf $winh " Script    : %s %s\n"        ,$0, $VERSION;                                #  0  1, 2,    3,   4,    5,    6,    7,     8
           printf $winh " Date      : %4s-%02s-%02s\n",1900+$year,$mon,$cday;                       # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $winh " Time      : %4s:%02s:%02s\n",$h, $m,$s;                                   # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $winh " Cycle     : %10s %s\n"      ,$cycle, $tb;
           printf $winh " Frequency : %10s %s\n",     ,$frequency, $fb;
           printf $winh " %s\n", '='x90;
      }#logging

      if ( ${$opts_ref}{from}   < ${${$ptr_ref}{adr}{first}}{assert} ) {
           printf STDERR" Starting time point out of bound to the lower side of trace window\n";    # None maskable error
           if ( ${$opts_ref}{logging_window} ) {
                printf $winh " Starting time point out of bound to the lower side of trace window\n";
           }#logging
      }
      if ( ${$opts_ref}{from}   > ${${$ptr_ref}{adr}{last }}{assert} ) {
           printf STDERR" Starting time point out of bound to the upper side of trace window\n";    # None maskable error
           if ( ${$opts_ref}{logging_window} ) {
                printf $winh " Starting time point out of bound to the upper side of trace window\n";
           }#logging
      }
      if ( ${$opts_ref}{until}  < ${${$ptr_ref}{adr}{first}}{assert} ) {
           printf STDERR" Ending   time point out of bound to the lower side of trace window\n";    # None maskable error
           if ( ${$opts_ref}{logging_window} ) {
                printf $winh " Ending   time point out of bound to the lower side of trace window\n";
           }#logging
      }
      if ( ${$opts_ref}{until}  > ${${$ptr_ref}{adr}{last }}{assert} ) {
           printf STDERR" Ending   time point out of bound to the upper side of trace window\n";    # None maskable error
           if ( ${$opts_ref}{logging_window} ) {
                printf $winh " Ending   time point out of bound to the upper side of trace window\n";
           }#logging
      }
      if ( ${$opts_ref}{until}  < ${$opts_ref}{from} ) {                                            # The start and end time would select just one Transfer
           printf  STDERR" Ending   time is earlier than the Starting time :: Contradiction !!\n";  # None maskable error
           if ( ${$opts_ref}{logging_window} ) {
                printf $winh " Ending   time is earlier than the Starting time :: Contradiction !!\n";
           }#logging
      }
      
      my $stop_ptr   =   ${$ptr_ref}{adr}{first};                                                   # Set buffer stop pointer
      my $search_ptr =   ${$ptr_ref}{adr}{first};                                                   # Set search      pointer to the FIRST  pointer of Transfer List
      my $next_ptr   = ${${$ptr_ref}{adr}{first}}{next};                                            # Set lookahead   pointer to the NEXT   pointer of Transfer List

      do {
          #
          #  1) Transfer assertion is earlier   as   the START window
          #
          #  2) Transfer assertion is identical with the START window
          #
          #  3) Transfer assertion is past           the START window
          #
          $transaction++;
          if ( ${$opts_ref}{logging_window} ) {
               printf $winh "%*s %s  %15s\n",12,'','Transaction  ',$transaction;
               printf $winh "%*s %s  %15s\n",12,'','TransferTime ',${$search_ptr}{assert};
               printf $winh "%*s %s  %15s"  ,12,'','Pointer      ',$search_ptr;
          }#logging
          
          if (  ${$search_ptr}{assert}  == ${$opts_ref}{from}                                       # Set START       pointer as the BEGIN  pointer in Transfer List
                                                                                                    # specifically    if at      FIRST    and ULTIMARE    transfer
             ||(${$search_ptr}{assert}   < ${$opts_ref}{from} &&                                    #                 if between                any two   transfers
                ${$next_ptr  }{assert}   > ${$opts_ref}{from}   )                                   # specifically    if between ULTIMATE and PENULTIMATE transfer
             ) {   
                ${$ptr_ref}{start} = $search_ptr;
                if ( ${$opts_ref}{logging_window} ) {
                     printf $winh "\t%s  %15s", 'STARTWINDOW ', ${$ptr_ref}{start};
                }#logging
          }
          if (  ${$search_ptr}{assert}  == ${$opts_ref}{until}                                      # Set END         pointer as the ENDING pointer in Transfer List
                                                                                                    # specifically    if at      ULTIMATE or at any other transfer
             ||(${$search_ptr}{assert}   < ${$opts_ref}{until} &&                                   #                 if between                any two   transfers
                ${$next_ptr  }{assert}   > ${$opts_ref}{until}   )                                  # specifically    if between ULTIMATE and PENULTIMATE transfer
             ) {
                ${$ptr_ref}{stop}     = $search_ptr;
                if ( ${$opts_ref}{logging_window} ) {
                     printf $winh "\t%s  %15s", 'STOP WINDOW ', ${$ptr_ref}{stop};
                }#logging
          }
          printf $winh "\n" if ( ${$opts_ref}{logging_window} );                                    # Spacer
          $search_ptr = ${$search_ptr}{next};
          $next_ptr   = ${$search_ptr}{next};
      } until ( $search_ptr == $stop_ptr );
      
      if ( defined ${$opts_ref}{debug_trace} ) {                                                    # logg start and end pointer for transfer list
            printf $proh "%*sSTART pointer %s\n",5,'',${$ptr_ref}{start};
            printf $proh "%*sSTOP  pointer %s\n",5,'',${$ptr_ref}{stop};
      }#logging

      if ( ${$opts_ref}{logging_window} ) {
            printf $winh "\n";
            printf $winh " TraceStart: %10s %s\n" , ${${$ptr_ref}{adr}{first}}{assert}, $tb;
            printf $winh " TraceEnd  : %10s %s\n" , ${${$ptr_ref}{adr}{last }}{assert}, $tb;
            printf $winh " Starting  : %10s %s\n" , ${$opts_ref}{from}                , $tb;
            printf $winh " Ending    : %10s %s\n" , ${$opts_ref}{until}               , $tb;
            printf $winh "\n";
            printf $winh " START pointer %s\n", ${$ptr_ref}{start};
            printf $winh " STOP  pointer %s\n", ${$ptr_ref}{stop};
            close( $winh );
            printf $proh  "     closing WindowLogFile %s\n", $logfile;
      }#logging

      printf $proh  " ... restrict window done\n";

}#sub restrict_window

#
#     This function is experimental, and as such not conform with bandwidth latency analysis
#

sub   overwrite_restrict_window {
      my    (   $opts_ref                                                                           # Input     Command line options
            ,   $trace_header_ref                                                                   #           Trace   information from trace file header
            ,   $ptr_ref            )   = @_;                                                       # Output    Change  transaction trace pointer

      my $logfile     = ${$opts_ref}{window};
      my $cycle       = ${$trace_header_ref}{period};                                               # (float)
      my $tb          = ${$trace_header_ref}{timebase};                                             # =  $6; # (ns|ps)
      my $frequency   = ${$trace_header_ref}{frequency};                                            # (float)
      my $fb          = ${$trace_header_ref}{freqbase};                                             # (MHz|GHz)
      my $transaction = 0;

      printf $proh  "\n";
      printf $proh  " ... overwrite restrict window ... \n";
      printf $proh  "     opening WindowLogFile %s\n", $logfile;
      
     #
     # Not all analysis needs a window restriction
     # The commandline restriction would exclude transactions, which should be considered
     #
     
      if ( !defined ${$opts_ref}{from}  ) {
            ${$opts_ref}{from}  = ${${$ptr_ref}{adr}{first}}{assert};                               # Set default
      }
      if ( !defined ${$opts_ref}{until} ) {
            ${$opts_ref}{until} = ${${$ptr_ref}{adr}{last}}{assert};                                # Set default
      }

      open (my $winh, ">$logfile")        || die " Can not create log $logfile";
      printf $winh " %s\n", '='x80;
      printf $winh " Tracefile : %s\n"           ,${$trace_header_ref}{tracefile};                  # This is the old reporting parameter redundance !!
      printf $winh "           : %s\n"           ,${$opts_ref}{trace_file};                         # This is the new driving parameter
      printf $winh " Logfile   : %s\n"           ,$logfile; 
      printf $winh " Script    : %s %s\n"        ,$0, $VERSION;                                     #  0  1, 2,    3,   4,    5,    6,    7,     8
      printf $winh " Date      : %4s-%02s-%02s\n",1900+$year,$mon,$cday;                            # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf $winh " Time      : %4s:%02s:%02s\n",$h, $m,$s;                                        # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf $winh " Cycle     : %10s %s\n"      ,$cycle, $tb;
      printf $winh " Frequency : %10s %s\n",     ,$frequency, $fb;
      printf $winh " %s\n", '='x80;

      if ( ${$opts_ref}{from}   < ${${$ptr_ref}{adr}{first}}{assert} ) {
           printf       " Starting time point out of bound to the lower side of trace window\n";
           printf $winh " Starting time point out of bound to the lower side of trace window\n";
      }
      if ( ${$opts_ref}{from}   > ${${$ptr_ref}{adr}{last }}{assert} ) {
           printf       " Starting time point out of bound to the upper side of trace window\n";
           printf $winh " Starting time point out of bound to the upper side of trace window\n";
      }
      if ( ${$opts_ref}{until}  < ${${$ptr_ref}{adr}{first}}{assert} ) {
           printf       " Ending   time point out of bound to the lower side of trace window\n";
           printf $winh " Ending   time point out of bound to the lower side of trace window\n";
      }
      if ( ${$opts_ref}{until}  > ${${$ptr_ref}{adr}{last }}{assert} ) {
           printf       " Ending   time point out of bound to the upper side of trace window\n";
           printf $winh " Ending   time point out of bound to the upper side of trace window\n";
      }
      if ( ${$opts_ref}{until}  < ${$opts_ref}{from} ) {                                            # The start and end time would select just one Transfer
           printf        " Ending   time is earlier than the Starting time :: Contradiction !!\n";
           printf  $winh " Ending   time is earlier than the Starting time :: Contradiction !!\n";
      }
      
      if ( defined ${$opts_ref}{overwrite} ) {
            printf        " OVERWRITE command line limitation !! of time window\n";
            printf  $winh " OVERWRITE command line limitation !! of time window\n";
            ${$opts_ref}{from}  = ${${$ptr_ref}{adr}{first}}{assert};                               # Set default
            ${$opts_ref}{until} = ${${$ptr_ref}{adr}{last}}{assert};                                # Set default
      }#WARNING this function overwrites the limiting scope of --from --until

      
      my $stop_ptr   =   ${$ptr_ref}{adr}{first};                                   # Set buffer stop pointer
      my $search_ptr =   ${$ptr_ref}{adr}{first};                                   # Set search      pointer to the FIRST  pointer of Transfer List
      my $next_ptr   = ${${$ptr_ref}{adr}{first}}{next};                            # Set lookahead   pointer to the NEXT   pointer of Transfer List

      do {
          #
          #  1) Transfer assertion is earlier   as   the START window
          #
          #  2) Transfer assertion is identical with the START window
          #
          #  3) Transfer assertion is past           the START window
          #
          $transaction++;
          printf $winh "%*s %s  %15s\n", 8,'','Transaction ',$transaction;
          printf $winh "%*s %s  %15s\n", 8,'','TransferTime',${$search_ptr}{assert};
          printf $winh "%*s %s  %15s"  , 8,'','Pointer     ',$search_ptr;
          
          if (  ${$search_ptr}{assert}  == ${$opts_ref}{from}                       # Set START       pointer as the BEGIN  pointer in Transfer List
                                                                                    # specifically    if at      FIRST    and ULTIMARE    transfer
             ||(${$search_ptr}{assert}   < ${$opts_ref}{from} &&                    #                 if between                any two   transfers
                ${$next_ptr  }{assert}   > ${$opts_ref}{from}   )                   # specifically    if between ULTIMATE and PENULTIMATE transfer
             ) {   
                ${$ptr_ref}{start} = $search_ptr;
                printf $winh "\t%s  %15s", 'STARTWINDOW ', ${$ptr_ref}{start};
          }
          if (  ${$search_ptr}{assert}  == ${$opts_ref}{until}                      # Set END         pointer as the ENDING pointer in Transfer List
                                                                                    # specifically    if at      ULTIMATE or at any other transfer
             ||(${$search_ptr}{assert}   < ${$opts_ref}{until} &&                   #                 if between                any two   transfers
                ${$next_ptr  }{assert}   > ${$opts_ref}{until}   )                  # specifically    if between ULTIMATE and PENULTIMATE transfer
             ) {
                ${$ptr_ref}{stop}     = $search_ptr;
                printf $winh "\t%s  %15s", 'STOP WINDOW ', ${$ptr_ref}{stop};                
          }
          printf $winh "\n";
          $search_ptr = ${$search_ptr}{next};
          $next_ptr   = ${$search_ptr}{next};                   #

      } until ( $search_ptr == $stop_ptr );
      
      printf $proh " START pointer %s\n", ${$ptr_ref}{start};
      printf $proh " STOP  pointer %s\n", ${$ptr_ref}{stop};

      printf $winh "\n";
      printf $winh " TraceStart: %10s %s\n" , ${${$ptr_ref}{adr}{first}}{assert}, $tb;
      printf $winh " TraceEnd  : %10s %s\n" , ${${$ptr_ref}{adr}{last }}{assert}, $tb;
      printf $winh " Starting  : %10s %s\n" , ${$opts_ref}{from}                , $tb;
      printf $winh " Ending    : %10s %s\n" , ${$opts_ref}{until}               , $tb;
      printf $winh "\n";
      printf $winh " START pointer %s\n", ${$ptr_ref}{start};
      printf $winh " STOP  pointer %s\n", ${$ptr_ref}{stop};

      close( $winh );
      printf $proh  "     closing WindowLogFile %s\n", $logfile;
      printf $proh  " ... overwrite restrict window done\n";
}#sub overwrite_restrict_window
    

sub   analysis_report{
      my    (  $trace_header_ref                                                        # Input     Trace   information from trace file header
            ,  $opts_ref                                                                #           Command line options
            ,  $latency_ref                                                             #           reference to %ahb_latency_new
            ,  $transfer_ref                                                            #           reference to %%ahb_transfer new
            ,  $bandwidth_ref                                                           #           reference to %%ahb_bandwidth_new
            ,  $transaction_ref    ) = @_;                                              #           reference to %%ahb_transaction_new

      my $logfile     = ${$opts_ref}{report};
       
      my $tb   = ${$trace_header_ref}{timebase};                                        # =  $6; # (ns|ps)
      my $scale = ($tb eq 'ms')?                      1000                              # ms
                : ($tb eq 'us')?               1000 * 1000                              # us
                : ($tb eq 'ns')?        1000 * 1000 * 1000                              # ns
                : ($tb eq 'ps')? 1000 * 1000 * 1000 * 1000                              # ps
                :         1000 * 1000 * 1000 * 1000 * 1000;                             # fs
      my $giga  =  1000 * 1000 * 1000;
      my $length_of_line = 91;

      printf  $proh "\n";
      printf  $proh " ... printing analysis report \n";
      printf  $proh  "     opening    analysis report %s\n" ,$logfile;
      open(my $anah, ">$logfile")|| die " Can not create log $logfile";                 # Analysis Report
      printf  $anah "Trace file     : %s\n",     ${$trace_header_ref}{tracefile} ;
      printf  $anah "Protocol       : %s\n",     ${$trace_header_ref}{protocol};
      printf  $anah "Data bus width : %s bit\n", ${$trace_header_ref}{databus};
      printf  $anah "Convention     : SI : giga = 1 000 000 000 = 10^9\n";              # IEC 2^10 gibibit JEDEC 
      printf  $anah "                      mega =     1 000 000 = 10^6\n";
      printf  $anah "                      kilo =         1 000 = 10^3\n";

      printf  $anah "\n\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah "Last  Data Latency ( Latency = Last  Data HREADY Assert time - Address HREADY Assert time )\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah "\n";
      printf  $anah " %s : %9s\n"        , '        total       transaction number',${$latency_ref}{L}{ALL  }{number};
      printf  $anah " %s : %13.3f %s\n"  , 'minimum transaction completion latency',${$latency_ref}{L}{ALL  }{minimum}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'average transaction completion latency',${$latency_ref}{L}{ALL  }{average}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'maximum transaction completion latency',${$latency_ref}{L}{ALL  }{maximum}, $tb;
      printf  $anah "\n";
      printf  $anah " %s : %9s\n"        , '        READ        transaction number',${$latency_ref}{L}{READ }{number};
      printf  $anah " %s : %13.3f %s\n"  , 'minimum READ        completion latency',${$latency_ref}{L}{READ }{minimum}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'average READ        completion latency',${$latency_ref}{L}{READ }{average}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'maximum READ        completion latency',${$latency_ref}{L}{READ }{maximum}, $tb;
      printf  $anah "\n";
      printf  $anah " %s : %9s\n"        , '        WRITE       transaction number',${$latency_ref}{L}{WRITE}{number};
      printf  $anah " %s : %13.3f %s\n"  , 'minimum WRITE       completion latency',${$latency_ref}{L}{WRITE}{minimum}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'average WRITE       completion latency',${$latency_ref}{L}{WRITE}{average}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'maximum WRITE       completion latency',${$latency_ref}{L}{WRITE}{maximum}, $tb;
      printf  $anah "\n";
 
      printf  $anah "\n\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah "First Data Latency ( Latency = First Data HREADY Assert time - Address HREADY Assert time )\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah "\n";
      printf  $anah " %s : %9s\n"        , '        total       transaction number',${$latency_ref}{1}{ALL  }{number};
      printf  $anah " %s : %13.3f %s\n"  , 'minimum transaction completion latency',${$latency_ref}{1}{ALL  }{minimum}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'average transaction completion latency',${$latency_ref}{1}{ALL  }{average}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'maximum transaction completion latency',${$latency_ref}{1}{ALL  }{maximum}, $tb;
      printf  $anah "\n";
      printf  $anah " %s : %9s\n"        , '        READ        transaction number',${$latency_ref}{1}{READ }{number};
      printf  $anah " %s : %13.3f %s\n"  , 'minimum READ        completion latency',${$latency_ref}{1}{READ }{minimum}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'average READ        completion latency',${$latency_ref}{1}{READ }{average}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'maximum READ        completion latency',${$latency_ref}{1}{READ }{maximum}, $tb;
      printf  $anah "\n";
      printf  $anah " %s : %9s\n"        , '        WRITE       transaction number',${$latency_ref}{1}{WRITE}{number};
      printf  $anah " %s : %13.3f %s\n"  , 'minimum WRITE       completion latency',${$latency_ref}{1}{WRITE}{minimum}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'average WRITE       completion latency',${$latency_ref}{1}{WRITE}{average}, $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'maximum WRITE       completion latency',${$latency_ref}{1}{WRITE}{maximum}, $tb;
      printf  $anah "\n";
      
      printf  $anah "\n\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah " Bandwidth Analysis\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah "\n";
   
      printf  $anah " %s : %9s %*s\n"    , 'Total  transfered   amount of data    ',${$bandwidth_ref}{ALL}{payload}   , 8,'byte';
      printf  $anah " %s : %9s %*s\n"    , 'Total  READ         amount of data    ',${$bandwidth_ref}{READ}{payload}  , 8,'byte';
      printf  $anah " %s : %9s %*s\n"    , 'Total  WRITE        amount of data    ',${$bandwidth_ref}{WRITE}{payload} , 8,'byte';
      printf  $anah "\n\n";

      printf  $anah " %s : %13.3f %s\n"  , 'Total  traced       period            ',${$bandwidth_ref}{ALL}{totaltime} , $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'Total  READ         time              ',${$bandwidth_ref}{READ}{time}     , $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'Total  WRITE        time              ',${$bandwidth_ref}{WRITE}{time}    , $tb;
      printf  $anah " %s : %13.3f %s\n"  , 'Total  IDLE         time              ',${$bandwidth_ref}{ALL}{totalidle} , $tb;
      printf  $anah "\n\n"; 

      printf  $anah " %s : %13.3f byte/s", 'Total  Bandwith     consumed          ',${$bandwidth_ref}{ALL}{payload}  /  ${$bandwidth_ref}{ALL}{totaltime} * $scale;
      printf  $anah " %10.3f Gbit/s\n"                                             ,${$bandwidth_ref}{ALL}{payload}  /  ${$bandwidth_ref}{ALL}{totaltime} * $scale / $giga * 8;
      printf  $anah " %s : %13.3f byte/s", 'READ   Bandwith     consumed          ',${$bandwidth_ref}{READ}{payload} /  ${$bandwidth_ref}{READ}{time}     * $scale;
      printf  $anah " %10.3f Gbit/s\n"                                             ,${$bandwidth_ref}{READ}{payload} /  ${$bandwidth_ref}{READ}{time}     * $scale / $giga * 8;
      printf  $anah " %s : %13.3f byte/s", 'WRITE  Bandwith     consumed          ',${$bandwidth_ref}{WRITE}{payload}/  ${$bandwidth_ref}{WRITE}{time}    * $scale;
      printf  $anah " %10.3f Gbit/s\n"                                             ,${$bandwidth_ref}{WRITE}{payload}/  ${$bandwidth_ref}{WRITE}{time}    * $scale / $giga * 8;
      printf  $anah "\n\n";
      report_transactions ( $anah                                                   #   filehandle
                          , $transaction_ref                                        #   %ahb_transaction
                          , 91               );                                     #   length of a report line

      #======================================================================================================================================

      printf  $anah "\n\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah " Latency per transaction\n";
      printf  $anah "%s\n", '='x$length_of_line;
      printf  $anah "\n\n";

      printf  $anah "Transaction\t\tTransaction\t\tSample time\t\tSample time\t\t    Latency\t\t    Latency\n";
      printf  $anah "\t number\t\t  assertion\t\t first_data\t\t  last_data\t\t first_data\t\t  last_data\n";       # Version 1.01.05 header
      printf  $anah "%s\n", '='x$length_of_line;

      # Version 1.01.06
      foreach my $transaction ( sort { $a <=> $b } keys %{$transfer_ref } ) {                                       # Sort numerically
          my $L = ${$transfer_ref}{$transaction}{ADDR}{length};                                                     # Last DATA beat, burst length
          printf $anah "#%10s"    , $transaction;                                                                   # First  column Transaction Number
          printf $anah "\t%12s %s", ${$transfer_ref}{$transaction}{ADDR}{transferstop}    , $tb;                    # Second column       ADDR transfer done 
          printf $anah "\t%12s %s", ${$transfer_ref}{$transaction}{DATA}{ 1}{transferstop}, $tb;                    # Third  column 1st   DATA transfer done 
          printf $anah "\t%12s %s", ${$transfer_ref}{$transaction}{DATA}{$L}{transferstop}, $tb;                    # Fourth column Last  DATA transfer done 
          printf $anah "\t%12s %s", ${$transfer_ref}{$transaction}{DATA}{ 1}{duration}    , $tb;                    # Fifth  column 1st   DATA transfer period 
          printf $anah "\t%12s %s", ${$transfer_ref}{$transaction}{DATA}{total}{duration} , $tb;                    # Sixth  column total DATA transfer period 
          printf $anah "\n";    
      }#foreach transaction/cmd NOT transfer

      printf $anah "%s\n", '='x$length_of_line;
      printf $anah "End of Analysis Report\n";
      printf $anah "%s\n", '='x$length_of_line;
      close( $anah );

      printf $proh  "     closing    analysis report %s\n", $logfile;
      printf $proh " ... printing analysis report done \n";

      if ( defined ${$opts_ref}{debug_trace} ) {
            printf " ... %s trace analysis done\n",$Trace{protocol};                                # debug     log Protocol on terminal
      }#debug 

}#sub analysis_report

sub   transaction2_analysis{
      my    (  $trace_header_ref                                                                    # Input     Trace   information from trace file header
            ,  $ptr_ref                                                                             #           Pointer information into transfer/trace list
            ,  $opts_ref                                                                            #           Command line options
            ,  $transaction_ref    ) = @_;                                                          # Output    %ahb_transaction_new

      my $tr2h;                                                                                     # File handle transaction2
      my $logfile     =           ${$opts_ref}{transaction2};
      my $cycle       =   ${$trace_header_ref}{period};                                             # (float)
      my $tb          =   ${$trace_header_ref}{timebase};                                           # =  $6; # (ns|ps)
      my $frequency   =   ${$trace_header_ref}{frequency};                                          # (float)
      my $fb          =   ${$trace_header_ref}{freqbase};                                           # (MHz|GHz)
      my $ptr_cur_cmd =   ${$ptr_ref}{start};                                                       # Initialize starting point in transaction list 
      my $buffer_stop =   ${${$ptr_ref}{stop}}{next};                                               # STOP Transaction following the Last transaction, Ring structure 
      my $transaction =   ${${$ptr_ref}{start}}{transaction};                                       #           Set ordinal transaction number

      printf  $proh  " ... TransactionAnalysis2 new\n";
      if ( ${$opts_ref}{logging_transaction} ) {
           printf $proh  "     opening    Transaction2Log %s\n",$logfile;
           open ( $tr2h,">$logfile")|| die " Can not create log $logfile";                          # Are the bus transfers accounted for ? Mendatory
           printf $tr2h " %s\n"       , '='x80;
           printf $tr2h " Tracefile   : %s\n"           ,${$trace_header_ref}{tracefile};
           printf $tr2h "               %s\n"           ,${$opts_ref}{trace_file};
           printf $tr2h " Synopsis    : %s\n"           ,'TransactionAnalysis windowed';
           printf $tr2h " Script      : %s %s\n"        ,$0, $VERSION;                              #  0  1, 2,    3,   4,    5,    6,    7,     8
           printf $tr2h " Date        : %4s-%02s-%02s\n",1900+$year,$mon,$cday;                     # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $tr2h " Time        : %4s:%02s:%02s\n",$h, $m,$s;                                 # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $tr2h " Cycle       : %10s %s\n"      ,$cycle, $tb;                               # Header timebase information
           printf $tr2h " Frequency   : %10s %s\n"      ,$frequency, $fb;                           # Header frequency information
           printf $tr2h " Start       : %10s %s\n"      ,${${$ptr_ref}{start}}{assert},$tb;
           printf $tr2h " Stop        : %10s %s\n"      ,${${$ptr_ref}{stop}}{assert} ,$tb;
           printf $tr2h " %s\n"       , '='x80;
           printf $tr2h "\n";
           printf $tr2h "START pointer %s\n",  ${$ptr_ref}{start};
           printf $tr2h "Transaction#  %s\n",${${$ptr_ref}{start}}{transaction};
           printf $tr2h "Start time    %s\n",${${$ptr_ref}{start}}{assert};
           printf $tr2h "\n";
           printf $tr2h "STOP  pointer %s\n",  ${$ptr_ref}{stop};
           printf $tr2h "Transaction#  %s\n",${${$ptr_ref}{stop}}{transaction};
           printf $tr2h "Stop time     %s\n",${${$ptr_ref}{stop}}{assert};
           printf $tr2h "\n";
      }#logging

      do {
          my $direction  = ${$ptr_cur_cmd}{direction};
          my $burst_type = ${$ptr_cur_cmd}{burst_type};
          my $burst_size = ${$ptr_cur_cmd}{burst_size};
          my $timestamp  = ${$ptr_cur_cmd}{assert};
          ${$transaction_ref}{transaction}{total}                               += 1;   # accounting starts with counting
          ${$transaction_ref}{transaction}{$burst_type}                         += 1;
          if ($direction =~ m{WR-NONSEQ} ){
              ${$transaction_ref}{transaction}{WRITE}{total}                    += 1;
              ${$transaction_ref}{transaction}{WRITE}{$burst_type}              += 1;
              ${$transaction_ref}{transaction}{$burst_size}{WRITE}{total}       += 1;
              ${$transaction_ref}{transaction}{$burst_size}{WRITE}{$burst_type} += 1;
          }
          if ($direction =~ m{RD-NONSEQ} ){
              ${$transaction_ref}{transaction}{READ}{total}                     += 1;
              ${$transaction_ref}{transaction}{READ}{$burst_type}               += 1;
              ${$transaction_ref}{transaction}{$burst_size}{READ}{total}        += 1;
              ${$transaction_ref}{transaction}{$burst_size}{READ}{$burst_type}  += 1;
          }
          if ( ${$opts_ref}{logging_transaction} ) {
            printf $tr2h "%6s # %12s %3s %s\n"
                         ,$transaction,$timestamp,$tb,${$transaction_ref}{transaction}{total};
          }#logging
          $transaction++;
          $ptr_cur_cmd   = ${$ptr_cur_cmd}{next};
      } until ( $ptr_cur_cmd == $buffer_stop );
      if ( ${$opts_ref}{logging_transaction} ) {
           report_transactions ( $tr2h                   #   filehandle
                               , $transaction_ref        #   %ahb_transaction
                               , 91               );     #   length of a report line
           close  $tr2h;
           printf $proh  "     closing    Transaction2log %s\n", $logfile;
      }#logging
      printf $proh  " ... TransactionAnalysis2 done\n";
}#sub transaction2_analysis 


sub   transaction_analysis {
      my    (   $trace_header_ref                                                       # Trace information
            ,   $trace_ref                                                              # Reference to global %AHB_hash, holding all ADDR transfers/ AHB transactions
                                                                                        #                                no DATA transfers are included in %AHB_hash
            ,   $opts_ref                                                               #           Command line options
            ,   $transaction_ref    ) = @_;                                             # %ahb_transaction_new

      my $cmdh;                                                                         # File handle for transaction logging
      my $logfile     =         ${$opts_ref}{transaction};
      my $cycle       = ${$trace_header_ref}{period};                                   # (float)
      my $tb          = ${$trace_header_ref}{timebase};                                 # =  $6; # (ns|ps)
      my $frequency   = ${$trace_header_ref}{frequency};                                # (float)
      my $fb          = ${$trace_header_ref}{freqbase};                                 # (MHz|GHz)

      printf $proh "\n";
      printf $proh " ... transaction analysis\n";

      if ( ${$opts_ref}{logging_transaction} ) {
           open ( $cmdh,">$logfile")|| die " Can not create log $logfile";              # Command as in Transaction 
           printf $proh "     opening    transaction log %s\n", $logfile;
           printf $cmdh " %s\n", '='x80;
           printf $cmdh " Tracefile   : %s\n"           ,${$trace_header_ref}{tracefile};
           printf $cmdh "               %s\n"           ,${$opts_ref}{trace_file};
           printf $cmdh " Synopsis    : %s\n"           
                        ,'Transaction Analysis, spanning multiple Transfers';
           printf $cmdh " Logfile     : %s\n"           ,$logfile; 
           printf $cmdh " Script      : %s %s\n"        ,$0, $VERSION;                  #  0  1, 2,    3,   4,    5,    6,    7,     8
           printf $cmdh " Date        : %4s-%02s-%02s\n",1900+$year,$mon,$cday;         # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $cmdh " Time        : %4s:%02s:%02s\n",$h, $m,$s;                     # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
           printf $cmdh " Cycle       : %10s %s\n"      ,$cycle, $tb;
           printf $cmdh " Frequency   : %10s %s\n",     ,$frequency, $fb;
           printf $cmdh " %s\n", '='x80;
      }#logging

      foreach my $timestamp (sort { $a <=> $b } keys %{$trace_ref}) {                   # The order is chronologic
          my $direction  = ${${$trace_ref}{$timestamp}}{direction};
          my $burst_type = ${${$trace_ref}{$timestamp}}{burst_type};
          my $burst_size = ${${$trace_ref}{$timestamp}}{burst_size};
          ${$transaction_ref}{transaction}{total}                               += 1;   # accounting starts with counting
          ${$transaction_ref}{transaction}{$burst_type}                         += 1;
          if ($direction =~ m{WR-NONSEQ} ){
              ${$transaction_ref}{transaction}{WRITE}{total}                    += 1;
              ${$transaction_ref}{transaction}{WRITE}{$burst_type}              += 1;
              ${$transaction_ref}{transaction}{$burst_size}{WRITE}{total}       += 1;
              ${$transaction_ref}{transaction}{$burst_size}{WRITE}{$burst_type} += 1;
          }
          if ($direction =~ m{RD-NONSEQ} ){
              ${$transaction_ref}{transaction}{READ}{total}                     += 1;
              ${$transaction_ref}{transaction}{READ}{$burst_type}               += 1;
              ${$transaction_ref}{transaction}{$burst_size}{READ}{total}        += 1;
              ${$transaction_ref}{transaction}{$burst_size}{READ}{$burst_type}  += 1;
          }
          if ( ${$opts_ref}{logging_transaction} ) {
            printf $cmdh "%6s # %12s\n", ${$transaction_ref}{transaction}{total}, $timestamp;
          }#logging
      }#foreach

      if ( ${$opts_ref}{logging_transaction} ) {
           report_transactions ( $cmdh                   #   filehandle
                               , $transaction_ref        #   %ahb_transaction
                               , 91               );     #   length of a report line
           close  $cmdh;
           printf $proh  "     closing    transaction log %s\n", $logfile;
      }#logging
      printf $proh  " ... transaction analysis done\n";
}#sub transaction_analysis


sub report_transactions {
    my  (    $fileh                                                                     # Input         Filehandle
        ,    $transaction_ref                                                           #               Reporting data structure
        ,    $length_of_line     ) = @_;                                                #               Formating information

    printf $fileh "%s\n", '='x$length_of_line;
    printf $fileh " Transaction Overview\n";
    printf $fileh "%s\n", '='x$length_of_line;
    printf $fileh "\n";

    my @_list = ( "SINGLE", "INCR", "INCR4", "INCR8", "INCR16"
                , "WRAP4", "WRAP8", "WRAP16", "total" );
    printf $fileh "   TOTAL transactions :: (by type)\n";
    foreach my $type ( @_list ){
        printf $fileh "   %8s : %4s transactions\n", $type,${$transaction_ref}{transaction}{$type};
    }
    printf $fileh "%s\n", '-'x$length_of_line;
    printf $fileh "   WRITE transactions :: (by type)\n";
    foreach my $type ( @_list ){
        printf $fileh "   %8s : %4s transactions\n", $type,${$transaction_ref}{transaction}{WRITE}{$type};
    }
    printf $fileh "%s\n", '-'x$length_of_line;
    printf $fileh "   READ  transactions :: (by type)\n";
    foreach my $type ( @_list ){
        printf $fileh "   %8s : %4s transactions\n", $type,${$transaction_ref}{transaction}{READ}{$type};
    }
    printf $fileh "\n";
    printf $fileh "%s\n", '='x$length_of_line;
    printf $fileh "   WRITE transactions :: (by size, type)\n";
    foreach my $size ( ( 1, 2, 4 ) ){   # byte
        printf $fileh "   %s byte wide burst\n", $size;
        foreach my $type ( @_list ) {
            printf $fileh "   %8s : %4s transactions\n", $type,${$transaction_ref}{transaction}{$size}{WRITE}{$type};
        }# by type
        printf $fileh "%s\n", '-'x$length_of_line;
    }#by size
    printf $fileh "%8s : %4s transactions\n", "Total WRITE",${$transaction_ref}{transaction}{WRITE}{total};

    printf $fileh "\n";
    printf $fileh "%s\n", '='x$length_of_line;
    printf $fileh "   READ  transactions :: (by size, type)\n";
    foreach my $size ( ( 1, 2, 4 ) ){   # byte
        printf $fileh "   %s byte wide burst\n", $size;
        foreach my $type ( @_list ) {
            printf $fileh "   %8s : %4s transactions\n", $type,${$transaction_ref}{transaction}{$size}{READ}{$type};
        }# by type
        printf $fileh "%s\n", '-'x$length_of_line;
    }# by size
    printf $fileh "%8s : %4s transactions\n", "Total READ ",${$transaction_ref}{transaction}{READ}{total};
    printf $fileh "%s\n", '='x$length_of_line;
}#sub report_transactions


sub   check_environment {
      my    (   $opts_ref                                                                                   # Input     Reference to %opts
            ,   $trace_ref                                                                                  # Output    Reference to @traces array of hash
            ,   $trace_dir_ref  )   = @_;                                                                   #           Reference to @dir or @traces        # deprecated
 
      my $report_path;
      my $logging_path;
      my $analysis_report;
      my $report_path_alt;
      my $analysis_rpt_alt;
      my @trace_files;
      my $cnt = 0;
      my $trah;                                                                                             # logging file handle
      
      printf $proh "     %s\n", ${$opts_ref}{program};
      printf $proh "     %s\n", ${$opts_ref}{version};
      printf $proh "     %s\n", ${$opts_ref}{call};
      printf $proh "\n";
      
      if ( defined ${$opts_ref}{debug_trace} ) {
            printf " ... checking environment ... \n";
            printf " ... checking CMDline reference:: %s\n",$opts_ref;
      }#debugging

      printf $proh " ... checking environment ... \n";
      #
      # Absolute vs relative file path
      #
      my $tracelog    = ${$opts_ref}{trace_default};                                                        # Logging all trace files of one analysis run
      if ( ${$opts_ref}{logging_trace} ) {
        open (  $trah, ">$tracelog") || die " Can not create log $tracelog";                                # debug path/file name generation
        printf  $trah  " %s\n", '='x90;
        printf  $trah  " Logfile     : %s\n"           ,$tracelog;
        printf  $trah  " Script      : %s %s\n"        ,$0, $VERSION;                                       #  0  1, 2,    3,   4,    5,    6,    7,     8
        printf  $trah  " Date        : %4s-%02s-%02s\n",1900+$year,$mon,$cday;                              # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
        printf  $trah  " Time        : %4s:%02s:%02s\n",$h, $m,$s;                                          # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
        printf  $trah  " %s\n", '='x90;
        printf  $proh  "     opening TraceLogFile   %s\n",$tracelog;
      }


      if ( defined ${$opts_ref}{report_dir} ) {                                                             # Redirect and Create report subdirectory
        printf $proh " ... cecking path to trace dir :: %s\n", ${$opts_ref}{report_dir};

        unless ( -d ${$opts_ref}{report_dir} ) {                                                            # This code is left from development
              my $dir = ${$opts_ref}{report_dir};                                                           # depending on command line only optional
              printf $proh " WARNING report directory <%s> doesn't exist\n", $dir;
              make_path( $dir );
              printf $proh " ... creating report directory <%s> !!\n", $dir;
        }# This code might be redundant due to complete implementing

      } else {
        printf $proh " ... default report path       :: %s\n", ${$opts_ref}{report_path_default};
      }#Reporting option

      if (  defined ${$opts_ref}{trace_file}   ) {                                                          # Selecting single trace file
            my $file = ${$opts_ref}{trace_file};
            printf " ... list trace file           :: %s ", $file;
            printf " :: %s\n", (not_empty( 10, $file)) ? 'not empty':'    empty';
            push (@{${$opts_ref}{trace_files}}, $file) if ( not_empty( 10, $file));                         # test trace file
      }

      if (  defined ${$opts_ref}{trace_dir}    ) {                                                          # Selecting test case w/ multiple trace files
            printf "\n ... path to trace files       :: %s \n", ${$opts_ref}{trace_dir};
            my $path= ${$opts_ref}{trace_dir}; 
            my $dir = $path.'/*';
            @trace_files = grep { -f } glob("$dir");
            foreach my $trace (@trace_files) {

                if ( ${$opts_ref}{logging_trace} ) {
                    printf $trah "%*s%s\n",21,'',$trace;
                }#logging

                if ($trace =~ m/${$opts_ref}{file_pattern}/) {                                              # m/ahb_beat.log/
                    push (@{${$opts_ref}{trace_files_candidates}}, $trace);
                }# filter file name pattern
            }#foreach trace matching file pattern
            printf $trah "\n" if ( ${$opts_ref}{logging_trace} );                                           # logging spacer
            foreach my $file ( @{${$opts_ref}{trace_files_candidates}} ) {
                $cnt++;
                if ( ${$opts_ref}{logging_trace} ) {
                    printf $trah "%*s%4s %s :: %s\n",3,'',$cnt,
                                 ,(not_empty( 10, $file)) ? 'not empty':'    empty',$file;
                }#logging
               #printf       "%*s%4s %s :: %s\n",3, '',$cnt,
               #             ,(not_empty( 10, $file)) ? 'not empty':'    empty',$file;
                push (@{${$opts_ref}{trace_files}}, $file) if ( not_empty( 10, $file));                     # test trace files
            }#foreach none empty file
      }

      if (  defined ${$opts_ref}{trace_dirs}   ) {                                                          # Selecting total project Use with knowledge
            printf       "\n ... list trace directory      :: %s \n", ${$opts_ref}{trace_dirs};
            if ( ${$opts_ref}{logging_trace} ) {
                printf $trah "\n ... list trace directory      :: %s \n", ${$opts_ref}{trace_dirs};
            }#logging
            my $dir         = ${$opts_ref}{trace_dirs}.'/*';                                                # Glob term
           #@trace_files    = grep { -f } glob("$dir");                                                     # Knowhow to glob !!
            @trace_dirs     = grep { -d } glob("$dir");
            ${$opts_ref}{trace_dirs} = [];                                                                  # Reference to anonymous array
            printf       " ... size of list of trace dirs :: %s\n", scalar @{${$opts_ref}{trace_dirs}}; 
            if ( ${$opts_ref}{logging_trace} ) {
                printf $trah " ... size of list of trace dirs :: %s\n", scalar @{${$opts_ref}{trace_dirs}};
            }#logging

            foreach my $trace (@trace_dirs) {
                if ( ${$opts_ref}{logging_trace} ) {
                    printf $trah "%*s%s\n", 5, '',      $trace  
                    if ($trace =~ m/${$opts_ref}{dir_pattern}/);                                            # m/ahbfab/
                }#logging
                push  (@{${$opts_ref}{trace_dirs}}, $trace) 
                if ($trace =~ m/${$opts_ref}{dir_pattern}/);                                                # m/ahbfab/
            }
            printf " ... size of list of trace dirs :: %s\n", scalar @{${$opts_ref}{trace_dirs}};

            ${$opts_ref}{trace_files_candidates} = [];
            if ( ${$opts_ref}{logging_trace} ) {
                printf $trah "\n"; 
                printf $trah "%s\n", '='x100;                                                               # pull parameter out
                printf $trah "\n";
            }#logging

            foreach my $path ( @{${$opts_ref}{trace_dirs}} ) {
                my $dir = $path.'/*';
                @trace_files = grep { -f } glob("$dir"); 
                if ( ${$opts_ref}{logging_trace} ) {
                    printf $trah "\n";
                    printf $trah "%*s%s\n", 5,'', $path;                                                    # All trace directories
                }#logging
                foreach my $trace (@trace_files) {
                    printf $trah "%*s%s\n",10, ''     ,$trace if ( ${$opts_ref}{logging_trace} );           # logging
                    push (@{${$opts_ref}{trace_files_candidates}}, $trace) 
                    if ($trace =~ m/${$opts_ref}{file_pattern}/);                                           # m/ahb_beat.log/
                }#foreach trace matching file pattern
            }#foreach path

            if ( ${$opts_ref}{logging_trace} ) {
                printf $trah "\n"; 
                printf $trah "%s\n", '='x100;                                                               # pull parameter out
                printf $trah "\n";
            }#logging

            ${$opts_ref}{trace_files} = [];
            foreach my $file ( @{${$opts_ref}{trace_files_candidates}} ) {
                printf $trah "%*s%4s %s\n",10, '',++$cnt,$file if ( ${$opts_ref}{logging_trace} );          # logging
               #printf $trah "%*s%s\n"    ,15, '', (empty_sallow($file)) ? 'empty file' : 'trace file';
               #printf $trah "%*s%s %s\n" ,15, '', 'file has :: ', empty_deep($file);
                push (@{${$opts_ref}{trace_files}}, $file) if ( not_empty( 10, $file));
            }#foreach none empty file

            ${$opts_ref}{cwd}           = getcwd();
            ${$opts_ref}{cwd_absolute}  = cwd();
            printf       " ... size of list of trace files:: %s\n", scalar @{${$opts_ref}{trace_files}};
            printf       "     current working directory  :: %s\n", ${$opts_ref}{cwd}; 
            printf       "                                :: %s\n", ${$opts_ref}{cwd_absolute};

            if ( ${$opts_ref}{logging_trace} ) {
                printf $trah "\n"; 
                printf $trah "%s\n", '='x100;                                                               # pull parameter out
                printf $trah "%s\n", ' All trace files selected\n';
                printf $trah "%s\n", '='x100;                                                               # pull parameter out
                printf $trah "\n";
            }#logging
            $cnt = 0;
      }# for all trace_dirs

      
      printf $trah "\n" if ( ${$opts_ref}{logging_trace} );                                                 # logging
      $cnt = 0;
      foreach my $file ( @{${$opts_ref}{trace_files}} ) {
          my %trace_info  = ();                                                                             # information hash per trace
          my ($f,$p,$e)   = fileparse($file, qr/\.[^.]*/);                                                  # filepath, filename, extension
          # test case
          my @test_case   = split /[\/]/, $p;                                                               # split at character sub class
          ${$opts_ref}{test_case} = $test_case[-1];
          # test point
          # uvm_test_top.top_env_i.ahbfab_env_i.mvc_ahb_slv_4_env_i_ahb_beat <--- $f
          #                                    .mvc_ahb_slv_4_env_i_ahb_beat
          #                                     mvc_ahb_slv_4                <--- Test point
          my @test_praw   = split /[.]/, $f;                                                                # split at character sub class
          my @test_point  = split /[_]/,$test_praw[-1];                                                     # split string
          ${$opts_ref}{test_point} = join  ('_', @test_point[0 .. 3]);                                      # join  array slice
          $cnt++;                                                                                           # Explicite counter only 
          if ( ${$opts_ref}{logging_trace} ) {
            printf $trah "%*s%4s%8s %s\n", 3,'',$cnt,empty_deep($file), $file;
            printf $trah "%*s%s %s\n"    ,20,'', 'file path          ', $p;
            printf $trah "%*s%s %s\n"    ,20,'', 'file name          ', $f;
            printf $trah "%*s%s %s\n"    ,20,'', 'file extension     ', $e;
            printf $trah "%*s%s %s\n"    ,20,'', 'test case          ', ${$opts_ref}{test_case};
            printf $trah "%*s%s %s\n"    ,20,'', 'test point raw     ', $test_praw[-1];
            printf $trah "%*s%s %s\n"    ,20,'', 'test point         ', ${$opts_ref}{test_point};
            printf $trah "\n";
          }#logging
          $report_path_alt      =   $p.'ahb_tracker_analysis';                                              # Create redundancy to test the auto_name algorithm
          $analysis_rpt_alt     =   $report_path_alt.'/'
                                .   ${$opts_ref}{test_point}.'_'
                                .   ${$opts_ref}{report_default};
          if ( defined ${$opts_ref}{report_dir} ){
               printf $trah "%*s%s %s\n"    ,20, ''
                            , 'report_dir         '
                            , ${$opts_ref}{report_dir}  if ( defined ${$opts_ref}{report_dir} );            # Path of redirected output
               $report_path         = ${$opts_ref}{report_dir}.'/'                                          # Start of path
                                    . ${$opts_ref}{test_case} .'/'
                                    . ${$opts_ref}{test_point};
               $logging_path        = ${$opts_ref}{report_dir}.'/'                                          # Start of path
                                    . ${$opts_ref}{test_case}.'/'
                                    . ${$opts_ref}{test_point}.'_'
                                    . ${$opts_ref}{log_path_default};                                       # Ending the path on pattern<_logs/>
               $analysis_report     = ${$opts_ref}{report_dir}.'/'
                                    . ${$opts_ref}{test_case} .'/'
                                    . ${$opts_ref}{test_point}.'_'
                                    . ${$opts_ref}{report_default};
          } else {
               printf $trah "%*s%s %s\n"    ,20, ''
                            , 'report_path_default'
                            , ${$opts_ref}{report_path_default}  if ( defined ${$opts_ref}{report_dir} );   # Default output path
               $report_path         = $p.${$opts_ref}{report_path_default};
               $logging_path        = $report_path.'/'
                                    . ${$opts_ref}{test_point}.'_'
                                    . ${$opts_ref}{log_path_default};
               $analysis_report     = $report_path.'/'
                                    . ${$opts_ref}{test_point}.'_'
                                    . ${$opts_ref}{report_default};
          }
          $trace_info{trace}        = $file;
          $trace_info{number}       = $cnt;
          $trace_info{test_case}    = ${$opts_ref}{test_case};
          $trace_info{test_point}   = ${$opts_ref}{test_point};
          $trace_info{report_path}  = $report_path;
          $trace_info{logging_path} = $logging_path;
          $trace_info{report}       = $analysis_report;
          if ( ${$opts_ref}{logging_trace} ) {
            printf $trah "%*s%s %s\n" ,20,'','report_path        ',$report_path;
            printf $trah "%*s%s %s\n" ,20,'','logging_path       ',$logging_path;
            printf $trah "%*s%s %s\n" ,20,'','analysis report    ',$analysis_report;
            printf $trah "%*s%s %s\n" ,20,'','report_path     alt',$report_path_alt;                        # Redundancy of algorithm
            printf $trah "%*s%s %s\n" ,20,'','analysis report alt',$analysis_rpt_alt;                       # Redundancy of algoritm
          }#logging
          if ( -d $report_path ) {                                                                          # positive logic - empty branch
          } else {
              make_path( $report_path );
              printf $proh " ... WARNING <%s> PATH was created\n", $report_path;
          }# create reporting structure
          ### if ( -d $logging_path ) {                                                                     # positive logic - empty branch
          ### } else {                                                                                      # deprecated this is a conditional ondemand creation
          ###     make_path( $logging_path );
          ###     printf $proh " ... WARNING <%s> PATH was created\n", $logging_path;
          ### }# create logging structure
          push ( @{$trace_ref} , \%trace_info);                                                             # queue up all analysis traces, w/ elaborated information 
      }#foreach none empty file

      if ( defined ${$opts_ref}{logging_trace} ) {
            close( $trah );                                                                                 # close logging 
            printf $proh "     closing TraceLogFile   %s\n", $tracelog;
      }#logging

      printf $proh " ... checking environment done \n";                                                     # Non maskable logging

      printf " ... path to reports/logs      :: %s\n",$report_path;
      if ( defined ${$opts_ref}{debug_trace} ) {
            printf " ... checking environment done \n";
      }#debugging

}#sub check_environment


# Files do exist, and are of type -f for file
#

sub   empty_sallow {
      my ( $file_name ) = @_;
      return ( -z $file_name);
}#sub empty_sallow

#
# Files with no samples are instantiated, but with out traffic
# 

sub   empty_deep {
      my    ( $file_name    ) = @_;
      open (my $file, "<$file_name")    || die  " Can not open  file $file_name"; 
      my @LINES = <$file>;                      # Slurp file into array
      return $#LINES;                           # Number of lines in file, empty files -1
}#sub empty_deep

sub   not_empty {
      my    ( $header
            , $file_name    ) = @_;
      return ( empty_deep($file_name) > $header );
}#sub not_empty

#
#   The first implementation of the transfer pointer list, was using global pointer - 
#   The commented pointer are for informational, and historical purpose to list all global pointer
#
#   Unified pointer statemachine
#
#   NOTE::  Previous and Last pointer are very similar and with the destinction during building transfer list
#           when the previous pointer becomes the last pointer, when the last pointer was always the last pointer
#
sub   initialize_pointer {
      my    (   $pointer_ref    )   = @_;                                           # Input     Hash reference
                                                                                    # Output    Initialized pointer, build, iterate, analyze

      ${$pointer_ref}{adr}{initialize}      =   1;                                  # Initialize ADDR transfer state variable for new transfer list
      ${$pointer_ref}{adr}{first}           =   undef;                              # Head      of transaction list,                    $ptr_fst_cmd
      ${$pointer_ref}{adr}{previous}        =   undef;                              #           Positional/temporal pointer             $ptr_prv_cmd
     #${$pointer_ref}{adr}{current}         =   undef; informal                     #           Positional/temporal pointer             $ptr_cur_cmd became local Ptr
     #${$pointer_ref}{adr}{next}            =   undef; informal                     #           Positional/temporal pointer             $ptr_nxt_cmd 
     #${$pointer_ref}{adr}{antepenultimate} =   undef; informal                     #           Positional                              $ptr_ant_cmd
      ${$pointer_ref}{adr}{penultimate}     =   undef;                              #           Positional                              $ptr_pen_cmd
     #${$pointer_ref}{adr}{ultimate}        =   undef; informal                     #           Positional ultimate == last             $ptr_ult_cmd == $ptr_lst_cmd
      ${$pointer_ref}{adr}{last}            =   undef;                              # Tail      of transaction list                     $ptr_lst_cmd
      ${$pointer_ref}{adr}{start}           =   undef;                              # Begin     of analysis    window                   $ptr_stt_cmd
      ${$pointer_ref}{adr}{stop}            =   undef;                              # End       of analysis    window                   $ptr_stp_cmd

      ${$pointer_ref}{dta}{initialize}      =   1;                                  # Initialize DATA transfer state variable absorbed in pointer SM deprecated !!
      ${$pointer_ref}{dta}{first}           =   undef;                              # Head      of Data transfers                       $ptr_fst_dta
      ${$pointer_ref}{dta}{previous}        =   undef;                              #           positional/temporal pointer(building)   $ptr_prv_dta == $ptr_lst_cmd
      ${$pointer_ref}{dta}{last}            =   undef;                              # Tail      of Data transfers                       $ptr_lst_dta
      printf $proh "\n";
      printf $proh " ... initialzing pointer done !!\n";
}#sub initialize_pointer

sub   initialize_trace_info {
      my    (   $trace_header_ref   )   = @_;                                       # Input     Hash reference
                                                                                    # Output    Reinitialize trace file header information
      printf $proh " ... initialzing trace information done !!\n";
}#sub initialize_trace

sub   help{
      printf "\n";
      printf " ... script usage :: %s\n", $VERSION;
      printf "\n";
      printf "     <script.pl>  --trace=<file_name>\n";
      printf "                  --trace=<file_name>     --info \n";
      printf "                  --trace=<file_name>     --from=<time> --until=<time>\n";
      printf "\n";
      printf "                  --trace_dir=<pathname>\n";
      printf "                  --trace_dir=<pathname>  --from=<time> --until=<time>\n";
      printf "\n";
      printf "     NOTE           Don't terminate <pathname> with an </> at the end!!\n";
      printf "\n";
      printf "     Optional     --Redirecting output\n";
      printf "    <script.pl>   --trace_dir=<pathname>  --from= --until= --o=reports ...\n";
      printf "\n";
      printf "     Debugging\n";
      printf "    <script.pl>   --trace_dir=<pathname>  --from= --until= | & tee ./log.out\n";
      printf "\n";
      exit 0;
}#sub help


sub   analyze_tracefiles {
      my (  $opts_ref                                                               # Input     Command line options
         ,  $trace_ref                                                              #           List of trace files
         ,  $trace_info                                                             #           Hash of trace file header info
         ,  $ptr_ref            )   = @_;                                           #           Hash of transfer list pointer

      my $cnt = 0;
      
      printf "\n";
      printf " ... analyze_tracefile ... \n";
      foreach my $analyse ( @{$trace_ref} ){
          my %local_Trace;
          my %local_pointer;

          printf "%*s%4s %s\n", 10,'',${$analyse}{number},${$analyse}{trace};

          ${$opts_ref}{trace_file}  = ${$analyse}{trace};                                                   # assign trace file name
          ${$opts_ref}{parse}       = ${$analyse}{logging_path}.'/'.${$opts_ref}{parse_default};
          ${$opts_ref}{build}       = ${$analyse}{logging_path}.'/'.${$opts_ref}{build_default};
          ${$opts_ref}{window}      = ${$analyse}{logging_path}.'/'.${$opts_ref}{window_default};
          ${$opts_ref}{payload}     = ${$analyse}{logging_path}.'/'.${$opts_ref}{payload_default};
          ${$opts_ref}{errlog}      = ${$analyse}{logging_path}.'/'.${$opts_ref}{errlog_default};
          ${$opts_ref}{transfer}    = ${$analyse}{logging_path}.'/'.${$opts_ref}{transfer_default};          # assign logging file path names
          ${$opts_ref}{transferlist}= ${$analyse}{logging_path}.'/'.${$opts_ref}{transferlist_default};
          ${$opts_ref}{latency}     = ${$analyse}{logging_path}.'/'.${$opts_ref}{latency_default};
          ${$opts_ref}{bandwidth}   = ${$analyse}{logging_path}.'/'.${$opts_ref}{bandwidth_default};
          ${$opts_ref}{transaction} = ${$analyse}{logging_path}.'/'.${$opts_ref}{transaction_default};
          ${$opts_ref}{transaction2}= ${$analyse}{logging_path}.'/'.${$opts_ref}{transaction2_default};
          ${$opts_ref}{report}      = ${$analyse}{report};                                                  # assign analysis report name

          initialize_pointer        (   $ptr_ref            );                      # Output    Initialized pointer structure of trace transfers
          initialize_trace_info     (   $trace_info         );                      # Output    Initialized information structure of trace file header

          elaborate_tracefile       (   $trace_info                                 # Output    Extracting    trace file header information
                                    ,   $ptr_ref                                    #           Pointer into  trace transfer double pointered list 
                                    ,   $opts_ref           );                      # Input     Options list  from command line

          if ( defined ${$opts_ref}{logging_transfer_list} ) {
               read_transfer_list   (   $trace_info                                 # Input     Trace Header information
                                    ,   $ptr_ref                                    #           Pointer information into transfer/trace list
                                    ,   $opts_ref           );                      #           Command line options
          }#logging transfer list

          restrict_window           (   $opts_ref                                   # Input     Options list  from command line\%Trace          
                                    ,   $trace_info                                 #           Trace file header information
                                    ,   $ptr_ref            );                      # Ouptut    Pointer into  trace transfer double pointered list 

        initialize_latency_analysis ( \%ahb_latency_new     );                      # Output    Initialize reporting structure
    initialize_transaction_analysis ( \%ahb_transaction_new );                      # Output    Initialize reporting structure
    initialize_transaction_analysis ( \%ahb_transaction2_new) ;                     # Output    Initialize reporting structure

#
# determine burst length and calculate payload per transaction
#
        initialize_payload_analysis (  $trace_info                                  # Input     Trace   information from trace file header
                                    ,  $ptr_ref                                     #           Pointer information into transfer/trace list
                                    ,  $opts_ref            );                      #           Command line options
                                                                                    # Output    Augmentation of transfer list
    
               transfer_analysis    (  $trace_info                                  # Input     Trace Header information
                                    ,  $ptr_ref                                     #           Pointer information into transfer/trace list
                                    ,  $opts_ref                                    #           Command line options
                                    ,  \%ahb_transfer_new   );                      # Output    Transfer analysis, IDLE, WAIT states, BEAT
    
               latency_analysis     (  $trace_info                                  # Input     Trace Header information
                                    ,  $ptr_ref                                     #           Pointer information into transfer/trace list
                                    ,  $opts_ref                                    #           Command line options
                                    ,  \%ahb_transfer_new                           #           Transfer analysis IDLE, WAIT states, BEATs
                                    ,  \%ahb_latency_new     );                     # Output    Latency  analysis ( From, To )      
    
               bandwidth_analysis   (  $trace_info                                  # Input     Trade Header information
                                    ,  $ptr_ref                                     #           Pointer information into transfer/trace list
                                    ,  $opts_ref                                    #           Command line options
                                    ,  \%ahb_transfer_new                           #           Transfer analysis IDLE, WAIT states, BEATs
                                    ,  \%ahb_bandwidth_new                          # Output    Bandwidth analysis (From, To )
                                    ,  \%ahb_transaction_new );                     #           Transaction statistic
    
               transaction_analysis (  $trace_info                                  # Input     Trace Header information
                                    ,  \%AHB_hash                                   #           Reference to transfer list 
                                    ,  $opts_ref                                    #           Command line options
                                    ,  \%ahb_transaction_new );                     # Output    Transaction reporting, replacing %ahb_anal

               transaction2_analysis(  $trace_info                                  # Input     Trade Header information
                                    ,  $ptr_ref                                     #           Pointer information into transfer/trace list
                                    ,  $opts_ref
                                    ,  \%ahb_transaction2_new);                     # Output    Transaction reporting, based on pointer
    
                analysis_report     (  $trace_info                                  # Input     Trade Header information
                                    ,  $opts_ref                                    #           Command line options
                                    ,  \%ahb_latency_new                            #           Latency analysis
                                    ,  \%ahb_transfer_new                           #           Transfer analysis   to be deprecated
                                    ,  \%ahb_bandwidth_new                          #           Bandwidth analysis
                                    ,  \%ahb_transaction_new );                     #           Transaction analysis
      }#foreach analysis
}#sub analyze_tracefiles

sub   coverage_analysis {
      my    (   $opts_ref                                                           # Input     Command line options
            ,   $trace_ref                                                          #           List of trace files
            ,   $trace_info                                                         #           Hash of trace file header info
            ,   $ptr_ref                                                            #           Hash of transfer list pointer
            ,   $adr_ref            )   = @_;                                       #           HASH ref to address coverage

      my $cnt = 0;
      
      printf "\n";
      printf " ... analyze_coverage ... \n";
      foreach my $analyse ( @{$trace_ref} ){

          printf "%*s%4s %s\n", 10,'', ${$analyse}{number}, ${$analyse}{trace}      ;

          ${$opts_ref}{trace_file}  = ${$analyse}{trace};
          ${$opts_ref}{parse}       = ${$analyse}{logging_path}.'/'.${$opts_ref}{parse_default};
          ${$opts_ref}{build}       = ${$analyse}{logging_path}.'/'.${$opts_ref}{build_default};
          ${$opts_ref}{window}      = ${$analyse}{logging_path}.'/'.${$opts_ref}{window_default};
          ${$opts_ref}{payload}     = ${$analyse}{logging_path}.'/'.${$opts_ref}{payload_default};
          ${$opts_ref}{errlog}      = ${$analyse}{logging_path}.'/'.${$opts_ref}{errlog_default};
          ${$opts_ref}{transfer}    = ${$analyse}{logging_path}.'/'.${$opts_ref}{transfer_default};
          ${$opts_ref}{transferlist}= ${$analyse}{logging_path}.'/'.${$opts_ref}{transferlist_default};
          ${$opts_ref}{latency}     = ${$analyse}{logging_path}.'/'.${$opts_ref}{latency_default};
          ${$opts_ref}{bandwidth}   = ${$analyse}{logging_path}.'/'.${$opts_ref}{bandwidth_default};
          ${$opts_ref}{transaction} = ${$analyse}{logging_path}.'/'.${$opts_ref}{transaction_default};
          ${$opts_ref}{transaction2}= ${$analyse}{logging_path}.'/'.${$opts_ref}{transaction2_default};
          ${$opts_ref}{address}     = ${$analyse}{logging_path}.'/'.${$opts_ref}{address_default};
          ${$opts_ref}{report}      = ${$analyse}{report};

          initialize_pointer        (   $ptr_ref                );                  # Output    Initialized pointer structure of trace transfers
          initialize_trace_info     (   $trace_info             );                  # Output    Initialized information structure of trace file header

          elaborate_tracefile       (   $trace_info                                 # Output    Extracting    trace file header information
                                    ,   $ptr_ref                                    #           Pointer into  trace transfer double pointered list 
                                    ,   $opts_ref               );                  # Input     Options list  from command line

          if ( defined ${$opts_ref}{logging_transfer_list} ) {                      # Inspecting data structure for algorithm development
               read_transfer_list   (   $trace_info                                 # Input     Trace Header information
                                    ,   $ptr_ref                                    #           Pointer information into transfer/trace list
                                    ,   $opts_ref           );                      #           Command line options
          }#logging transfer list

          overwrite_restrict_window (   $opts_ref                                   # Input     Options list  from command line\%Trace          
                                    ,   $trace_info                                 #           Trace file header information
                                    ,   $ptr_ref                );                  # Ouptut    Pointer into  trace transfer double pointered list 

        initialize_latency_analysis ( \%ahb_latency_new         );                  # Output    Initialize reporting structure
    initialize_transaction_analysis ( \%ahb_transaction_new     );                  # Output    Initialize reporting structure
    initialize_transaction_analysis ( \%ahb_transaction2_new    );                  # Output    Initialize reporting structure

#
# determine burst length and calculate payload per transaction
#
        initialize_payload_analysis (   $trace_info                                 # Input     Trace   information from trace file header
                                    ,   $ptr_ref                                    #           Pointer information into transfer/trace list
                                    ,   $opts_ref               );                  #           Command line options
                                                                                    # Output    Augmentation of transfer list
    
               transfer_analysis    (   $trace_info                                 # Input     Trace Header information
                                    ,   $ptr_ref                                    #           Pointer information into transfer/trace list
                                    ,   $opts_ref                                   #           Command line options
                                    ,   \%ahb_transfer_new      );                  # Output    Transfer analysis, IDLE, WAIT states, BEAT
    
               latency_analysis     (   $trace_info                                 # Input     Trace Header information
                                    ,   $ptr_ref                                    #           Pointer information into transfer/trace list
                                    ,   $opts_ref                                   #           Command line options
                                    ,   \%ahb_transfer_new                          #           Transfer analysis IDLE, WAIT states, BEATs
                                    ,   \%ahb_latency_new       );                  # Output    Latency  analysis ( From, To )      
    
               bandwidth_analysis   (   $trace_info                                 # Input     Trade Header information
                                    ,   $ptr_ref                                    #           Pointer information into transfer/trace list
                                    ,   $opts_ref                                   #           Command line options
                                    ,   \%ahb_transfer_new                          #           Transfer analysis IDLE, WAIT states, BEATs
                                    ,   \%ahb_bandwidth_new                         # Output    Bandwidth analysis (From, To )
                                    ,   \%ahb_transaction_new   );                  #           Transaction statistic
    
               transaction_analysis (   $trace_info                                 # Input     Trace Header information
                                    ,   \%AHB_hash                                  #           Reference to transfer list 
                                    ,   $opts_ref                                   #           Command line options
                                    ,   \%ahb_transaction_new   );                  # Output    Transaction reporting, replacing %ahb_anal

             transaction2_analysis  (   $trace_info                                 # Input     Trade Header information
                                    ,   $ptr_ref                                    #           Pointer information into transfer/trace list
                                    ,   $opts_ref
                                    ,   \%ahb_transaction2_new  );                  # Output    Transaction reporting, based on pointer

          address_coverage_analysis (   $trace_info                                 # Input     Trace Header information
                                    ,   $ptr_ref                                    #           Pointer into AHB transfer list
                                    ,   $opts_ref                                   #           Command line options
                                    ,   $adr_ref                );                  # Output    Address Coverage Analysis 
    
###             analysis_report     (  $trace_info                                  # Input     Trade Header information
###                                 ,  $opts_ref                                    #           Command line options
###                                 ,  \%ahb_latency_new                            #           Latency analysis
###                                 ,  \%ahb_transfer_new                           #           Transfer analysis   to be deprecated
###                                 ,  \%ahb_bandwidth_new                          #           Bandwidth analysis
###                                 ,  \%ahb_transaction_new    );                  #           Transaction analysis

      }#foreach analysis      
}#sub analyze_coverage


sub   read_transfer_list {
      my (  $trace_header_ref                                                       # Input     Trace   information from trace file header
         ,  $ptr_ref                                                                #           Pointer information into trace list
         ,  $opts_ref          )    = @_;                                           #           Command line options

      my $logfile     = ${$opts_ref}{transferlist};
      my $cycle       = ${$trace_header_ref}{period};                               # (float)
      my $tb          = ${$trace_header_ref}{timebase};                             # =  $6; # (ns|ps)
      my $frequency   = ${$trace_header_ref}{frequency};                            # (float)
      my $fb          = ${$trace_header_ref}{freqbase};                             # (MHz|GHz)
      my $transaction = 0;

      my $ptr_cur_cmd               =     ${$ptr_ref}{adr}{first};

      my $buffer_stop               =     ${$ptr_ref}{adr}{first};                  # Interate through the whole list, stop at the top
      my $TIME_START                = ${$ptr_cur_cmd}{assert};                      # Start of trace window, assert first transfer
   
      printf  $proh "\n";
      printf  $proh  "     opening    TransferList log %s\n", $logfile;
      open(my $lsth, ">$logfile")|| die " Can not create log $logfile";             # Are the bus transfers accounted for ? Mendatory
      printf  $lsth  " %s\n"     , '='x90;
      printf  $lsth  " Tracefile   : %s\n"             , ${$trace_header_ref}{tracefile};
      printf  $lsth  "               %s\n"             , ${$opts_ref}{trace_file};
      printf  $lsth  " Synopsis    : %s\n"             , 'Inspect Transfer Pointer Structure';
      printf  $lsth  " Logfile     : %s\n"             , $logfile; 
      printf  $lsth  " Script      : %s %s\n"          , $0, $VERSION;              #  0  1, 2,    3,   4,    5,    6,    7,     8
      printf  $lsth  " Date        : %4s-%02s-%02s\n"  , 1900+$year,$mon,$cday;     # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf  $lsth  " Time        : %4s:%02s:%02s\n"  , $h, $m,$s;                 # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf  $lsth  " Cycle       : %10s %s\n"        , $cycle, $tb;               # Header timebase information
      printf  $lsth  " Frequency   : %10s %s\n",       , $frequency, $fb;           # Header frequency information
      printf  $lsth  " %s\n"     , '='x90;

      printf  $lsth  " FirstPointer: %s\n"             , ${$ptr_ref}{adr}{first};
      do {
          $transaction++;   
          printf $lsth "\n";                                       
          printf $lsth "%*s %s %15s\n",14,'','Transaction:',$transaction;                                       
          printf $lsth "%*s %s %15s\n",14,'','TransferPtr:',$ptr_cur_cmd;                                       
          printf $lsth "%*s %s %15s\n",14,'','PreviousPtr:',${$ptr_cur_cmd}{prev};                                       
          printf $lsth "%*s %s %15s\n",14,'','Assertion  :',${$ptr_cur_cmd}{assert};                              
          printf $lsth "%*s %s %15s\n",14,'','Completion :',${$ptr_cur_cmd}{complete};                              
          printf $lsth "%*s %s %15s\n",14,'','Direction  :',${$ptr_cur_cmd}{direction};                              
          printf $lsth "%*s %s %15s\n",14,'','Address    :',${$ptr_cur_cmd}{addr};                              
          printf $lsth "%*s %s %15s\n",14,'','BurstLength:',${$ptr_cur_cmd}{burst_len};                              
          printf $lsth "%*s %s %15s\n",14,'','Burst Type :',${$ptr_cur_cmd}{burst_type};                              
          printf $lsth "%*s %s %15s\n",14,'','Burst Size :',${$ptr_cur_cmd}{burst_size};                              
          printf $lsth "%*s %s %15s\n",14,'','Protection :',${$ptr_cur_cmd}{hport}; 
          printf $lsth "%*s %s %15s\n",14,'','DataPointer:',${$ptr_cur_cmd}{data}; 
          my $ptr_cur_dta   = ${$ptr_cur_cmd}{data};                                # Set pointer to              data transfer also the first
          my $ptr_fst_dta   = ${$ptr_cur_dta}{prev};                                # Initialize pointer to first data transfer
          my $ptr_lst_dta   = ${$ptr_cur_dta}{last};                                # Initialize pointer to last  data transfer
          my $beat          = 0;
          printf $lsth "%*s %s %15s\n",44,'','FirstDtaPtr:',$ptr_fst_dta;
          printf $lsth "%*s %s %15s\n",44,'','Last DtaPtr:',$ptr_lst_dta;
          do {
                $beat++;
                printf $lsth "\n";                                       
                printf $lsth "%*s %s %15s\n",44,'','Beat       :',$beat                    ;                   
                printf $lsth "%*s %s %15s\n",44,'','PreviousPtr:',${$ptr_cur_dta}{prev}    ;
                printf $lsth "%*s %s %15s\n",44,'','Current Ptr:',  $ptr_cur_dta           ;
                printf $lsth "%*s %s %15s\n",44,'','Assertion  :',${$ptr_cur_dta}{assert}  ;
                printf $lsth "%*s %s %15s\n",44,'','Completion :',${$ptr_cur_dta}{complete};
                printf $lsth "%*s %s %15s\n",44,'','Phase      :',${$ptr_cur_dta}{phase}   ;
                printf $lsth "%*s %s %15s\n",44,'','Address    :',${$ptr_cur_dta}{address} ;
                printf $lsth "%*s %s %15s\n",44,'','Description:',${$ptr_cur_dta}{beat_num};
                printf $lsth "%*s %s %15s\n",44,'','Data       :',${$ptr_cur_dta}{data}    ;
                printf $lsth "%*s %s %15s\n",44,'','Response   :',${$ptr_cur_dta}{response};
                printf $lsth "%*s %s %15s\n",44,'','NextPointer:',${$ptr_cur_dta}{next}    ;
                $ptr_cur_dta = ${$ptr_cur_dta}{next};                               # Circular list points to the beginning
          }until ($ptr_cur_dta == $ptr_fst_dta);                                    # If first is the last&only pointer,     Until LAST DATA transfer
                                                                                    # then the next is the first as well

          printf $lsth "%*s %s %15s\n",14,'','NextPointer:',${$ptr_cur_cmd}{next}; 
          $ptr_cur_cmd = ${$ptr_cur_cmd}{next};                                     # Iterate to the next transaction/transfer AHB command
      } until ($ptr_cur_cmd == $buffer_stop );                                      # Until LAST AHB transaction
      printf  $lsth  "\n";
      printf  $lsth  " Last Pointer: %s\n"             , ${$ptr_ref}{adr}{last};

      close ( $lsth );
      printf  $proh  "     closing    TransferList log %s\n", $logfile;
      printf  $proh "\n";
}#sub read_transfer_list


sub   address_coverage_analysis {
      my    (   $trace_header_ref                                                   # Input     Trace Header information
            ,   $ptr_ref                                                            #           Pointer into AHB transfer list
            ,   $opts_ref                                                           #           Command line options
            ,   $adr_ref                )   = @_;                                   # Output    Address Coverage Analysis 

      my $logfile     = ${$opts_ref}{address};                                      # log file for address coverage analysis
      my $cycle       = ${$trace_header_ref}{period};                               # (float)
      my $tb          = ${$trace_header_ref}{timebase};                             # =  $6; # (ns|ps)
      my $frequency   = ${$trace_header_ref}{frequency};                            # (float)
      my $fb          = ${$trace_header_ref}{freqbase};                             # (MHz|GHz)

      my $ptr_cur_cmd =     ${$ptr_ref}{adr}{first};
      my $buffer_stop =     ${$ptr_ref}{adr}{first};                                # Iterate through the whole list, stop at the top
      my $TIME_START  = ${$ptr_cur_cmd}{assert};                                    # Start of trace window, assert first transfer
      my $transaction = 0;

      printf  $proh "\n";
      printf  $proh " ... coverage    analysis\n";
      printf  $proh  "     opening    CoverageLog      %s\n", $logfile;
      open(my $covh, ">$logfile")|| die " Can not create log $logfile";             # Are the bus transfers accounted for ? Mendatory
      printf  $covh  " %s\n"     , '='x80;
      printf  $covh  " Tracefile   : %s\n"             , ${$trace_header_ref}{tracefile};
      printf  $covh  "               %s\n"             , ${$opts_ref}{trace_file};
      printf  $covh  " Synopsis    : %s\n"             , 'Coverage Analysis, spanning all transfers over multiple traces';
      printf  $covh  " Logfile     : %s\n"             , $logfile; 
      printf  $covh  " Script      : %s %s\n"          , $0, $VERSION;              #  0  1, 2,    3,   4,    5,    6,    7,     8
      printf  $covh  " Date        : %4s-%02s-%02s\n"  , 1900+$year,$mon,$cday;     # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf  $covh  " Time        : %4s:%02s:%02s\n"  , $h, $m,$s;                 # $s,$m,$h,$cday,$mon,$year,$wday,$yday,$isdst
      printf  $covh  " Cycle       : %10s %s\n"        , $cycle, $tb;               # Header timebase information
      printf  $covh  " Frequency   : %10s %s\n",       , $frequency, $fb;           # Header frequency information
      printf  $covh  " %s\n"     , '='x80;


      printf  $covh  " FirstPointer: %s\n"             , ${$ptr_ref}{adr}{first};
      do {
          $transaction++;   
          printf $covh "\n";                                       
          printf $covh "%*s %s %10s\n",14,'','Transaction:',$transaction;                                       
          printf $covh "%*s %s %10s\n",14,'','TransferPtr:',$ptr_cur_cmd;                                       
          printf $covh "%*s %s %10s\n",14,'','PreviousPtr:',${$ptr_cur_cmd}{prev};                                       
          printf $covh "%*s %s %10s\n",14,'','Assertion  :',${$ptr_cur_cmd}{assert};                              
          printf $covh "%*s %s %10s\n",14,'','Completion :',${$ptr_cur_cmd}{complete};                              
          printf $covh "%*s %s %10s\n",14,'','Direction  :',${$ptr_cur_cmd}{direction};                              
          printf $covh "%*s %s %10s\n",14,'','Address    :',${$ptr_cur_cmd}{addr};                              
          printf $covh "%*s %s %10s\n",14,'','BurstLength:',${$ptr_cur_cmd}{burst_len};                              
          printf $covh "%*s %s %10s\n",14,'','Burst Type :',${$ptr_cur_cmd}{burst_type};                              
          printf $covh "%*s %s %10s\n",14,'','Burst Size :',${$ptr_cur_cmd}{burst_size};                              
          printf $covh "%*s %s %10s\n",14,'','Protection :',${$ptr_cur_cmd}{hport}; 
          printf $covh "%*s %s %10s\n",14,'','DataPointer:',${$ptr_cur_cmd}{data}; 
          my $ptr_cur_dta   = ${$ptr_cur_cmd}{data};                                # Set pointer to              data transfer also the first
          my $ptr_fst_dta   = ${$ptr_cur_dta}{prev};                                # Initialize pointer to first data transfer
          my $ptr_lst_dta   = ${$ptr_cur_dta}{last};                                # Initialize pointer to last  data transfer
          my $beat          = 0;
          printf $covh "%*s %s %10s\n",38,'','FirstDtaPtr:',$ptr_fst_dta;
          printf $covh "%*s %s %10s\n",38,'','Last DtaPtr:',$ptr_lst_dta;
          do {
                $beat++;
                printf $covh "\n";                                       
                printf $covh "%*s %s %10s\n",38,'','Beat       :',$beat                    ;                   
                printf $covh "%*s %s %10s\n",38,'','PreviousPtr:',${$ptr_cur_dta}{prev}    ;
                printf $covh "%*s %s %10s\n",38,'','Current Ptr:',  $ptr_cur_dta           ;
                printf $covh "%*s %s %10s\n",38,'','Assertion  :',${$ptr_cur_dta}{assert}  ;
                printf $covh "%*s %s %10s\n",38,'','Completion :',${$ptr_cur_dta}{complete};
                printf $covh "%*s %s %10s\n",38,'','Phase      :',${$ptr_cur_dta}{phase}   ;
                printf $covh "%*s %s %10s\n",38,'','Address    :',${$ptr_cur_dta}{address} ;
                printf $covh "%*s %s %10s\n",38,'','Description:',${$ptr_cur_dta}{beat_num};
                printf $covh "%*s %s %10s\n",38,'','Data       :',${$ptr_cur_dta}{data}    ;
                printf $covh "%*s %s %10s\n",38,'','Response   :',${$ptr_cur_dta}{response};
                printf $covh "%*s %s %10s\n",38,'','NextPointer:',${$ptr_cur_dta}{next}    ;
                $ptr_cur_dta = ${$ptr_cur_dta}{next};                               # Circular list points to the beginning
          }until ($ptr_cur_dta == $ptr_fst_dta);                                    # If first is the last&only pointer,     Until LAST DATA transfer
                                                                                    # then the next is the first as well
          printf $covh "%*s %s %10s\n",14,'','NextPointer:',${$ptr_cur_cmd}{next}; 
          $ptr_cur_cmd = ${$ptr_cur_cmd}{next};                                     # Iterate to the next transaction/transfer AHB command
      } until ($ptr_cur_cmd == $buffer_stop );                                      # Until LAST AHB transaction
      printf  $covh  "\n";
      printf  $covh  " Last Pointer: %s\n"             ,${$ptr_ref}{adr}{last};

      close ( $covh );
      printf  $proh  "     closing    TransferList log %s\n", $logfile;
      printf  $proh " ... coverage    analysis done\n";
      printf  $proh "\n";
}#sub address_coverage_analysis

#
# address coverage is accummulative
# over multiple trace files
#


sub   addr_cov {
      my    (   $opts_ref                                                           # Input     Command line options
            ,   $trace_file_ref                                                     #           LIST ref of trace files
            ,   $trace_dir_ref                                                      #           LIST ref of dirs w/ trace files
            ,   $trace_header_ref                                                   #           Trace   information from trace file header
            ,   $ptr_ref                                                            #           HASH ref to pointer into AHB transfer tree
            ,   $adr_ref            )   = @_;                                       #           HASH ref to address coverage
      printf    " ... Address coverage analysis ...\n"; 
      #printf    "     trace path :: %s\n",$opts{report_dir};
      check_environment           (   $opts_ref                                     # Input     Command Line Options
                                  ,   $trace_file_ref                               # Output    LIST ref of trace files
                                  ,   $trace_dir_ref        );                      #           LIST ref of directories w/ trace files  Deprecated aka not used

      coverage_analysis           (   $opts_ref                                     # Input     Command Line Options
                                  ,   $trace_file_ref                               #           List of trace files
                                  ,   $trace_header_ref                             #           HASH of trace header information        from global to local
                                  ,   $ptr_ref                                      #           HASH of pointer of AHB transfer list    from global to local
                                  ,   $adr_ref              );                      #           HASH ref to address coverage
      exit 0;
}#sub addr_cov


sub   DebugControl {
      my    (   $opts_ref   )   =   @_;                                             # Input     Command Line Options
                                                                                    # Output    Logging Control of all log files
      if ( defined ${$opts_ref}{logs}   ){                                          # Test      Array reference
        if ( @{${$opts_ref}{logs}}    )   {                                         # Test      Array empty
            printf "\n";
            foreach my $log ( @{${$opts_ref}{logs}} ) {
                printf " ... logging :: %s\n", $log;
                if ( $log =~  m/all/ ) {                                            # Storage intensive
                    ${$opts_ref}{logging_trace}         = 1;
                    ${$opts_ref}{logging_parse}         = 1;
                    ${$opts_ref}{logging_build}         = 1;
                    ${$opts_ref}{logging_error}         = 1;
                    ${$opts_ref}{logging_window}        = 1;
                    ${$opts_ref}{logging_latency}       = 1;
                    ${$opts_ref}{logging_payload}       = 1;
                    ${$opts_ref}{logging_transfer}      = 1;
                    ${$opts_ref}{logging_bandwidth}     = 1;
                    ${$opts_ref}{logging_transaction}   = 1;
                    ${$opts_ref}{logging_transfer_list} = 1;
                }#
                ${$opts_ref}{logging_trace}         = 1 if ( $log =~ m/trace/  );      # logging filesystem flow control
                ${$opts_ref}{logging_parse}         = 1 if ( $log =~ m/parse/  );      # logging trace file parsing
                ${$opts_ref}{logging_build}         = 1 if ( $log =~ m/build/  );      # logging trace file transfer list building
                ${$opts_ref}{logging_error}         = 1 if ( $log =~ m/error/  );      # logging trace file errors                 only explicite request for tracking
                ${$opts_ref}{logging_window}        = 1 if ( $log =~ m/window/ );      # logging trace file analysis window reduction
                ${$opts_ref}{logging_latency}       = 1 if ( $log =~ m/latency/);      # logging trace file latency     analysis
                ${$opts_ref}{logging_payload}       = 1 if ( $log =~ m/payload/);      # logging trace file payload     analysis
                ${$opts_ref}{logging_transfer}      = 1 if ( $log =~ m/transfer/);     # logging trace file transfer    analysis
                ${$opts_ref}{logging_bandwidth}     = 1 if ( $log =~ m/bandwidth/ );   # logging trace file bandwidth   analysis
                ${$opts_ref}{logging_transaction}   = 1 if ( $log =~ m/transaction/);  # logging trace file transaction analysis
                ${$opts_ref}{logging_transfer_list} = 1 if ( $log =~ m/transfer_list/);# logging trace file transfer list inspecting-algorithm development pointer list
                
                if (    ${$opts_ref}{logging_parse}     ||  ${$opts_ref}{logging_transfer_list}
                    ||  ${$opts_ref}{logging_build}     ||  ${$opts_ref}{logging_payload}  
                    ||  ${$opts_ref}{logging_error}     ||  ${$opts_ref}{logging_transfer}
                    ||  ${$opts_ref}{logging_window}    ||  ${$opts_ref}{logging_bandwidth}
                    ||  ${$opts_ref}{logging_latency}   ||  ${$opts_ref}{logging_transaction}   ) {

                    printf "\n";
                    printf " ... calling CreateLoggingPath()\n";

                    CreateLoggingPath   (   \%opts                                                  # Input     Command Line Options
                                        ,   \@traces            );                                  #           List of trace files w/ information
                                        
                }#Need to build LoggingPath

            }#foreach
        }#Loggs is not empty
      }#Array reference is defined
}#sub DebugControl

sub   CreateLoggingPath {
      my    (   $opts_ref                                                                           # Input     Command line options
            ,   $trace_file_ref     )   = @_;                                                       #           Reference with list of trace files w/ extracted information

      if ( defined ${$opts_ref}{debug_trace} ) {
          printf "\n";
          printf " ... CreateLoggingPath()\n";
      }#DebugLogging

      foreach my $trace ( @{$trace_file_ref} ) {
          if ( -d ${$trace}{logging_path} ) {
          } else {
                if ( defined ${$opts_ref}{debug_trace} ) {
                    printf "%*s%s :: %s\n",5,'','create',${$trace}{logging_path};
                }#DebugLogging

                make_path (${$trace}{logging_path});
          }#create logging structure
      }#foreach
}#sub CreateLoggingPath
### CreateLoggingPath           (   \%opts                                          # Input     Command Line Options
###                             ,   \@traces            );                          #           List of trace files w/ information


###       if ( -d $logging_path ) {                                                                         # positive logic - empty branch
###       } else {
###           make_path( $logging_path );
###           printf $proh " ... WARNING <%s> PATH was created\n", $logging_path;
###       }# create logging structure


### sub list_hash {
###     my ($href) = @_;
###     foreach my $entry ( keys %{$href} ){
###         printf "\n", ;
###     }#foreach
### }#sub list_hash
