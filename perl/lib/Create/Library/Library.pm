package Create::Library::Library;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/Create/Library/Library.pm
#
# Created       04/04/2019          
# Author        Lutz Filor
# 
# Synopsys      Create::Library::LibraryARM::Monitor::Add::add_new_monitor()
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

use Excel::Writer::XLSX;                            # Spreadsheet::WriteExcel
use Spreadsheet::ParseXLSX;
#use Excel::CloneXLSX::Format;
#use Safe::Isa;

use File::Basename;
use POSIX                       qw  (   strftime    );			# Format string

#use lib                        qw  (   ../lib );               # Relative UserModulePath
use lib                         qw  (   ~/ws/perl/lib );        # Relative UserModulePath from user
use Dbg                         qw  (   debug 
					            		subroutine  );
use Logging::Record             qw  (   log_msg
                                        log_lmsg    );

use File::Header::Add           qw  /   add_header  /;  # .xlsx controlled header
use File::IO::UTF8::UTF8        qw  /   read_utf8
                                        write_utf8  /;  
#use UTF8                        qw  (   read_utf8   );
use PPCOV::DataStructure::DS    qw  /   list_ref    /;  # Data structure


#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.01");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   makepath
						);#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S

sub     makepath    {
        my  ( @refs )   = @_;
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( 'ARRAY' eq ref $refs[0] ) {
        }
        #my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING File $f not found !!");
        my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING File $f not found !!");
        print BLINK BOLD RED $msg, RESET unless $e;
}#sub   makepath


#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

#   string 2 array ref
sub     _makepath    {
        my  (   $path                               # [list of subdir branches]
            ,   $format )   = @_;                   # {format parameter}
        my $i   =   ${$format}{indent};
        my $p   =   ${$format}{padding};
        my $v   =   ${$format}{verbose};
        my $h   =   ${$format}{dryrun};
        foreach my $d ( @{$path}) {                 # directory path from CWD
            #system "unzip $f -d XML";
            printf  "%*s%s\n",$i,$p,$d if ($v);
            system "mkdirhier $d" unless ($h);
        }#foreach entry
}#sub   makepath

#----------------------------------------------------------------------------
#  End of module Create::Library::Library
1
