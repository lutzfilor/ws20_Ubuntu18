package Find;
# File          Find.pm
#
# Refactored    01/18/2019          
# Author        Lutz Filor
# 
# Synopsys      Find::modules() Finding the path to or the location 
#                               of an installed Perl Module
#

use strict;
use warnings;

use Readonly;
#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.01");

use Exporter qw (import);
use parent 'Exporter';                              # parent replaces use base 'Exporter';

our @EXPORT     = qw    (    
                        );#implicite

our @EXPORT_OK  = qw    (    modules
                        );#explicite

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ]
                        );
#----------------------------------------------------------------------------
# C O N S T A N T S

#----------------------------------------------------------------------------
# S U B R O U T I N S

sub     modules  {
        my  (   @list   )   = @_;
        foreach my $module  ( @list )   {
            printf "%*s%s\n",5,'','module';
        }#foreach
        printf  "\n";
        exit;
}#sub   modules
        

# for my $module ( @ARGV ) {
#     my $package = $module;
# 
#     # From This::That to This/That.pm
#     s/::/\//g, s/$/.pm/ for $module;
# 
#     if ( require $module ) {
#         print $package . " => " . $INC{$module} . "\n";
#     }
# }



#----------------------------------------------------------------------------
# End of module Find.pm
1;
