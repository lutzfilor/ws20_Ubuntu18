package XLSX;
# File      XLSX.pm
#
# Author    Lutz Filor
# Synopsys  Document library for .xlsx documents
#
#---------------------------------------------------------------------------
# L I B R A R I E S


use strict;
use warnings;

use version; our $VERSION =version->declare("v1.00.02");

use File::Basename;
use Readonly;                                       

use lib                     qw  (   ~/ws/perl/lib       );                      # Relative path to User Modules
#use lib             qw  (   ../lib );                                          # Relative path to User Modules 05/07/2019
use Dbg                     qw  (   debug subroutine    );
use File::IO::UTF8::UTF8    qw  (   read_utf8   write_utf8  );
use XML                     qw  (   read_xml  preserve_space  );

#---------------------------------------------------------------------------
# I N T E R F A C E

use Exporter qw (import);
use parent 'Exporter';                              # replaces deprecated use base


our @EXPORT    = qw(    read_workbook
                        new
                   ); # .xlsx documents

our @EXPORT_OK = qw(    read_workbook
                        initialize
                        $VERSION
                   ); # parser
                        
our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------

#%supported_file_types   =   {   .xlsx   =>  &read_xlsx()


#----------------------------------------------------------------------------
# C O N S T A N T S

Readonly my $TAGN           =>  qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]* }xms;        # XML Tag name
Readonly my $XMLAN          =>  qr  {   [_a-zA-Z][_\-:.a-zA-Z0-9]* }xms;        # XML Attribute name
Readonly my $XMLAV          =>  qr  { (?|['][^']*['] | ["][^"]*["]) }xms;       # XML Attribute value single/double quoted string
Readonly my $XMLA           =>  qr  {   \s+ $XMLAN [=] $XMLAV   }xms;           # XML Attribute
Readonly my $XML_ELEMENT    =>  qr  {   [^><]+                  }xms;           # Any character Inside opening and closing XML TAG
Readonly my $XMLE           =>  qr  {   [<]\B$TAGN\b                            # XML opening tag
                                        ($XMLA*)\s*[>]                          # w/ optional XML attribute
                                        $XML_ELEMENT                            # XML element data
                                        [<][/]$TAGN [>]         }xms;           # XML closing tag matching
Readonly my $XML_NEO        =>  qr  {   [<]($TAGN\b)                            # XML nested element opening tag
                                        ($XMLA*)[>]             }xms;           # w/ optional XML attribute
Readonly my $XML_NEC        =>  qr  {   [<][/]$TAGN[>]          }xms;           # XML nested element closing tag
Readonly my $XMLE_ST        =>  qr  {   [<]$TAGN\s+.*[/][>]$    }xms;           # XML self terminating elememt
Readonly my $XML_PRO        =>  qr  {   [<][?](.*)[?][>]        }xms;           # XML Prolog
Readonly my $XML_COM        =>  qr  {   [<][!][-][-]
                                        (.*)[-][-][>]           }xms;

#----------------------------------------------------------------------------
# Class C O N S T R U C T O R
#----------------------------------------------------------------------------
sub   new {
      my    (   $class      
            ,   $fullname   
            ,   $opts_ref   )   =   @_;
      my    (   $na,$pa,$su )   =   fileparse( $fullname, qr{[.][^.]*} );
      my    $n      =   subroutine('name');
      printf "     Constructor() called\n" if( debug($n) );
      my $self = {
         _opts      =>  $opts_ref,
         _filename  =>  $fullname,
         _path      =>  $pa,
         _name      =>  $na,
         _suffix    =>  $su,
         _content   =>  [],                                 # Table of content Files
         #_data     =>  {},                                 # document data
      };
      bless     $self,  $class;
      return    $self;
}#sub new 

#----------------------------------------------------------------------------
# Class M E T H O D S  -  S U B R O U T I N S
#----------------------------------------------------------------------------
sub   initialize    {
      my    $self   =   shift;
      my    $f      =   $self->{_filename};
      my    $i      =   ${$self->{_opts}}{indent};
      my    $p      =   ${$self->{_opts}}{indent_pattern};
      my    $n      =   subroutine('name');
      #my    %c      =   {   _fname  =>  $f,
      #                      _xmls   =>  [],
      #                      _xmle   =>  [],
      #                      _data   =>  []      };          # content container
      system `rm -rf 'XLSX'`  if ( -e 'XLSX' );             # remove old temporary document
      system `mkdir XLSX` unless ( -e 'XLSX' );             # create temporary directory          
      printf "%*s%s () called\n",$i,$p,$n if( debug($n) );
      system "unzip -q $f -d XLSX";                         # unpack document into temporary directory
      @{$self->{_content}} = `find ./XLSX -type f`;         # get list of files
      my $s  = length($#{$self->{_content}});               # format counter 
      while (my ($c, $fn) = each @{$self->{_content}}) {
        chomp $fn;  
        printf "%*s(%*s) %s\n",$i,$p,$s,$c+1,$fn            if( debug($n) );
        unless($fn =~ m/.bin$/xms)  {                       # (?|.xml|.rels)$
            my @xmls = read_xml ( $fn );                    # read xml string from xml file
            @xmls = preserve_space ( @xmls );               # preserve and compact xml string
            ${$self->{_opts}}{cnt} = $c+1;                  # support container     # logging support #number
            report_container( $self, $fn );                                         # logging support # filename
            my @xmle                                        # Array of XML elements
            = breakup_xml_string( $self, \@xmls );          # XML string w/ XML elements
            $self->{_data}{$fn}{_fname} = $fn;
            $self->{_data}{$fn}{_xmls}  = [ @xmls ];
            $self->{_data}{$fn}{_xmle}  = [ @xmle ];
            if ( $fn =~ m/XLSX\/xl\/worksheets\/sheet4\.xml/xms ) {
                printf " Examine me !!\n";
                decode_xml_element ( $self, \@xmle );
            }#if
            parse_xml_element( $self, \@xmle, 'tmp3' ); 
        }#unless
      }#while
      logging_container( $self );
}#sub initialize


sub   breakup_xml_string    {
      my    (   $self                                       # reference to workbook
            ,   $x_ref       )   = @_;                      # XML prolog, XML string w/ joined XML elements
      my @xmle;                                             # Array of XML elements
      while (my ($lc, $xmls) = each @{$x_ref}) {            # XML string of joined XML elements
            # $xmls unchomped !!                            # preserve separators
            $xmls   =~ s/></>><</g;                         # create a sacrifice
            my @tmp =  split (/></, $xmls);                 # splitt string into elements
            push ( @xmle, @tmp );                           # XML prolog & XML string together
            report_xml_string($self, $lc, $xmls);

      }#whole XML file
      return @xmle;                                         # Array of XML elements
}#sub breakup_xml_string     


sub   report_xml_string {                                   # Auxillary logging subroutine
      my    (   $self
            ,   $lc                                         # XLM string count (should be two)
            ,   $xmls   )   = @_;
      my    $i      =   ${$self->{_opts}}{indent};
      my    $p      =   ${$self->{_opts}}{indent_pattern};
      my    $n      =   'breakup_xml_string';               # hard coded intentionally  
      if( debug($n) ) {
          printf "%*s%*s: %s",$i,$p,4,$lc,$xmls;            # Terminal display verbose
      }#debug
      chomp $xmls;                                          # ^M is preserved after prolog
      my $lm = sprintf "%*s%*s: %s",$i,$p,4,$lc,$xmls;
      push ( @{${$self->{_opts}}{tmp}} , $lm);              # teardown .xlsx content
      push ( @{${$self->{_opts}}{tmp2}}, $lm);              # parsing
      push ( @{${$self->{_opts}}{tmp3}}, $lm);              # experimental
}#sub report_xml_string

sub   decode_xml_element {                                  # ( $self, \@xmle )
      my    (   $self
            ,   $x_ref  )   = @_;
      while (my ($c, $xmle)  = each @{$x_ref} ) {
          #push ( @{${$self->{_opts}}{tmp5}},sprintf "%*s(%s)",$i,$p,$xmle); 
           push ( @{${$self->{_opts}}{tmp5}},sprintf "%*s(%s)",5 ,'',$xmle); 
      }#while
}#sub decode_xml_element

sub   parse_xml_element {
      my    (   $self
            ,   $xmle_ref
            ,   $tmp        )   = @_;
      my $i = ${$self->{_opts}}{indent};
      my $p = ${$self->{_opts}}{indent_pattern};                                         # ${$opts_ref}{padding_pattern}
      my $n = 1;
      for my $xmle ( @{$xmle_ref} ) {
          chomp ($xmle);
          #printf "%*s(%s)++\n",$i,$p,$xmle;                                        # Silenced

          #push ( @{${$opts_ref}{$tmp}}, "\n" );
          push ( @{${$self->{_opts}}{$tmp}},sprintf "%*s(%s)",$i,$p,$xmle);
          push ( @{${$self->{_opts}}{tmp2}},sprintf "%*s(%s)",$i,$p,$xmle);              # Track XML elements
          push ( @{${$self->{_opts}}{tmp4}},sprintf "%*s(%s)",$i,$p,$xmle);              # Parse XML elements, identification
          $n++;
          if ( $xmle =~   m{^\s*(<(?|/|\?)?)                                        # XML Start TAG begin
                            #   ([_a-zA-Z:]+)                                       # Forgot numbers and colon
                            #   ([a-zA-Z][_a-zA-Z:0-9]+)                            # XML tag name, single character tags
                                ([a-zA-Z][_a-zA-Z:0-9]*)                            # XML tag name
                            #   $TAGN
                              (\s(\w+=".+")?)?                                      # XML attribute, multiple attributes
                                ((?|/|\?|)? >)                                      # XML Start TAG end
                                ([^<]+)?                                            # XML elememt
                                (</\1>)?                                            # XML End TAG
                           }xms          ) {
                push( @{${$self->{_opts}}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAG open',$1);
                push( @{${$self->{_opts}}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAG name',$2);
                push( @{${$self->{_opts}}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML Attribut',(defined $4)?$4:'none');           # if undef no Attribute
                push( @{${$self->{_opts}}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAGclose',$5);
                push( @{${$self->{_opts}}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML Element ',(defined $6)?$6:'empty');
                push( @{${$self->{_opts}}{$tmp}},sprintf "%*s%s :: %s",$i+$n*4,$p,'XML TAG end ',(defined $7)?$7:'skipped');
          }# match
          $n--;
      }#for
}#sub parse_xml_element

sub   get_attribute{my($self,$atr)= @_; return $self->{$atr};      }#sub get_attribute
sub   get_filename { my ( $self ) = @_; return $self->{_filename}; }#sub get_filename
sub   get_path     { my ( $self ) = @_; return $self->{_path};     }#sub get_path
sub   get_name     { my ( $self ) = @_; return $self->{_name};     }#sub get_name
sub   get_suffix   { my ( $self ) = @_; return $self->{_suffix};   }#sub get_suffix
sub   get_content  { my ( $self ) = @_; return $self->{_content};  }#sub get_content @array

sub   get_xmle      { 
      my (  $self   )   = @_;
      while (my ($c, $fn) = each @{$self->{_content}}) {
          chomp $fn;
          my $s1 = $#{$self->{_data}{$fn}{_xmls}};
          my $s2 = $#{$self->{_data}{$fn}{_xmle}};
          printf "%5s%s %s\n", '','filename  :', $fn;
          printf "%5s%s %s\n", '','xmls size :', $s1+1;
          printf "%5s%s %s\n", '','xmle size :', $s2+1;
      }#
}#sub get_xmle


sub   report_container{
      my $self  = shift;
      my $f     = shift;
      my $n = subroutine('name');
      my $i = ${$self->{_opts}}{indent};
      my $p = ${$self->{_opts}}{indent_pattern};                                    # ${$opts_ref}{padding_pattern}
      my $c = ${$self->{_opts}}{cnt};
      my $lm= sprintf "\n\n%*s(%2s)%s %s",$i,$p,$c,$f,'FILE content :';
      push ( @{${$self->{_opts}}{tmp}},  $lm);                                      # capture message
      push ( @{${$self->{_opts}}{tmp2}}, $lm);
      push ( @{${$self->{_opts}}{tmp3}}, $lm);                                      # XML string
      push ( @{${$self->{_opts}}{tmp4}}, $lm);
}#sub report_container


sub   logging_container {
      my $self = shift;
      write_utf8_wrapper($self, ${$self->{_opts}}{tmp} ,'logs/parse_xlsx.log');
      write_utf8_wrapper($self, ${$self->{_opts}}{tmp2},'logs/parse_xmlf.log');
      write_utf8_wrapper($self, ${$self->{_opts}}{tmp3},'logs/parse_xmls.log');
      write_utf8_wrapper($self, ${$self->{_opts}}{tmp4},'logs/parse_xmle.log');
      write_utf8_wrapper($self, ${$self->{_opts}}{tmp5},'logs/experiment.log');
      
}#sub logging_container


sub   write_utf8_wrapper {
      my    (   $self
            ,   $a_ref                                                              # tmp arry buffer
            ,   $file_name      )   = @_;
      my $i = ${$self->{_opts}}{indent};
      my $p = ${$self->{_opts}}{indent_pattern};                                                             # ${$opts_ref}{padding_pattern}
      my $n = subroutine('name');
      printf "%*s%s()\n",$i,$p,$n if( debug($n));
      printf "%*s%s : %s\n", $i,$p,'LogFile ', $file_name;
      write_utf8 ( $a_ref, $file_name );
}#sub write_utf8_wrapper


sub   read_xml_file {
      my    $self   =   shift;
      my    $f      =   shift;                                                      # Get file name
      my $n = subroutine('name');
      my $i = ${$self->{_opts}}{indent};
      my $p = ${$self->{_opts}}{indent_pattern};                                    # ${$opts_ref}{padding_pattern}
      my $c = ${$self->{_opts}}{cnt};
      if ( defined $f ) {
          printf "%*s%s %s",$i,$p,$f,'File name :'
      }

      my $lm= sprintf "\n\n%*s(%2s)%s %s",$i,$p,$c,$f,'FILE content :';             # log message                       FIX ME

      printf "\n\n"  if( debug($n) );
      printf "%*s%s  --\n",$i,$p,$f if( debug($n) );                                # file name
      push ( @{${$self->{_opts}}{tmp}},  $lm);                                      # capture message
      push ( @{${$self->{_opts}}{tmp2}}, $lm);
      push ( @{${$self->{_opts}}{tmp3}}, $lm);                                      # XML string
      push ( @{${$self->{_opts}}{tmp4}}, $lm);

      open (my $fh,'<:encoding(UTF-8)',"$f")
      || die " Cannot open file $f";                                                # Part of the document
      my @xml=<$fh>;                                                                # Read file into array
      close (  $fh );

      @xml = preserve_space ( @xml );                                               # preserve and compact xml string

      my $lc    = 0;
      for my $line ( @xml) {
            $lc++;
            chomp $line;                                                            # ^M is preserved
            printf "%*s%*s: %s\n",$i,$p,4,$lc,$line if( debug($n) );                # print XML array line
            $lm = sprintf "%*s%*s: %s",$i,$p,4,$lc,$line;
            push ( @{${$self->{_opts}}{tmp}} , $lm);                                # teardown
            push ( @{${$self->{_opts}}{tmp2}}, $lm);                                # parsing
            push ( @{${$self->{_opts}}{tmp3}}, $lm);                                # experimental
      }#for
      printf "\n\n"  if( debug($n) ); 
      $lc = 0;
      for my $line ( @xml) {
            printf "%*s%*s: %s",$i,$p,4,$lc,$line  if( debug($n) );
            print_xml_string($line);
      }#
      #print_xml_string($xml[1]);
      return @xml;
}#sub read_xml_file


### sub     filename_generator  {
###         my  (   $opts_ref   )   =   @_;
###         my  $fullname           =   ${$opts_ref}{workbook};
###         my  (   $na,$pa,$su )   =   fileparse( $fullname, qr{[.][^.]*} );
###         my  $i = ${$opts_ref}{indent};              # indentation
###         my  $p = ${$opts_ref}{indent_pattern};      # indentation pattern
###         
###         printf  "%*s%s %s\n",$i,$p,'Source Name',$fullname;
###         
### }#sub   filename_generator


#----------------------------------------------------------------------------
# End of module

1;
