#!/usr/bin/perl -w
#
#   Author  Lutz Filor
#   Date    09-20-2020

use strict;
use warnings;


use lib "$ENV{PERLPATH}";

#use feature 'unicode_strings';
#use open ":std", ":encoding(UTF-8)";
#use open qw( :std :utf8 );

use DS::Array       qw/ list_array
                        list_table
                        maxwidth
                        columnwidth
                        transpose           /;
use DS::Synthesis   qw/ generate_api
                        code_block          /;
use File::IO::UTF8  qw/ read_utf8   
                        write_utf8          /;
use File::IO::CSV   qw/ read_csv
                        write_csv           /;
use File::IO::Log   qw/ log_activity
                        activity_message    /;

use File::IO::Excel qw/ open_workbook
                        read_worksheet
                        list_worksheets     /;

printf  "\n%*s%s\n",5,'',$0;

binmode (STDOUT, ":encoding(UTF-8)");

my  $specification  =   "$ENV{PERLDATA}"."/code_gen/SDIO_api.txt";
my  $file           =   "$ENV{PERLDATA}"."/code_gen/tb_api_synthesis.v";
my  $logf           =   "$ENV{PERLDATA}"."/logs/work_with_workbooks/activity.log";
my  $workbookfile   =   "$ENV{PERLDATA}"."/Excel/test.xlsx";
my  $datafile       =   "$ENV{PERLDATA}"."/Excel/data.csv";
#my  $workbookfile   =   "$ENV{PERLDATA}"."/Excel/test.ods";

my  $format         =   {   number  =>  1
                        ,   name    =>  '@spec Code Generation'
                        ,   trailing=>  2                       };
#my  @spec           =   read_utf8( $specification );
#    list_array          ( [@spec], $format );
my  $message        =   sprintf "Reading %s file",$workbookfile;
my  $message2       =   sprintf "Reading %s CSV file",
my  $msg_info       =   {   date    =>  `TZ='America/Los_Angeles' 
                                         date +%Y/%m/%d-%H:%M:%S`
                        ,   proc    =>  $message     };                         # message information
my  $msg_info2      =   {   date    =>  `TZ='America/Los_Angeles' 
                                         date +%Y/%m/%d-%H:%M:%S`
                        ,   proc    =>  $message2    };                         # message information


my  $synthetic      =   [];
my  $sheetname      =   'Setup';                                                #   Hardcoded
my  $workbook       =   open_workbook   (   $workbookfile   );                  #   Read .xlsx file
                        list_worksheets (   $workbook       );                  #   workbook data
my  $wrksheet       =   read_worksheet  (   $workbook,  $sheetname  );          #   2D table, not a worksheet object reference

list_table          (   $wrksheet,  {   name    =>  'Worksheet_Setup'
                                    ,   leading =>  1
                                    ,   frame   =>  'vertical,top,bottom'
                                    ,   align   =>  [ qw( -1 -1 ) ]             #   left, right align in column
                                    ,   trailing=>  2               }   );

my  $datatable      =   read_csv    (   $datafile   );
list_table          (   $datatable, {   name    =>  'Datatable'
                                    ,   leading =>  1
                                    ,   frame   =>  'vertical,top,bottom'
                                    ,   trailing=>  2               }   );

my  $logm           =   activity_message(   $msg_info   );                      #   creating a log message
my  $logm2          =   activity_message(   $msg_info2  );                      #   creating a log message
log_activity    ( $logf, $logm  );                                    
log_activity    ( $logf, $logm2 );                                    

exit 0;
