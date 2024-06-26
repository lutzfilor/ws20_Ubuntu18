package EXP::XML;
# File          EXP/XML.pm
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

use open ":std", ":encoding(UTF-8)";


use lib "$ENV{PERLPATH}";                                                       # Add Include path to @INC
use Dbg                     qw  (   debug subroutine    );
use DS::Array               qw  (   maxwidth
                                    list_array  );
use File::IO::UTF8          qw  (   read_utf8   
                                    write_utf8          
                                    append_utf8 );

#----------------------------------------------------------------------------
#   I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.17");

use Exporter qw (import);
use parent 'Exporter';                                                          #   parent replaces base

#our @EXPORT   = qw(    );                                                      #   Deprecate implicite

our @EXPORT_OK = qw(    read_xml
                        merge_xml
                        get_parts
                        disjoin_xml
                        list_xml
                        list_parts
                        join_xml
                        
                        xml_encoding
                        file_exists
                        path_exists
                        preserve_space  );                                      #   explicite

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#   C O N S T A N T S

# For simple, not nested XML strings
# and not for packed XML strings - no TAG analysis for nested XML elements
 
#Readonly my $TAG_OPEN      =>      qr  { [<]|[<][/]|[<][?] };                  #   Generalization not all permutations are valid XOR
Readonly my $TAG_OPEN       =>      qr  { <([/]|[?])?  };                       #   Generalization not all permutations are valid XOR
Readonly my $TAG_NAME       =>      qr  { \B\w+   };                            #   A welformed XML tag is [<]\D\w+, to capture them all errors are permissable in parsing
Readonly my $TAG_CLOSE      =>      qr  { [>]|[/][>]|[?][>] };                  #   Generalization not all permutations are valid XOR
Readonly my $ANAME          =>      qr  { \b\w+  };
Readonly my $AVALUE         =>      qr  { ['].*[']|["].*["]  }xms;              #   single or double quoted string
Readonly my $XML_ATTRIBUTE  =>      qr  { $ANAME\B[=]\B$AVALUE  }xms;           #   N0 space in XML Attribute specification
Readonly my $XML_CONTENT    =>      qr  { [^><]+    }xms;                       #   Any character Inside opening and closing XML TAG
 
Readonly my $XML_STARTTAG   =>      qr  { $TAG_OPEN                             #   [<]
                                          $TAG_NAME\s+
                                          $XML_ATTRIBUTE*\s*                    #   Optional XML attribute, or multiples, NO withspace between last attribute and closing tag
                                          $TAG_CLOSE            }xms;           #   [/][>] self closing
 
Readonly my $XML_ENDTAG     =>      qr  { $TAG_OPEN                             #   [<]   [<][/]   [<][?]
                                          $TAG_NAME
                                          $TAG_CLOSE    }xms;                   #   [>]   [/][>]   [?][>]
 
 
#Readonly my $XML_ELEMENT    =>      qr  {   ($XML_STARTTAG)?                        # Closing TAG for nested XML elements
#                                            ($XML_CONTENT)?                         # XML elements could be empty
#                                            ($XML_ENDTAG)?      }xms;               # XML self closing element
#==== new xml
 
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
 
#Readonly my $XML_NEO        =>     qr  {   [<]($TAGN\b)                            # XML nested element opening tag
#                                           (.*)[>]                 }xms;           # w/ optional XML attribute
 
 
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
#   S U B R O U T I N S


sub   read_xml  {
      my    (   $f  )   =   @_;
      open (my $fh,'<:encoding(UTF-8)',"$f")
      || die " Cannot open file $f";                # Part of the document
      #printf STDERR "%s\n",$f;
      my @xml=<$fh>;                                # Read file into array buffer
      close (  $fh );
      return @xml;
}#sub read_xml

sub     merge_xml   {
        my  (   $xml_e                                                          #   $xml element
            ,   $xml_d                                                          #   $xml document
            ,   $where  )   =   @_;                                             #   {HashRef} where to insert XML element
        my  $xml_merge  =   [];                                                 #   merged xml document content
        my  $appearance =   $$where{appearance};
        my  $count      =   0;
        for my $line ( @{$xml_d} ) {
            if ( $line =~ m/$$where{level}/ ) {
                $count  +=  1;
                if  ( $count == $appearance )   {
                    if ( $$where{where} eq 'after' ) {
                        push( @{$xml_merge}, $line );
                        copy_xml ( $xml_e, $xml_merge );
                    }
                    if ( $$where{where} eq 'before' ) {
                        copy_xml ( $xml_e, $xml_merge );
                        push( @{$xml_merge}, $line );
                    }
                } else {
                    push( @{$xml_merge}, $line );
                }
            } else {
                push( @{$xml_merge}, $line );
            }# copy head and tail of $xml_d
        }# copy whole document
        return  $xml_merge;
}#sub   merge_xml


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

sub     list_xml    {
        my  (   $a_ref                                                          #   [ArrRef] w/ XML file content
            ,   $format ) = @_;                                                 #   {HashRef} format information 
        my  $name   =   $$format{name};    
        my  $i      =   $$format{indent};
        my  $p      =   $$format{pattern};
        my  $ll     =   $$format{leading};
        my  $n      =   $$format{number};
        my  $align  =   $$format{align};
        my  $tl     =   $$format{trailing};
        my  $logf   =   $$format{logfile};
        my  $ne_log =   $$format{ne_log};                                       #   nesting ending log
        my  $ns_log =   $$format{ns_log};                                       #   nesting starting log
            $i      //= 5;                                                      #   Default indentation
            $p      //= '';
            $ll     //= 0;                                                      #   Default zero leading lines
            $tl     //= 0;                                                      #   Default zero trailing lines
            $align  //= 'unaligned';                                            #   Default alignment is left
            $ne_log //= [];
            $logf   //= "$ENV{PERLDATA}"."/logs/work_with_docx/content.log"; 
        my  $ne_logf  = "$ENV{PERLDATA}"."/logs/work_with_docx/nested_ends.log"; 
        my  $ns_logf  = "$ENV{PERLDATA}"."/logs/work_with_docx/nested_start.log"; 
        my  $log    =   [];                                                     #   temporary Logfile
        my  $a  =   ( $align eq 'right' ) ? 1 :
                    ( $align eq 'left'  ) ?-1 : 1;
        my  $w1 =   maxwidth(   $a_ref  );                                      #   Width of content column
        #printf "%5s%s()\n\n",$p,"list_array";
        #printf "%5s%s %s\n" ,$p,'indent',$i;
        #printf "%5s%s %s\n" ,$p,'maxkey',$w1;
        #printf "%5s%s %s\n" ,$p,'align' ,$align;
        my $tmp =   disjoin_xml(  $a_ref  );                                    #   packed XML string -> array XML elements

        for my $l   (1..$ll) { printf "%*s\n"  ,$i,$p; }
        if ( defined $name ) { 
            printf "%*s%s\n",$i,$p,$name; 
            push ( @{$log}   , sprintf "%*s%s",$i,$p,$name );
            push ( @{$ns_log}, sprintf "%*s%s",$i,$p,$name );
            push ( @{$ne_log}, sprintf "%*s%s",$i,$p,$name );
        }
        if ( defined $$format{number} ) {
            #my  $ln =   $#{$a_ref};
            my  $ln =   $#{$tmp};                                               
            my  $w0 =   length $ln;
                $ln =   1;                                                      #   First entry
            my  $ln1=   1;
            my  $w  =   0;                                                      #   Prime XML element
            my  $tw =   `tput cols`;                                            #   Terminal width
            foreach my $xmle ( @{$tmp} ) {                                      #   XML element
                chomp $xmle;
                $w  +=  nesting_starts( $xmle, $ns_log );                       #   <TAG .... > BUT not ?> or /> or </TAG
                my $m2= sprintf "%*s%*s%2s %s"  ,$w0,$ln1++                     #   numbering XML element
                                                ,$i-$w0,$p                      #   padding number
                                                ,$w                             #   nesting end                    
                                                ,$xmle;                         #   XML element
                push    ( @{$ne_log},  $m2 );
                my $xmles   =   $xmle;                                          #   create a sacrifice
                   $xmles   =~  s/" /" % /g;                                    #   create a sacrifice
                my $xmlss   =   [split(/ % /,$xmles)];                          #   XML element with sacrifice
                if  (   (length $xmle > $tw)
                    &&  ($#{$xmlss}  >    2) ) {                                #   XML substring/ partial strings
                    for my $ix  (0..$#{$xmlss}) {
                        my $wi  =   (   $ix == 0 ) ? $w : $w+4;
                        my $m = sprintf "%*s%*s%*s%s",$w0,$ln++                 #   numbering XML element
                                                     ,$i-$w0,$p                 #   padding number
                                                     ,$wi,$p                    #   indent  XML element
                                                     ,${$xmlss}[$ix];           #   XML element
                        push    ( @{$log}   ,  $m  );                           #   Logging
                        printf  "%s\n",$m;                                      #   Terminal
                    }#for all partial
                } else {
                    my $m = sprintf "%*s%*s%*s%s",$w0,$ln++                     #   numbering XML element -- original
                                                 ,$i-$w0,$p                     #   number padding 
                                                 ,$w,$p                         #   indent  XML element
                                                 ,$xmle;                        #   XML element
                    push    ( @{$log},  $m );                                   #   Logging
                    printf  "%s\n",$m;                                          #   Terminal
                }
                $w  +=  nesting_ends( $xmle, $ne_log );                         #   </TAG>
            }# foreach
        } else { #numbered list
            foreach my $xmle ( @{$tmp} ) {
                my $w =   ( $align eq 'unaligned' )? 1 : $w1;                   #   [Fi] Experiment 09-21-2020
                chomp $xmle;
                my $m =     sprintf "%*s%*s",$i,$p,$a*$w,$xmle;
                push    ( @{$log}, $m );
                printf  "%s\n",$m;
            }# foreach
        }# unnumbered list
        for my $l   (1..$tl) { push ( @{$log}, '' );    }                       #   empty line, vertical whitespace 
        for my $l   (1..$tl) { printf "%*s\n",$i,$p;    }
        #write_utf8( $log, $logf ) if ( defined $$format{trailing} );           #   overwriting
        append_utf8( $log   , $logf    ) if ( defined $$format{logging} );
        append_utf8( $ns_log, $ns_logf ) if ( defined $$format{logging} );
        append_utf8( $ne_log, $ne_logf ) if ( defined $$format{logging} );
        return;
}#sub   list_xml

sub     list_parts   {
        my  ( $docname  )   =   @_;
        my  $ns_log =   [];
        my  $ne_log =   [];
        file_exists (   $docname    );
        system "unzip -oq  $docname -d DOCX";
        my $xmlfile     =   "$ENV{PERLPROJ}"."/DOCX/[Content_Types].xml";
        my $xmlcontent  =   [read_xml( $xmlfile )];
        my $xmle        =   disjoin_xml ( $xmlcontent );
        #list_xml    (   $xmlcontent,    {   name    =>  $xmlfile
        list_xml    (   $xmle,  {   name    =>  $xmlfile
                                ,   leading =>  1
                                ,   trailing=>  2
                                ,   logging =>  'ON'
                                ,   ns_log  =>  $ns_log
                                ,   ne_log  =>  $ne_log
                                ,   number  =>  'ON'    }   );
        my $parts   =   get_parts   (   $xmle   );
        list_doc    (   $parts ,    {   ns_log  =>  $ns_log
                                    ,   ne_log  =>  $ne_log }   );              #   list_array  (   $parts );
        return;
}#sub   list_parts

sub     disjoin_xml {
        my  (   $xmlRef )   =   @_;
        my  $xml_expended   =   [];                                             #   XML element list/ XML extended
        for my $xmls ( @{$xmlRef} )  {                                          #   XML string
                $xmls  =~ s/></>><</g;                                          #   create a sacrifice
            my  @xmle  =  split (/></, $xmls);                                  #   XML element array
            push( @{$xml_expended},@xmle );
        }#for all xml strings
        return $xml_expended;                                                   #   Newlines still included
}#sub   disjoin_xml

sub     break_xmle  {
        my  (   $xmle   )   =   @_;                                             #   XML element string <TAG Attribute1 Attribute2 ...AttributeN>
}#sub   break_xmle

sub     nesting_starts {                                                        #   XML ending on ["/>"], ["?>"] or "["</TAG>"]
        my  (   $xmle                                                           #   XML Element to be evaluated
            ,   $log    )   =   @_;                                             #   XML tmp logging file
        my  $indent = 0;
        my  $c0 =   "XML comment TAG";
        my  $c4 =   "XML closing TAG after XML value";                          #   One liner
        push    ( @{$log}, sprintf "%5s%s",'',$xmle );
        if  ( $xmle =~ m/<\?xml[.]+\?>/xms ) {
            $indent =   0;                     
            my $m = sprintf "%10s%45s %s",'',$c0, $indent; 
            push( @{$log}, $m );
        } else {
            if  ( $xmle =~ m/^<\//xms  )   {
                $indent -=  4;                      
                my $m = sprintf "%10s%45s %s",'',$c4, $indent; 
                push( @{$log}, $m );
            }
        }#  XML Tag clos
        return  $indent;                                                        #   indent;
}#sub   nesting_starts

sub     nesting_ends    {
        my  (   $xmle                                                           #   XML Element to be evaluated
            ,   $log    )   =   @_;                                             #   logging tmp file
        my  $indent = 0;                                                        #   neutral, no nesting
        my  $c0 =   "XML comment TAG";
        my  $c1 =   "XML opening TAG";
        my  $c2 =   "XML opening TAG terminating w/out XML value";
        my  $c3 =   "XML closing TAG w/out XML value";
        my  $c4 =   "XML closing TAG after XML value";                          #   One liner
        push    ( @{$log}, sprintf "%5s%s",'',$xmle );
        #if  ( $xmle =~ m/<\?xml[.]+\?>/xms ) {
        if  ( $xmle =~ m/<\?xml/xms ) {
            $indent =   0;                     
            my $m = sprintf "%10s%45s %s",'',$c0, $indent; 
            push( @{$log}, $m );
        } else {
            if  ( $xmle =~ m/ \/> /xms  )   {                                   #   XML opening TAG left  correction, nesting ends w/out XML value
                $indent  =  0;                                                  #                                       and w/out XML attributes 
                my $m = sprintf "%10s%45s %s",'',$c2, $indent; 
                push( @{$log}, $m );
            } elsif  ( $xmle =~ m/^<\//xms  )   {                               #   XML closing TAG left, - stand alone - is handled
                $indent  =  0;                      
                my $m = sprintf "%10s%45s %s do nothing",'',$c3, $indent; 
                push( @{$log}, $m );
            } else {
                if  ( $xmle =~ m/<[\w]/xms  )   {                               #   XML opening TAG right correction, nesting starts 
                    $indent =   4;                      
                    my $m = sprintf "%10s%45s %s",'',$c1, $indent; 
                    push( @{$log}, $m );
                }

                #   XML Value                                                   #   XML element value
                
                #if  ( $xmle =~ m/<.+>[.]+<\//xms   )   {                           #   XML closing TAG left  correction, nesting ends after XML value
                #if  ( $xmle =~ m/[<]{1}($TAGN) [<]{1}[\/]{1}($TAGN)[>]{1}/xms ) {  #   XML closing TAG left  correction, nesting ends after XML value
                if  ( $xmle =~ m/  [<]{1}[\/]{1}($TAGN)[>]{1}$/xms ) {              #   XML closing TAG left  correction, nesting ends after XML value
                    $indent -=  4;                      
                    my $m = sprintf "%10s%45s %s %s",'',$c4, $indent, $1; 
                    push( @{$log}, $m );
                }
            }
        }# No XML comment
        return  $indent;
}#sub   nesting_ends

sub     get_parts   {
        my  (   $xmleRef    )   =   @_;
        my  $parts  =   [];
        for my  $xlme   ( @{$xmleRef} )  {
            if ( $xlme =~ /PartName="([^"]+)"/ ) {                              #   [0-9a-zA-Z\.\/] Character Class for filenames
                #printf "%*s%s\n",5,'',$xlme;                                   #   Development vestigal
                push( @{$parts}, $1);
            }
        }#
        return $parts;
}#sub   get_parts

sub     list_doc    {
        my  (   $fileRef    
            ,   $attributes )   =   @_;
        #clean logfile;
        my  $logf   = "$ENV{PERLDATA}"."/logs/work_with_docx/content.log";      #   Reset file every run
        my  $ne_logf= "$ENV{PERLDATA}"."/logs/work_with_docx/nested_ends.log"; 
        my  $ns_logf= "$ENV{PERLDATA}"."/logs/work_with_docx/nested_start.log"; 
        unlink( $logf );                                                        #   Delete file
        unlink( $ne_logf );                                                     #   Delete file
        unlink( $ns_logf );                                                     #   Delete file
        for my $part ( @{$fileRef} ) {
            my  $xmlfile    =   "$ENV{PERLPROJ}"."/DOCX".$part;
            my $xmlcontent  =   [read_xml( $xmlfile )];
            my $xmle        =   disjoin_xml     ( $xmlcontent );
            my $attr        =   get_attribute   ( ${$xmle}[0], 'encoding' );
            unless  (   $attr eq 'UTF-8'    )   {
                printf "%*s%s is %s encoded <<<\n",5,'',$xmlfile,$attr;
                printf  "%*sFatal encoding error !! Termination\n\n",5,'';
                exit    1;
            }#                                                                  #   Unexpected encoding scheme
            list_xml    (   $xmle ,{   name     =>  $xmlfile
                                   ,   leading   =>  1
                                   ,   trailing  =>  2
                                   ,   ne_log    =>  $$attributes{ne_log}
                                   ,   ns_log    =>  $$attributes{ns_log}
                                   ,   logging   =>  'ON'
                                   ,   number    =>  'ON'    }   );
            # exit 2;                                                           #   Break after first part
        }# iterate all parts of doc
        return;
}#sub   list_doc

sub     xml_encoding    {
        my  (   $xmlRef )   =   @_;
        #printf "%*s%s",5,'',${$xmlRef}[0];
        my  $t = (${$xmlRef}[0] =~ m/encoding="([^"]+)"/ ) ? $1:'undefined';
        return $t;
}#sub   xml_encoding

sub     get_attribute   {
        my  (   $xmle                                                           #   XML element, string
            ,   $attribute  )   =   @_;                                         #   attribute name
        return ($xmle   =~  m/$attribute="([^"]+)"/ ) ? $1:'Attribute Not found';
}#sub   get_attribute

sub		file_exists	{
		my	(	$filename	)	=	@_;
		unless ( -e $filename ) {
			printf "%5sFile%s%s%s\n",'',' 'x16,$filename,' not found !!';
			exit 1;                                                             #   Protective Termination
		}# 
        return;
}#sub	file_exists

sub     path_exists  {
        my  (   $pathname   )   =   @_;                                         #   path to sub directory
		unless ( -e $pathname && -d $pathname ) {
			printf "%5sPath%s%s%s\n",'',' 'x16,$pathname,' not found !!';
			exit 1;                                                             #   Protective Termination
		}# 
        return;
}#sub   path_exists

#----------------------------------------------------------------------------
#           P r i v a t e  -  M e t h o d s

sub     copy_xml    {
        my  (   $xml_e
            ,   $xml_m  )   =   @_;
        for my  $line   ( @{$xml_e} ) {
            push ( @{$xml_m}, $line );
        }# insert XML nested element at the current tail of document
        return $xml_m;
}#sub   copy_xml

sub     join_xml    {
        my  (   $xmle   )   =   @_;
        my  $xmls   =   [];
        push    ( @{$xmls}, $$xmle[0] );
        push    ( @{$xmls}, join("",@{$xmle}[1..$#{$xmle}]) );
        return $xmls;
}#sub   join_xml
       
#----------------------------------------------------------------------------
#       EXP::XML End of module
1;
