package XML;
# File          XML.pm
#
# Refactored    01/18/2019          
# Author        Lutz Filor
# 
# Synopsys      XML::read_xml() Reading UTF-8 text files,
#               with presumingly xml content, into array w/ XML string
#               
#               XML::preserve_space() restoring XML string, 
#               encode record separator properly
#
#               XML::split 

use strict;
use warnings;
use feature 'state';

use Readonly;

use lib                     qw  (   ~/ws/perl/lib       );                  # Relative UserModulePath
use Dbg                     qw  (   debug subroutine    );
#use UTF8                   qw  (   read_utf8   write_utf8  );              # 05/07/2019 modified
use File::IO::UTF8::UTF8    qw  (   read_utf8   write_utf8  );

#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.01");

use Exporter qw (import);
use parent 'Exporter';                              # parent replaces base

our @EXPORT    = qw(
                   );   #implicite

our @EXPORT_OK = qw(    read_xml
                        preserve_space
                   );   #explicite

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
# C O N S T A N T S

#----------------------------------------------------------------------------
# S U B R O U T I N S


sub   read_xml  {
      my    (   $f  )   =   @_;
      open (my $fh,'<:encoding(UTF-8)',"$f")
      || die " Cannot open file $f";                # Part of the document
      #printf STDERR "%s\n",$f;
      my @xml=<$fh>;                                # Read file into array buffer
      close (  $fh );
      return @xml;
}#sub read_xml


sub   preserve_space {
      my    (   @arr    ) = @_;
      my @xmli;                                     # internal xml packed array

      $xmli[0] = $arr[0];                           # copy xml Prolog
      if ( $#arr == 1 )  {
          $xmli[1] = $arr[1];                       # copy packed xml string
      } elsif ( $#arr > 1) {                        # Multi line xml string
          my $xml_str_tmp = join '', @arr[1..$#arr];# gluing the array together
          $xml_str_tmp =~ s/\x0d\x0a/&#xD;&#xA;/g;  # preserve CR,LF in XML string
          $xmli[1] = $xml_str_tmp;                  # copy rejoined xml string
      }#
      return @xmli;                                                                 
}#sub preserve_space


sub   print_xml_string  {
      my    (   $xmls                                                               # avoid processing, keep the string
            ,   $opts_ref   )   = @_;
      #$opts_ref //= \%opts;
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

#----------------------------------------------------------------------------
# End of module
1;
