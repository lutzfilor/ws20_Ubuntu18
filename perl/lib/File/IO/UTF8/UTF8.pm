package File::IO::UTF8::UTF8;
# File          ~/ws/perl/lib/File/IO/UTF8/UTF8.pm
#
# Refactored    01/21/2019
#               04/04/2019          lib/UTF8.pm ->  lib/File/IO/UTF8/UTF8.pm
#               
# Author        Lutz Filor
# 
# Synopsis      UTF8::read_utf8()       Reading UTF-8 text file ->  text string arrary
#               UTF8::read_utf8_slurp() Reading UTF-8 text file ->  text string single multiline
#               UTF8::read_utf8_string()Reading UTF-8 text file ->  text string single line \n removed
#               UTF8::write_utf8()      Writing text array      ->  UTF-8 encoded file
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use lib				"$ENV{PERLPATH}";               # Add Include path to @INC

use Readonly;
use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;

use File::Basename;
use POSIX           qw  (   strftime    );			# Format string

use Dbg             qw  (   debug 
					   		subroutine  );
use PPCOV::DataStructure::DS    qw  /   list_ref    /;  # Data structure
use Dbg             qw  (   debug subroutine    );

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.06");

use Exporter qw (import);
use parent 'Exporter';                              # replaces base; base is deprecated


our @EXPORT    =    qw(
                      ); # UTF-8 encoded Files

our @EXPORT_OK =    qw(     read_utf8
                            read_utf8_slurp
                            read_utf8_string
                            write_utf8
                      ); # UTF-8 encoded Files

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
# C O N S T A N T S


#----------------------------------------------------------------------------
# S U B R O U T I N S

sub   read_utf8 {
      my    (   $f  )   =   @_;
      open (my $fh,'<:encoding(UTF-8)',"$f")
      || die " Cannot open file $f";                # Part of the document
      #printf STDERR "%s\n",$f;
      my @text=<$fh>;                               # Read file into array buffer
      close (  $fh );
      return @text;                                 # Return array buffer
}#sub read_utf8


sub   read_utf8_slurp   {
      my    (   $f  )   =   @_;
      open (my $fh,'<:encoding(UTF-8)',"$f")
      || die " Cannot open file $f";                # Part of the document
      #printf STDERR "%s\n",$f;
      my $text=do { local $/; <$fh>};               # Read file into stringbuffer
      printf STDERR "%5s%s%s\n",'','SizeofString ', length $text;
      close (  $fh );
      return $text;        
}#sub read_utf8_slurp


sub   read_utf8_string  {                           # EXPERIMENTAL
      my    (   $f  )   =   @_;
      open (my $fh,'<:encoding(UTF-8)',"$f")
      || die " Cannot open file $f";                # Part of the document
      my $data;
      while ( my $line = <$fh> ) {
          chomp($line);
          $data .= $line;
      }#while
      return $data;
}#sub read_utf8_string


sub   write_utf8 {
      my    (   $a_ref                              # tmp array buffer -> file
            ,   $file_name)   = @_;                 # 
      open(my $fh,'>:encoding(UTF-8)',$file_name);
      foreach my $line ( @{$a_ref} ) {
         printf $fh "%s\n",$line;
      }#foreach
      close( $fh );      
}#sub write_utf8

#----------------------------------------------------------------------------
# End of module
1;
