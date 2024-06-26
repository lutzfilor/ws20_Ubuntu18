package DS::String;
# File          DS/String.pm
#
# Created       11-15-2020          
# Author        Lutz Filor
# 
# Synopsys      Strings are an elementary data structure and working
#               wish hashes requires, to support the data structure
#               
#               DS::String::capitalize  ( $string )     #   return  Capitalize      majuscule
#               DS::String::lowercase   ( $string )     #   return  capitalize      minuscule
#               DS::String::uppercase   ( $string )     #   return  CAPITALIZE      all caps
#                                                       #   returb  cAPITALIZE      lower case first
#               DS::String::Titlecase   ( $string )     #   return  ThisIsTitlecase CamelCase
#
#               DS::String::es()  Finding the path to or the location 
#                               of an installed Perl Module
#
#   Note        Snake case/pothole case (underscore)
#               Kebab case              (hyphen)        spinal/param/Lisp/dash/TRAIN-CASE
#               Studly case w/ no syntactical use

use strict;
use warnings;

use Switch;
#use Readonly;

use lib	"$ENV{PERLPATH}";                           #   Add Include path to @INC

use App::Dbg        qw  (   debug       
                            subroutine  );          #   Debug features

use DS::Array       qw  (   size_of
                            maxwidth    );          #   ArrayRef functions

use Terminal        qw  (   t_warn      );

#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.05");

use Exporter qw (import);
use parent 'Exporter';                              #   parent replaces use base 'Exporter';

#our @EXPORT    = qw    (   );#implicite            #   Deprecated implicite export

our @EXPORT_OK  = qw    (   sizeofstring
                            capitalize
                            lowercase
                            uppercase
                        );#explicite

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ]
                        );
#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     sizeofstring{ my ($string) = @_; return length($string); }#sub sizeofstring
sub     capitalize  { my ($string) = @_; return ucfirst($string);}#sub capitalize
sub     lowercase   { my ($string) = @_; return lc($string);     }#sub lowercase
sub     uppercase   { my ($string) = @_; return uc($string);     }#sub uppercase

#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D S




#----------------------------------------------------------------------------
#       End of module DS/String.pm
1;
