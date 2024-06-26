package PPCOV::HTML;
# File          PPCOV/HTML.pm
#
# Refactored    01/28/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::HTML::read_html() reading html files 
#                                        
#               

use strict;
use warnings;

use parent "HTML::Parser";

use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;
#   

use lib             qw  ( ../lib );                 # Relative UserModulePath
use Dbg             qw  ( debug subroutine      );
use UTF8            qw  ( read_utf8 write_utf8  );
#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.02");

use Exporter qw (import);                           # Import <import> function
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended to use

our @EXPORT_OK  =   qw  (	read_html
                        );#explicite export         # RECOMMENDED

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ]
                        );

#----------------------------------------------------------------------------
# C O N S T A N T S

#----------------------------------------------------------------------------
# V A R I A B L E S

my $source  =   [];									# index.html content

#----------------------------------------------------------------------------
# S U B R O U T I N S


sub     text    {
        my ($self, $text)   = @_;
        #print   $text;
        push    ( @{$source}, $text );
}#sub   text

sub     comment {
        my ($self, $comment)= @_;
        #print   $comment;
        push    ( @{$source}, $comment );
}#sub   comment

sub     start   {
        my ($self, $tag, $attr, $attrseq, $origtext)    = @_;
        #print   $origtext;
        push    ( @{$source}, $origtext );
}#sub   start

sub     end     {
        my ($self, $tag, $origtext) = @_;
        #print   $origtext;
        push    ( @{$source}, $origtext );
}#sub   end


sub     read_html   {
        my  (   $opts_ref   )   =   @_;
        my $i = ${$opts_ref}{indent};                                               # indentation
        my $p = ${$opts_ref}{indent_pattern};                                       # indentation pattern
        my $n = subroutine('name');                                                 # name of subroutine
        printf "\n%*s%s()\n", $i,$p,$n;
        #if ( defined ${$opts_ref}{coverage} )   {
        if ( defined ${$opts_ref}{final}{report} )   {
            my $coverage = ${$opts_ref}{final}{report};                             # full filename of coverage report
            printf "%*s%s %s\n",$i,$p,'Coverage report file',$coverage;
			exist_file( $coverage );
            my $p = new PPCOV::HTML;
            $p->parse_file($coverage);
        } else {
            printf "%*s%s %s\n",$i,$p,'Coverage report file','Not defined';
        }#
        return  $source;                                                            # reference to array of html text
}#sub   read_html


#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

sub		exist_file {
		my	(	$file	)	=	@_;

		if (! -e $file	) {
            my $msg = sprintf ("\n%5s%s\n\n",'',"WARNING $file NOT found !!");
            print BLINK BOLD RED $msg, RESET;
			exit;																	# Terminate execution
		}# File not found
}#sub   exist_file

#----------------------------------------------------------------------------
# End of module
1;
