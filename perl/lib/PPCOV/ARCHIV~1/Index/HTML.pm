package PPCOV::Archive::Index::HTML;
# File          PPCOV/Archive/Index/HTML.pm
#
# Refactored    01/28/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::Archive::Index::HTML::read_html() reading html files 
#                                        
#               

use strict;
use warnings;

use parent "HTML::Parser";

use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;
#   

use lib				        qw  ( /mnt/ussjf-home/lfilor/ws/perl/lib );     # Add Include path to @INC
use Dbg                     qw  ( debug subroutine      );
use File::IO::UTF8::UTF8    qw  ( read_utf8 write_utf8  );

#use lib             qw  ( ../lib );                                        # Relative UserModulePath
#use UTF8            qw  ( read_utf8 write_utf8  );                         # 05/08/2019
#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.07");

use Exporter qw (import);                           # Import <import> function
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended to use

our @EXPORT_OK  =   qw  (	read_html
							process_instances
                            get_references
                            get_attribute
                            get_accesspath

                        );#explicite export         # RECOMMENDED

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ]
                        );

#----------------------------------------------------------------------------
# C O N S T A N T S

#----------------------------------------------------------------------------
# V A R I A B L E S

my $source  =   [];

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
        if ( defined ${$opts_ref}{setup}{final}{report} )   {						# coverage report
            my $coverage = ${$opts_ref}{setup}{final}{report};                      # full filename of coverage report
			exist_file( $coverage );
            my $p = new PPCOV::Archive::Index::HTML;
            $p->parse_file($coverage);
        } else {
            printf "%*s%s %s\n",$i,$p,'Coverage report file','Not defined';
        }#
        return  $source;                                                            # reference to array of html text
}#sub   read_html


sub     process_instances   {
        my  (   $blk_r
            ,   $inst_r     )   = @_;               # instance reference
        my $inst = [];                              # reference to instances
        my $n =  subroutine('name');                # identify sub by name
        if( debug($n))  {
            printf  "\n%5s%s()\n",'',$n;
            printf  "%10s%s %s\n",'','Size of Block', $#{$blk_r}+1;
            printf  "%10s%s %s\n",'','Size of Block', $#{$inst_r}+1;
        }#if debug
        if ( $#{$blk_r} == $#{$inst_r}  )   {
            my $range  = $#{$blk_r};
            my $col1   = maxwidth ( $blk_r  );
            my $col2   = maxwidth ( $inst_r );
			printf "%10s%*s | %*s\n",''
                   ,$col1,${$blk_r}	[0]				# header
                   ,$col2,${$inst_r}[0] 			# header
				   if(debug($n));
            for my $i ( 1 .. $range ) {				# Skip the header
                printf	"%10s%*s | %*s\n",''
						,$col1,${$blk_r}[$i]
                        ,$col2,${$inst_r}[$i]
						if(debug($n));
                my @tmp = split / /, ${$inst_r}[$i];
                foreach my $e  ( @tmp ) {
                    push ( @{$inst}, $e ) if ($e !~ m/[+-]/ );
                }#
            }# for all blocks of interest
        } else {
            my $msg = 
			sprintf ("\n%*s%s\n",5,'',"WARNING Coverage Specification incomplete");
            print BLINK BOLD RED $msg, RESET;
            printf "\nWarning :: Block and Instance data are not complete !!\n";
        }
        my $u_inst = unique ( $inst );
        printf "\n" if(debug($n));
        return $u_inst;
}#sub   process_instances


sub     get_references  {
        my  (   $inst_r
            ,   $html_r     )   = @_;
        my  $n =  subroutine('name');                   # identify sub by name
        my  $uri  = {};
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%10s%s %s\n",'','Size of index.html  ',$#{$html_r}+1;
            printf  "%10s%s %s\n",'','Number of instances ',$#{$inst_r}+1;
        }#
        my %found;
        my $ix  =   0;
        foreach my $line    ( @{$html_r} ) {            # O(n) n is large 10K+
            if ( (match($line, $inst_r)) ) {            # O(n) n is very small < 10 
                #push ( @{$href},${$html_r}[$ix-1] );    # look behind for href
                my $inst = get_instance($line, $inst_r);
                $found{$inst} = 1;
                ${$uri}{$inst}{href} = ${$html_r}[$ix-1];
            };
            $ix++;
        }# foreach
        foreach my $inst ( @{$inst_r}) {
            if ( $found{$inst} ) {
            } else {
                printf  "\n%5s%s() \n",'',$n;
                my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING $inst instance not found");
                #printf "\n%*s%s\n",5,'',colored ("WARNING $inst instance not found", RED);
                print BLINK BOLD RED $msg, RESET;
            }# Give WARNING
        }# Check completness
        printf "\n";
        return $uri;
}#sub   get_references


sub     get_attribute   {
        my  (   $href   )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        if( debug($n)) {
            printf "\n%5s%s() \n",'',$n;
            printf "%5s%s %s\n",''
                    ,'Type of input parameter '
                    ,ref $href;
        }# debug
        if  (( ref $href ) =~ m/HASH/ ) {
            foreach my $instance ( keys %{$href} ) {
                if( debug($n)) {
                    printf  "%10s%s = %s",''
                            , $instance
                            , ${$href}{$instance}{href};
                }# debug
                if ( ${$href}{$instance}{href} =~ /.*"(.*)">/ ) {
                    printf " %s\n", $1 if( debug($n));
                    ${$href}{$instance}{attribute} = $1;
                } else {
                    printf "\n" if( debug($n));
                }#if match
            }#for all
            return $href;
        } else {
            my $msg = sprintf ("%*s%s\n\n",5,'',"WARNING $n() NO Hash reference");
            print BLINK BOLD RED $msg, RESET;
        }# Warning
}#sub   get_attribute


sub     get_accesspath  {
        my  (   $att_r								# attribute reference
            ,   $apath   )   = @_;					# absolutepath to URI
        my $n =  subroutine('name');                # identify sub by name
        printf  "\n%5s%s() \n",'',$n if( debug($n));
        if ( (ref $att_r) =~ m/HASH/ )  {
            foreach my $instance ( keys %{$att_r} ) {       # instance & attribute are correlate
                my  $attr = ${$att_r}{$instance}{attribute};
                if ( $attr =~ m/^(.*)[.]htm[?]f=(\d+)&s=(\d+)/ ) {
                    my ($path, $rec) = ( $1.$2.'.json', $3 );
                    my $fpath = "$apath/$path";
                    ${$att_r}{$instance}{zfile} = $fpath;
                    ${$att_r}{$instance}{znum}  = $rec;
                    if( debug($n)) {
						printf "%9s%s %s",'',$1,$2;
                    	printf "\t%s\trecord %s",  $path, $rec;
                    	printf "\tfile exists\n",         if(  -e $fpath);
                    	printf "\tfile doesn't exists\n", if(! -e $fpath);
                    }# debug
                }# extract attribute data
            }#for all attributes
            return $att_r;
        } else {
            my $msg = sprintf ("%*s%s\n\n",5,'',"WARNING $n() NO Hash reference");
            print BLINK BOLD RED $msg, RESET;
        }# Warning
}#sub   get_accesspath

#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

sub     unique  {
        my  (   $array_r    )   =   @_;
        my  %seen;
        my  $unique = [];
        foreach my $entry   ( @{$array_r} ) {
            push ( @{$unique}, $entry ) if ( !$seen{$entry}++ );
        }
        return $unique;
}#sub   unique


sub     match    {                                  # $string match @array
        my  (   $line
            ,   $inst_r )   = @_;
        my $found = 0;
        foreach my $instance    ( @{$inst_r} ) {
            next        if $line !~ m/$instance/ ; 
            $found++    if $line =~ m/$instance/ ;
        }# 
        return $found;
}#sub   match


sub		exist_file {
		my	(	$file	)	=	@_;

		if (! -e $file	) {
            my $msg = sprintf ("\n%5s%s\n\n",'',"WARNING $file NOT found !!");
            print BLINK BOLD RED $msg, RESET;
			exit;																	# Terminate execution
		}# File not found
		else {
            my $msg = sprintf "%5s%s %s\n",'','Coverage report file',$file;
            print BLINK BOLD BLUE $msg, RESET;
		}
}#sub   exist_file


sub     get_instance   {
        my  (   $line
            ,   $inst_r )   = @_;
        my $found = 0;
        my $return_inst = 'NOT FOUND';
        foreach my $instance    ( @{$inst_r} ) {
            next        if $line !~ m/$instance/ ;
            $found++    if $line =~ m/$instance/ ;
            $return_inst = $instance;
        }# 
        return $return_inst;
}#sub   get_instance


sub     maxwidth    {
        my  (   $array_r    )   =   @_;
        my  $max    =   0;
        foreach my $entry  ( @{$array_r} ) {
            my $tmp =   length($entry);
            $max = ( $max > $tmp ) ? $max : $tmp;
        }#for all
        return $max;
}#sub   maxwidth

#----------------------------------------------------------------------------
# End of module
1;
