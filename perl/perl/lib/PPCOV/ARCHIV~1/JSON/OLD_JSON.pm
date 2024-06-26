package PPCOV::JSON;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/PPCOV/JSON.pm
#
# Created       02/04/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::JSON::read_JSON()
#                       input   col Instance from Coverage Specification tab
#                       return  list of design instances
#
# Data model    [workbook]->@[sheet]->@name,[data]->@[col]->@cell
#                                          
#               
#----------------------------------------------------------------------------
#  I M P O R T S 
use strict;
use warnings;
use Readonly;
use JSON;

use lib             qw  (   ../lib );               # Relative UserModulePath
use Dbg             qw  (   debug subroutine    );
use UTF8            qw  (   read_utf8   
                            read_utf8_slurp     );

#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.01");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   _load_json
                            test_json
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S
#eadonly my $TAGN           =>      qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]+ }xms;        # XML Tag name
Readonly my $TAGN           =>      qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]* }xms;        # XML Tag name

#eadonly my $XMLAN          =>      qr  {   \b\w+                   }xms;           # XML Attribute name
Readonly my $XMLAN          =>      qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]* }xms;        # XML Attribute name

#Readonly my $XMLAV         =>      qr  {   ['].*[']|["].*["]       }xms;           # XML Attribute value single or double quoted string
#Readonly my $XMLAV         =>      qr  {   ['][^']*[']|["][^"]*["] }xms;           # XML Attribute value single or double quoted string
Readonly my $XMLAV          =>      qr  { (?|['][^']*['] | ["][^"]*["]) }xms;       # XML Attribute value single or double quoted string
Readonly my $XMLA           =>      qr  {   \s+ $XMLAN [=] $XMLAV   }xms;           # XML Attribute

Readonly my $XML_ELEMENT    =>      qr  {   [^><]+                  }xms;           # Any character Inside opening and closing XML TAG

Readonly my $XMLE           =>      qr  {   [<]\B$TAGN\b                            # XML opening tag
                                            ($XMLA*)\s*[>]                          # w/ optional XML attribute
                                            $XML_ELEMENT                            # XML element data
                                            [<][/]$TAGN [>]         }xms;           # XML closing tag matching
Readonly my $XML_NEO        =>      qr  {   [<]($TAGN\b)                            # XML nested element opening tag
                                            ($XMLA*)[>]             }xms;           # w/ optional XML attribute

#Readonly my $XML_NEO        =>      qr  {   [<]($TAGN\b)                            # XML nested element opening tag
#                                            (.*)[>]                 }xms;           # w/ optional XML attribute


#Readonly my $XML_NEC       =>      qr  {   [<][/](.*)[>]           }xms;           # XML nested element closing tag
Readonly my $XML_NEC        =>      qr  {   [<][/]$TAGN[>]          }xms;           # XML nested element closing tag
Readonly my $XMLE_ST        =>      qr  {   [<]$TAGN\s+.*[/][>]$    }xms;           # XML self terminating elememt
#Readonly my $XMLE_ST       =>      qr  {   [<]($TAGN)\s+           }xms;           # XML self terminating elememt
#                                           $XMLA*[/][>]            }xms;           # w/ optinal XML tag but - without closing tag
#                                           $XMLA*\s*[/][>]         }xms;           # w/ optinal XML tag but - without closing tag
Readonly my $XML_PRO        =>      qr  {   [<][?](.*)[?][>]        }xms;           # XML Prolog
Readonly my $XML_COM        =>      qr  {   [<][!][-][-]
                                            (.*)[-][-][>]           }xms;

#----------------------------------------------------------------------------
#  C O N S T R U C T O R

sub     new {
        my  $class  =   shift;
        my  ( $env  )   = @_;
        
        my $self   =   {};   
        $self   =  {   env =>  $env,   }; 
        bless   $self,  $class;
        #   $self->_initialize();
        
        return  $self;
}#sub   new constructor
#----------------------------------------------------------------------------
#  S U B R O U T I N S

sub     _load_json  {
        my  $self   =   shift;
        my  $file;
        my $json    =   read_utf8   ( $file );
}#sub   _load_json

sub     get_record  {
        my  $self   =   shift;
        my  $file   =   shift;
        my  $znumber=   shift;
}#sub   get_record


sub     test_json {
        my    (   $opts_ref   )   =   @_;
        #         $opts_ref       //= \%opts;                                       # default setting - global var
        my $i = ${$opts_ref}{indent};
        my $p = ${$opts_ref}{indent_pattern};                                       # ${$opts_ref}{padding_pattern}
        my $n = subroutine('name');                                                 # name of subroutine
        my $m;                                                                      # message
        my $t;                                                                      # text
        my $f = "%*s%s :: %s";                                                      # format
        ${$opts_ref}{file} //= 'experimental/pattern.json';
        printf "%*s%s()\n\n", $i,$p,$n;
        printf "%*s%s :: %s\n", $i,$p,'input',${$opts_ref}{file};
        my $json = read_utf8_slurp( ${$opts_ref}{file} );                           # string buffer
        printf "%*s%s length\n",$i,$p,length $json;
        printf "%*s%s\n",$i,$p,$json;
        my $znumber = 'z3077';
        #if    ( $json =~  m{$znumber:}smx)  {
        ##if  ( $json =~  m{$znumber:
        ##                          ( [{]                                             # b         Branch reset group 
        ##                                  (?>[^{}]+:                                # m Atomic group
        ##                                  |(?R))*                                   #   recursive
        ##                                  |'[^']+',
        ##                            [}]   ),                                        # e
        ##                   }smx   )  {
        ##    printf "%*s%s %s\n",$i,$p,'Found ',$znumber;
        ##}#

        ##                    (?| ( [{]                                               # b         Branch reset group 
        ##                                (?>[^}{]+:                                  # m Atomic group
        ##                                |(?R))*                                     #   recursive
        ##                          [}]   ),                                          # e
        ##                      | ( [\[]                                              # alternate list BoL [
        ##                          [^[\]]*                                           #                    list data,
        ##                          [\]]  ),                                          #                EoL ],
        ##                      | ('[^']' ),                                          # alternate 'value string',
        ##                    )

        #if    ( $json =~  m{($znumber:\{(?>[^{}]|(?R))*\},)\nz\d+:
        #if    ( $json =~  m{($znumber:\{(?>[^{}]*|(?R))*\},)\nz\d+:
        #if    ( $json =~  m{($znumber:\{(?>[^{}:]*:|(?R))*\},)\nz\d+:
        ##                    [{]                                                   # b Opening braket

        ##                    (?>[^{}]+:                                            # m Pair key : 
        ##                    |(?R))*                                               #   recursive pattern 
        ##                    [}],                                                  # e Closing braket
        if    ( $json =~  m{    (   $znumber:\{.*\}\n\},   ) 
                                   \nz\d+:
                           }smx )  {
            printf "%*s%s %s\n" ,$i,$p,'Found ',$znumber;
            printf "%*s%s\n"    ,$i,$p,$1;
        }#

}#sub test_json


#----------------------------------------------------------------------------
# End of module
1;
