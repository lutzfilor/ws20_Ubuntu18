package Create::Directory::Directory;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/Create/Director/Directory.pm
#
# Created       04/04/2019          
# Author        Lutz Filor
# 
# Synopsys      Create::Directory::Directory::new_subdirectiroy()
#                       input   [ @of_worksheets ] 
#								, $filename
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;


use File::Basename;
use POSIX                       qw  (   strftime    );			# Format string

use lib                         qw  (   ~/ws/perl/lib );        # Relative UserModulePath from user
use Dbg                         qw  (   debug 
					            		subroutine  );
use Logging::Record             qw  (   log_msg
                                        log_lmsg    );

use File::Header::Add           qw  /   add_header  /;  # .xlsx controlled header
#use File::IO::UTF8::UTF8        qw  /   read_utf8
#                                        write_utf8  /;  
#use UTF8                        qw  (   read_utf8   );
use PPCOV::DataStructure::DS    qw  /   list_ref    /;  # Data structure


#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.01");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   makepaths
                            _makepath
						);#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S

sub     makepaths {
        my  (   $directories                        # [ list w/ directories ]
            ,   $format     )   = @_;               # { format hash }
        my  $i  =   ${$format}{indent};
        my  $p  =   ${$format}{indent_pattern};
        my  $v  =   ${$format}{verbose};
        my  $d  =   ${$format}{dryrun};
        my  $n  =   subroutine('name');             # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n";
            printf  "%*s%s()\n",$i,$p,$n;
            printf  "%*s%s\n"  ,$i,$p,'Dry run' if $d;
        }# debug
        foreach my $dpath  ( @{$directories} ) {
            printf  "%*s%s %s\n"
                    ,$i,$p,'subdirectory',$dpath;
            _makepath   ($dpath) unless ($d);
        }# for all entries
}#sub   makepaths

sub     _makepath    {
        my  (   $directory  )   = @_;               # Single path
        system "mkdirhier $directory";
        printf "%10s%s%s\n",'','created ', $directory;
}#sub   _makepath

#		if ( debug($name)) {
#			printf "%*s%s\n", 5,'',"File $f found";
#			printf "%*s%s\n",10,'','ASCII/UTF-8 Text file' if ( -T $f);
#			printf "%*s%s\n",10,'','Binary file'           if ( -B $f);
#			printf "%*s%s\n",10,'','readable'              if ( -r $f);
#			printf "%*s%s\n",10,'','writeable'             if ( -w $f);
#		}#if debug


#----------------------------------------------------------------------------
#  End of module Create::Library::Library
1
