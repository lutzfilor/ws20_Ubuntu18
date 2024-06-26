#!/usr/bin/perl -w
#
#   Author  Lutz Filor
#   Date    09-20-2020

use strict;
use warnings;
use lib "$ENV{PERLPATH}";

use DS::Array       qw/ list_array
                        list_table
                        maxwidth
                        columnwidth
                        transpose           /;
use DS::Synthesis   qw/ generate_api
                        code_block          /;
use File::IO::UTF8  qw/ read_utf8   
                        write_utf8
                        append_utf8         /;
use File::IO::CSV   qw/ read_csv
                        write_csv           /;
use File::IO::Log   qw/ log_activity
                        activity_message    /;

use File::IO::Excel qw/ open_workbook
                        read_worksheet
                        list_worksheets     /;

use EXP::XML        qw/ read_xml
                        list_xml
                        list_parts
                        file_exists
                        path_exists
                        disjoin_xml         /;

use EXP::Docx       qw/ write_docx
                        insert_heading
                        update_docx         /;

printf  "\n%*s%s\n",5,'',$0;

my  $logf           =   "$ENV{PERLDATA}"."/logs/work_with_docx/activity.log";
my  $workbookfile   =   "$ENV{PERLDATA}"."/Excel/test.xlsx";
my  $datafile       =   "$ENV{PERLDATA}"."/Excel/data.csv";

#my  $docname        =   "$ENV{PERLDATA}"."/docs/Doc2.docx";
my  $docname        =   "$ENV{PERLDATA}"."/docs/Doc3.docx";
my  $doccopy        =   "$ENV{PERLDATA}"."/docs/Doc3_derivate.docx";
my  $doccopy2       =   "$ENV{PERLDATA}"."/docs/Doc4_change.docx";

my  $docxdir        =   "$ENV{PERLPROJ}"."/DOCX";
my  $xmlfile        =   "$ENV{PERLPROJ}"."/DOCX/[Content_Types].xml";
my  $relsfile       =   "$ENV{PERLPROJ}"."/DOCX/_rels/.rels";

my  $format         =   {   number  =>  1
                        ,   name    =>  '@spec Code Generation'
                        ,   trailing=>  2                       };

my  $message        =   sprintf "Reading %s file",$workbookfile;
my  $message2       =   sprintf "Reading %s CSV file",
my  $msg_info       =   {   date    =>  `TZ='America/Los_Angeles' 
                                         date +%Y/%m/%d-%H:%M:%S`
                        ,   proc    =>  $message     };                         # message information
my  $msg_info2      =   {   date    =>  `TZ='America/Los_Angeles' 
                                         date +%Y/%m/%d-%H:%M:%S`
                        ,   proc    =>  $message2    };                         # message information


my  $logm           =   activity_message(   $msg_info   );                      #   creating a log message
my  $logm2          =   activity_message(   $msg_info2  );                      #   creating a log message
log_activity    ( $logf, $logm  );                                    
log_activity    ( $logf, $logm2 );                                    

file_exists (   $docname    );
system "unzip -oq  $docname -d DOCX";
#my $xml_content =   [read_xml( $xmlfile )];
my $rel_content =   [read_xml( $relsfile )];
#list_array  (   $xml_content,   {   name    =>  $xmlfile
#                                ,   number  =>  'ON'    }   );

#list_xml    (   $xml_content,   {   name    =>  $xmlfile
#                                ,   leading =>  1
#                                ,   trailing=>  2
#                                ,   number  =>  'ON'    }   );
list_parts  (   $docname    );

list_xml    (   $rel_content,   {   name    =>  $relsfile
                                ,   leading =>  1
                                ,   trailing=>  2
                                ,   logging =>  'ON'
                                ,   number  =>  'ON'    }   );
my  $xml_in =   insert_heading ({   style   =>  'Heading1'
                                ,   text    =>  'Introduction to Docx'  }   );

#update_docx (  [$xmle], [$docx], {$where}  ) 

update_docx (   $xml_in                                 #   insert XML element
            ,   $doccopy2                               #   document name
            ,   {   file        =>  'document.xml'
                ,   level       =>  'w:body'
                ,   appearance  =>  1                   #   1, 2, all, last
                ,   hit         =>  'top'
                ,   where       =>  'after'   }   );

write_docx  (   $docxdir,   $doccopy    );

exit 0;


#================================================================================
sub		file_exists	{
		my	(	$filename	)	=	@_;
		unless ( -e $filename ) {
			printf "%5sFile%s%s%s\n",'',' 'x16,$filename,' not found !!';
			exit 1;                                                             #   Protective Termination
		}# 
}#sub	file_exists
