package EXP::Docx;

=head1 NAME

EXP::Docx - Experimental::Document for Office Documents Module

EXP/Docx.pm - Filepath

=head1 VERSION

Version     v1.00.03


=head1 AUTHOR

Lutz Filor, lutz@pacbell.com

=head1 SYNOPSIS

Docx.pm Module is reading Office Word Documents .docx files.
In the application include 

    use EXP::Docx;

    my $document = Docx::read_docx( $filename );
    ...


=head1 EXPORT

=head2 read_docx

    my $content = Docx::read_docx( $filename );


=head2 write_docx( $filename )



=cut



#
#---------------------------------------------------------------------------
# L I B R A R I E S


use strict;
use warnings;

use version; our $VERSION =version->declare("v1.00.05");

use File::Basename;
use Readonly;                                       

use lib "$ENV{PERLPATH}";                                                       #   Add Include path to @INC
use lib                     qw  (   ~/ws/perl/lib       );                      # Relative path to User Modules
use Dbg                     qw  (   debug subroutine    );
use File::IO::UTF8          qw  (   read_utf8   
                                    write_utf8          );
use EXP::XML                qw  (   read_xml
                                    list_xml
                                    get_parts
                                    disjoin_xml
                                    merge_xml
                                    join_xml
                                    preserve_space      );

#---------------------------------------------------------------------------
# I N T E R F A C E

use Exporter qw (import);
use parent 'Exporter';                              #   replaces deprecated use base


#our @EXPORT    = qw(       );                      #   .docx documents -- deprecated 

our @EXPORT_OK = qw(    write_docx
                        update_docx
                        insert_heading
                        insert_paragraph
                        $VERSION    );              #   implicite import    parser
                        
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

sub     write_docx  {
        my  (   $docx_dir
            ,   $docx_file  )   =   @_;
        #   $docx_dir exists
        #   $docx_file destination/path exists
        #system "zip -r $docx_file $docx_dir";              #   1st trail failed
        system " cd $docx_dir; zip -r $docx_file *";        #   2nd trail succeeded
        system " cp $docx_file /media/sf_Ubuntu_fs1/results/.";
        return;
}#sub   write_docx

#       $$where{file}   =   "$ENV{PERLPROJ}"."/DOCX/document.xml";
#       $$where{level}  =   "w:body";
#       $$where{where}  =   "before|after";

sub     update_docx {
        my  (   $xml_e
            ,   $docx   
            ,   $where  )   =   @_;
        my  $merge  =   [];
        my $xmlfile     =   "$ENV{PERLPROJ}"."/DOCX/[Content_Types].xml";
        my $xmlcontent  =   [read_xml( $xmlfile )];
        my $xmle        =   disjoin_xml ( $xmlcontent );
        my $parts       =   get_parts   (   $xmle   );
        for my $part ( @{$parts} ) {
            my  $xmlfile    =   "$ENV{PERLPROJ}"."/DOCX".$part;
            my  $xmlcontent =   [read_xml( $xmlfile )];
            my  $xmle       =   disjoin_xml     ( $xmlcontent );
            if ( $xmlfile =~ m/$$where{file}/ ) {
                my $doc_c = [read_xml( $xmlfile )];                             #   raw XML content
                my $doc_e = disjoin_xml (   $doc_c  );                          #   XML element array
                list_xml(   $doc_e  ,   {   name    =>  $xmlfile
                                        ,   leading =>  1
                                        ,   trailing=>  2
                                        ,   logging =>  'ON'
                                        ,   number  =>  'ON'    }   );
                
                list_xml(   $xml_e  ,   {   name    =>  $xmlfile
                                        ,   leading =>  1
                                        ,   trailing=>  2
                                        #,   ne_log =>  $$attributes{ne_log}
                                        #,   ns_log =>  $$attributes{ns_log}
                                        ,   logging =>  'ON'
                                        ,   number  =>  'ON'    }   );
                
                my $xml_m = merge_xml   (   $xml_e, $doc_e, $where  );
                my $xml_p = join_xml    (   $xml_m );

                list_xml(   $xml_m  ,   {   name    =>  $xmlfile
                                        ,   leading =>  1
                                        ,   trailing=>  2
                                        ,   logging =>  'ON'
                                        ,   number  =>  'ON'    }   );
                write_utf8  ( $xml_p, $xmlfile ); 
            }
        }# find the right part
        return $merge;
}#sub   update_docx

sub     insert_heading  {
        my  (   $what
            ,   $where  )   =   @_;
        my  $xmle   =   [];
        push( @{$xmle}, sprintf "<w:p>" ); 
        push( @{$xmle}, sprintf "<w:pPr>" ); 
        push( @{$xmle}, sprintf "<w:pStyle w:val=\"%s\"\/>",$$what{style} ); 
        push( @{$xmle}, sprintf "</w:pPr>" ); 
        push( @{$xmle}, sprintf "<w:r>" ); 
        push( @{$xmle}, sprintf "<w:t>%s</w:t>",$$what{text} ); 
        push( @{$xmle}, sprintf "</w:r>" ); 
        push( @{$xmle}, sprintf "</w:p>" ); 
        #insert what
        #insert where
        #insert how     read, modify, write file
        return $xmle;
}#sub   insert_heading

sub     insert_paragraph {
        my  (   $what   )   =   @_;
        my  $xmle   =   [];
        push( @{$xmle}, sprintf "<w:p>" );
        push( @{$xmle}, sprintf "<w:r>" ); 
        push( @{$xmle}, sprintf "<w:t xml:space=\"preserve\">%s</w:t>",$$what{text} ); 
        push( @{$xmle}, sprintf "<w:t>" ); 
        push( @{$xmle}, sprintf "</w:r>" ); 
        push( @{$xmle}, sprintf "</w:p>" ); 
        return $xmle;
}#sub   insert_paragraph

sub     insert_paragraph_highlight  {
}#sub   i_paragraph_


sub     initialize    {
        my    $self   =   shift;
        my    $f      =   $self->{_filename};
        my    $i      =   ${$self->{_opts}}{indent};
        my    $p      =   ${$self->{_opts}}{indent_pattern};
        my    $n      =   subroutine('name');
        #my    %c      =   {   _fname  =>  $f,
        #                      _xmls   =>  [],
        #                      _xmle   =>  [],
        #                      _data   =>  []      };             # content container
        system `rm -rf 'XLSX'`  if ( -e 'XLSX' );                 # remove old temporary document
        system `mkdir XLSX` unless ( -e 'XLSX' );                 # create temporary directory          
        printf "%*s%s () called\n",$i,$p,$n if( debug($n) );
        system "unzip -q $f -d XLSX";                             # unpack document into temporary directory
        @{$self->{_content}} = `find ./XLSX -type f`;             # get list of files
        my $s  = length($#{$self->{_content}});                   # format counter 
        while (my ($c, $fn) = each @{$self->{_content}}) {
          chomp $fn;  
          printf "%*s(%*s) %s\n",$i,$p,$s,$c+1,$fn if( debug($n) );
          unless($fn =~ m/.bin$/xms)  {                           # (?|.xml|.rels)$
              my @xmls = read_xml ( $fn );                        # read xml string from xml file
              @xmls = preserve_space ( @xmls );                   # preserve and compact xml string
              ${$self->{_opts}}{cnt} = $c+1;                      # support container     # logging support #number
              report_container( $self, $fn );                                             # logging support # filename
              my @xmle                                            # Array of XML elements
              = breakup_xml_string( $self, \@xmls );              # XML string w/ XML elements
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
}#sub   initialize


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
      my $p = ${$self->{_opts}}{indent_pattern};                                        # ${$opts_ref}{padding_pattern}
      my $n = 1;
      for my $xmle ( @{$xmle_ref} ) {
          chomp ($xmle);
          #printf "%*s(%s)++\n",$i,$p,$xmle;                                            # Silenced

          #push ( @{${$opts_ref}{$tmp}}, "\n" );
          push ( @{${$self->{_opts}}{$tmp}},sprintf "%*s(%s)",$i,$p,$xmle);
          push ( @{${$self->{_opts}}{tmp2}},sprintf "%*s(%s)",$i,$p,$xmle);             # Track XML elements
          push ( @{${$self->{_opts}}{tmp4}},sprintf "%*s(%s)",$i,$p,$xmle);             # Parse XML elements, identification
          $n++;
          if ( $xmle =~   m{^\s*(<(?|/|\?)?)                                            # XML Start TAG begin
                            #   ([_a-zA-Z:]+)                                           # Forgot numbers and colon
                            #   ([a-zA-Z][_a-zA-Z:0-9]+)                                # XML tag name, single character tags
                                ([a-zA-Z][_a-zA-Z:0-9]*)                                # XML tag name
                            #   $TAGN
                              (\s(\w+=".+")?)?                                          # XML attribute, multiple attributes
                                ((?|/|\?|)? >)                                          # XML Start TAG end
                                ([^<]+)?                                                # XML elememt
                                (</\1>)?                                                # XML End TAG
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
      return;
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
#           EXP::Docx   End of module
1;
