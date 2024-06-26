package PPCOV::FileIO;
# File          PPCOV/FileIO.pm
#
# Refactored    01/25/2019          
# Author        Lutz Filor
# 
# Synopsys      FileIO::filename_generator() creates unique 
#                                          derivative
#               02/13/2019  add sheetname_generator()   create unique name
#               03/05/2019  add file_exists()			guard against typoes

use strict;
use warnings;

use Readonly;
use File::Basename;
use POSIX                       qw  (   strftime        );                      # Format string

use lib							qw  (   /mnt/ussjf-home/lfilor/ws/perl/lib );   # Add Include path to @INC
use Dbg                         qw  (   debug 
                                        subroutine      );


use File::IO::UTF8::UTF8        qw  (   read_utf8   
                                        write_utf8      );
#use lib             qw  (   ../lib          );                                 # Relative UserModulePath
#use UTF8            qw  (   read_utf8                                          # 05-08-2019
#                            write_utf8      );

#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.03");

use Exporter qw (import);                      # Import <import> function
use parent 'Exporter';                              # parent replaces base

our @EXPORT     = qw(    
                    );#implicite export             # NOT recommended to use

our @EXPORT_OK  = qw(   file_exists
						filename_generator
                        sheetname_generator
                    );#explicite export             # RECOMMENDED

our %EXPORT_TAGS=   ( ALL => [ @EXPORT_OK ]
                    );

#----------------------------------------------------------------------------
# C O N S T A N T S

#----------------------------------------------------------------------------
# S U B R O U T I N S

sub		file_exists	{
		my	(	$filename	)	=	@_;
		unless ( -e $filename ) {
			printf "%5sFile%s%s%s\n",'',' 'x16,$filename,' not found !!';
			exit;
		}# 
}#sub	file_exists

sub     filename_generator  {
        my  (   $opts_ref   )   =   @_;
        my  $fullname           
        =   ${$opts_ref}{workbook};                 # absolute path/filename
        my  (   $na,$pa,$su )   
        =   fileparse( $fullname, qr{[.][^.]*} );
        my  $i = ${$opts_ref}{indent};              # indentation
        my  $p = ${$opts_ref}{indent_pattern};      # indentation pattern
        my  $u = strftime '_%Y-%m-%d', localtime;   # unique
        my  $d = $na.$u.$su;                        # derived name
        printf  "%*s%s %s\n",$i,$p,'Source Name',$fullname;
        printf  "%*s%s %s\n",$i,$p,'Date       ',$u;
        printf  "%*s%s %s\n",$i,$p,'Output Name',$d;
        ${$opts_ref}{output}    =   $d;
        return $d;
}#sub   filename_generator


sub     sheetname_generator {
        my  (   $opts_ref   )   =   @_;
        my  $i = ${$opts_ref}{indent};              # indentation
        my  $p = ${$opts_ref}{indent_pattern};      # indentation pattern
        my  $u = strftime '%Y-%m-%d', localtime;    # unique
        ${$opts_ref}{sheetname} =   $u;
        return $u;                                  # sheet name
}#sub   sheetname_generator


#----------------------------------------------------------------------------
# End of module
1;
