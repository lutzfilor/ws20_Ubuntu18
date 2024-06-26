#!/usr/bin/perl -w
#
#   Author  Lutz Filor
#   Date    08-13-2020

use strict;
use warnings;
use lib "$ENV{PERLPATH}";

use DS::Array       qw/ list_array              /;
use DS::Synthesis   qw/ generate_api
                        code_block              /;
use File::IO::UTF8  qw/ read_utf8   
                        write_utf8              /;
use File::IO::Log   qw/ log_activity
                        activity_message        /;

printf  "\n%*s%s\n",5,'',$0;

my  $specification  =   "$ENV{PERLDATA}"."/code_gen/SDIO_api.txt";
my  $file           =   "$ENV{PERLDATA}"."/code_gen/tb_api_synthesis.v";
my  $logf           =   "$ENV{PERLDATA}"."/logs/code_gen/activity.log";
#my  @spec          =   read_utf8( $file );
my  @spec           =   read_utf8( $specification );

my  $format         =   {   number  =>  1
                        ,   name    =>  '@spec Code Generation'
                        ,   trailing=>  2                       };

my  $msg_info       =   {   date    =>  `TZ='America/Los_Angeles' date +%Y/%m/%d-%H:%M:%S`
                        ,   proc    =>  'synthezise TB API'     };# message information

    list_array          ( [@spec], $format );

my  $synthetic      =   [];
    generate_api        (   $synthetic, [@spec] );
#=   code_block  (   [@spec] );

write_utf8  (   $synthetic, $file   );

my  $logm   =   activity_message    ( $msg_info );  #creating a log message
log_activity    ( $logf, $logm );                                    

exit 0;
