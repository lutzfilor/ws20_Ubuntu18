package PPCOV::Excel::XLSX;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/PPCOV/XLSX.pm
#
# Created       02/27/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::Excel::XLSX::write_workbook()
#                       input   [ @of_worksheets ] 
#								, $filename
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;


use Data::Dumper	            qw	/	Dumper		/;
use PPCOV::DataStructure::DS    qw  /   list_ref    /;                              # Data structure

use Spreadsheet::ParseXLSX;							                                # Spreadsheet::ReadExcel
use Excel::Writer::XLSX;                                                            # Spreadsheet::WriteExcel

use Excel::CloneXLSX::Format    qw	(	translate_xlsx_format );
use Safe::Isa;

use File::Basename;
use POSIX                       qw  (   strftime    );			                    # Format string

use lib							qw  (    /mnt/ussjf-home/lfilor/ws/perl/lib );      # Add Include path to @INC
use Dbg                         qw  (   debug 
							            subroutine  );
use File::IO::UTF8::UTF8        qw  (   read_utf8   );
use Logging::Record             qw  (   log_msg
                                        log_lmsg    );

#use lib             qw  (   ../lib );                                              # Relative UserModulePath
#use UTF8            qw  (   read_utf8   );                                         # 05/08/2019
#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.04");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   deepcopy_workbook
							worksheet_clone
							extract_hash
							extract_array
							add_worksheet
							insert_worksheet
							write_workbook
							revise_workbook
						);#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S


sub     deepcopy_workbook  {
        my  (   $book_r     )   =   @_;
        my  $n  =  subroutine('name');                                              # identify the subroutine by name
        #printf STDERR "%5s%s()\n",'',$n;
        printf  "\n%5s%s()\n",'',$n;
        my  $clone      =   [];                                                     # reference to workbook copy
        for my $sheet ( $book_r->worksheets()  ) {                                  # aggregate workbook, sheet by sheet
			push (@{$clone},worksheet_clone($sheet));
        }#for all sheets
        printf  "%5s%s() ... done \n",'',$n;
        return $clone;                                                              # clone[ sheets [ rows[ cells [] ]]]
}#sub   deepcopy_workbook 


sub     write_workbook  {
        my  (   $book_r								# [ @worksheets ]
			,	$filename							# target output file.xlsx
            ,   $opts_ref   )   =   @_;
        my  $i = ${$opts_ref}{indent};              # left side indentation
        my  $p = ${$opts_ref}{indent_pattern};      # indentation_pattern
        my	$n =  subroutine('name');				# identify sub by name
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
			printf  "%10s%s %s\n",'','Output Name'  ,$filename;
        }#if debug

        my  $workbook   
		= Excel::Writer::XLSX->new( $filename );    # Step 1
        $workbook->set_properties(
               title    => 'IoT - Testcoverage Report',
			   subject	=> 'Coverage Progress',
               author   => 'Lutz Filor',
               manager  => 'Ravi Kalyanaraman',
               company  => 'Synaptics',
               comments => 'Created w/ Perl lib Excel::Writer::XLSX',
			   keywords => 'CPIT, report, progress, IoT, DV',
        );
		#owner	=> 'RamyaReddy Nerabetla',
        if ( ref($book_r) =~ m/ARRAY/ ) {
            foreach my $t ( @{$book_r} ) {
                printf STDERR "%*s %s %s\n",$i,$p,'tab name', $t->[0];
                my $worksheet 
				= $workbook->add_worksheet($t->[0]);	# Step-2
                $worksheet->write_col(0,0,$t->[1]);		# Step-3
            }# for each table worksheet
        }#if NO GUARD - TYPE is ARRAY
		#workbook->close();
}#sub   write_workbook


sub		revise_workbook	{
		my	(	$filename
			,	$worksheets							# [list of worksheets]
			,	$opts	)	=	@_;					# { CL-options }
        my  $i = ${$opts}{indent};					# left side indentation
        my  $p = ${$opts}{indent_pattern};			# indentation_pattern
        my	$n 	=  subroutine('name');				# identify sub by name
		my	$revised_file
		= filename_generator($filename, $opts);		# local storage FIXME [FI] 
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
			printf	"%10s%s %s\n",$p,'Number of WS' ,$#{$worksheets}+1;
			printf  "%10s%s %s\n",'','Source Name ' ,$filename;
			printf  "%10s%s %s\n",'','Target Name ' ,$revised_file;
        }#if debug
		#   import previous/original workbook
		my  $cloned   = [];
		my  $parser   = Spreadsheet::ParseXLSX->new();				# Step 1
    	my  $workbook = $parser->parse( $filename );				# Step 2
    	#my $workbook = $parser->parse( $opts{workbook} );     		

		my $msg = sprintf ("\n%*s%s\n",$i*2,$p,"$n(cloning)");
		print BLINK BOLD BLUE $msg, RESET;
		#exit;
		
		#   deepclone	previous	workbook
		my  $clone 	= Excel::Writer::XLSX->new( $revised_file );	# Step 3
		#copy	previous	workbook
        for my $sheet ( $workbook->worksheets()  ) {
			if( debug($n))  {
				printf  "%10s%s %s\n",'','Worksheet  ',$sheet->get_name();
			}# if debug
			my $ws = $clone->add_worksheet($sheet->get_name());		# Step 4
			deepclone	( $sheet, $ws );							# Step 5
		}
		#my $msg = sprintf ("%*s%s\n\n",$i,$p
		#,"WARNING hard stop in $n(appending)");
		#print BLINK BOLD BLUE $msg, RESET;
		#exit;

		# update add latest	coverage report - insert new worksheet
        #if ( ref($book_r) =~ m/ARRAY/ ) {
        if ( ref($worksheets) =~ m/ARRAY/ ) {
			my $msg = sprintf ("\n%*s%s\n",$i*2,$p,"$n(appending)");
			print BLINK BOLD BLUE $msg, RESET;
            foreach my $t ( @{$worksheets} ) {
				unless ($t->[0] ~~ @{$cloned}) {
					printf STDERR "%*s%s %s\n",$i*2,$p,'worksheet  ',$t->[0];
					my $ws = $clone->add_worksheet($t->[0]);			# Step-6
					#$worksheet->write_col(0,0,$t->[1]);				# Step-7
				}
            }# for each table worksheet
        } else { #if NO GUARD - TYPE is ARRAY
			my $msg = sprintf ("%*s%s\n\n",$i,$p
			,"ERROR in $n(appending) parameter not [array] reference");
			print BLINK BOLD RED $msg, RESET;
			exit;
		}
}#sub	revise_workbook


sub		extract_hash	{
		my	(	$book_r							# workbook	reference     
            ,   $sheet_name 					# worksheet name
			,	$key							# column	number 0,1,2 ... whatever
			,	$val							# column	number  ,1,2 ... whatever should be $key+1
            ,   $opts_ref   	)   =   @_;		# option	reference
        my  $i  = 5;
        my  $p  = '';
        my  $n  =  subroutine('name');                                              # identify the subroutine by name
        my  $column_c   =   [];                                                     # reference of target column data
		my	$hash_clone =	{};
        my  ($f1,$f2)   =   (0,0);													# found data, report failure
		printf "\n";
        printf "%*s%s()\n", $i,$p,$n if(debug($n));
        if ( ref($book_r) =~ m/ARRAY/ ) {
            foreach my $t ( @{$book_r} ) {                                          # tab, worksheet reference
                my  $name   =   $t->[0];                                            # tab name
                my  $data_r =   $t->[1];                                            # tab data reference
                my  @data   =   @{$data_r};                                         # array of references -> column
                my  $n_row  =   $#data;                                             # number of rows		 span vertical 
                my  $n_col  =   $#{$data[0]};                                       # number of columns		 span horizontal
				my  $k		=	maxwidth([ map{$_->[$key]} @data ]);				# max width of keys
				my	$v		=	maxwidth([ map{$_->[$val]} @data ]);				# max width of any value
                printf "%*s%s: %s",$i,$p,'Sheet',$name if(debug($n));
                if ( $name  =~  m/$sheet_name/ ) {
					printf " found \n" if (debug($n));
					for my $row ( 0 .. $n_row) {
						if(debug($n)) {
							printf "%*s%*s = > %*s\n",$i*2,$p
							,$k,$data[$row][$key]
							,$v,$data[$row][$val];
						}# if debug
						${$hash_clone}{$data[$row][$key]} = $data[$row][$val];
					}# for all entries
				} else {
					printf "\n" if (debug($n));
				}#
			}# for all worksheet tabs
		} else {
		}# if reference is an array reference
		return $hash_clone; 
}#sub	extract_hash


# Data model    [workbook]->@[sheet]->@name,[data]->@[row]->@cell

sub     extract_array  {
        my  (   $book_r																# workbook
            ,   $sheet_name															# worksheet															
            ,   $col_header )   =   @_;												# column
        my  $i  = 5;
        my  $p  = '';
        my  ($f1,$f2)	=	(0,0);													# found data, report failure
        my  $n  =  subroutine('name');                                              # identify the subroutine by name
        my  $column_c   =   [];                                                     # reference of target column data
		if(debug($n)) {
			printf "\n%*s%s()\n", $i,$p,$n;
			printf "%*s%s %s\n", $i,$p,'Target',$col_header;
		}# if debug
        if ( ref($book_r) =~ m/ARRAY/ ) {
            foreach my $t ( @{$book_r} ) {                                          # tab, worksheet reference
                my  $name   =   $t->[0];                                            # tab name
                my  $data_r =   $t->[1];                                            # tab data reference
                my  @data   =   @{$data_r};                                         # array of references -> column
                my  $n_row  =   $#data;                                             # number of rows   
                my  $n_col  =   $#{$data[0]};                                       # number of columns
                printf "%*s%s: %s",$i,$p,'Sheet',$name if(debug($n));
                if ( $name  =~  m/$sheet_name/ ) {
                    $f1 = 1;														# worksheet found
                    printf " %s\n",'found' if(debug($n));
                    for my $col ( 0 .. $n_col ) {
                        my $f = "%*s%s";
                        printf $f,$i*2,$p,$data[0][$col] if(debug($n));
                        if ( $data[0][$col] =~ m/$col_header/ )  {					# search_field over search_pattern
                            $f2 = 1;												# column found		
                            printf " %s\n",'found' if(debug($n));
                            for my $row ( 0 .. $n_row ) {							# everything incl header
                                my $f = "%*s%2s %s\n";
                                printf $f,$i*3,$p,$row,$data[$row][$col] if(debug($n));
                                push (@{$column_c}, $data[$row][$col]);				# extract data
                            }# for each row
                        } else {# column found
							printf "\n" if(debug($n));
						}#
                    }#foreach
                } else { #found worksheet
					printf "\n" if(debug($n));
				}# skipp worksheet
            }#foreach            
        }# GUARD - reference TYPE is ARRAY
        my $f = "%*s%s %s %s\n";
        unless ( $f1 )  {
            printf STDERR $f,$i,$p,'Worksheet',$sheet_name,'NOT found';
        }
        unless ( $f2 )  {
            printf STDERR $f,$i,$p,'Column_header',$col_header,'NOT found';
        }
        return $column_c;															# return data
}#sub   extract_array


#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S


sub     maxwidth    {
        my  (   $array_r    )   =   @_;
        my  $max    =   0;
        foreach my $entry  ( @{$array_r} ) {
            my $tmp =   length($entry);
            $max = ( $max > $tmp ) ? $max : $tmp;
        }#for all
        return $max;
}#sub   maxwidth


sub		worksheet_clone	{
		my	(	$sheet	)	= @_;							# original worksheet
        my $data    =   [];
        my $clone   =   [];                                 # worksheet clone           
        my ( $row_min, $row_max ) = $sheet->row_range();    # region span in y / rows
        my ( $col_min, $col_max ) = $sheet->col_range();    # region span in x / columns
        for my $row ( $row_min .. $row_max ) {
            my $row_c   =   [];                             # row copy reference
            for my $col ( $col_min .. $col_max ) {
                my $cell    = $sheet->get_cell($row,$col);	# copy
                my $cell_v  = ($cell)?$cell->value():'';    # fully determined
                push ( @{$row_c}, $cell_v);                 # paste
            }# each column -> x
            push ( @{$data}, $row_c );                      # aggregate sheet row by row
        }# each row -> y
        push (@{$clone} , $sheet->get_name());              # copy tab name
        push (@{$clone} , $data   );                        # copy 2D region of values
		return $clone;
}#sub	worksheet_clone


sub		deepclone	{
		my	(	$org										# original worksheet
			,	$clone       )	=	@_;						# cloned worksheet
        my  $i  = 5;
        my  $p  = '';
        my	$n 	=  subroutine('name');						# identify sub by name
		if(debug($n)) {
			printf "\n%*s%s()\n", $i,$p,$n;
			#printf "%*s%s %s\n", $i,$p,'Target',$col_header;
		}# if debug
        my	($row_min,$row_max) = $org->row_range();		# region span in y / rows
        my	($col_min,$col_max) = $org->col_range();   		# region span in x / columns
		for my $row ($row_min .. $row_max) {
			printf  "%22s%s %s\n",'','row',$row	if( debug($n)); 
		    for my $col ($col_min .. $col_max) {
				printf  "%26s%s %s\n",'','col',$col	if( debug($n)); 
				my $cell = $org->get_cell($row,$col);		# CELL
                print Dumper ( $cell );
				list_ref( $cell , { name => 'CELL', } );
				my $msg = sprintf ("%*s%s\n\n",$i*2,$p
				,"WARNING hard stop in $n(copycell)");
				print BLINK BOLD RED $msg, RESET;
				exit;


				#my $form = $cell->get_format();			# FORMAT
				my $wert = $cell->unformatted();			# VALUE
				$clone->write($row,$col,$wert);
			}# for all columns
		}# for all rows
		if( debug($n))  {
			printf  "%22s%s %s\n",'',' ... done  ',$clone->get_name();
		}# if debuging
}#sub	deepclone


#sub     display_deepcopy {
sub     render_worksheet {
        my    (   $book_r
              ,   $opts_ref   )   =   @_;
                  #$opts_ref   //= \%opts;
        my $i = ${$opts_ref}{indent};                                                 # left side indentation
        my $p = ${$opts_ref}{indent_pattern};                                         # indentation_pattern
        my $n =  subroutine('name');                                                  # identify the subroutine by name
        printf STDERR "%*s%s()\n\n", $i,$p,$n;
        if ( ref($book_r) =~ m/ARRAY/ ) {
           printf STDERR "%*s %s %s %s\n",$i,$p,$n,'parameter is',ref $book_r;
           foreach my $t ( @{$book_r} ) {
              printf STDERR "\n";
              printf STDERR "%*s %s %s\n",$i,$p,'tab name', $t->[0];
              my  $b_ref = $t->[1];                                                   # reference to blatt
              my  $w_ref = $t->[2];                                                   # reference to format, 
              my  @colum = @{$b_ref};
              my  $n_row = scalar @{$colum[0]};                                       # number of columns
              my  $n_col = $#{$w_ref};
              printf STDERR "%*s %s %s\n",$i,$p,'number of col', $n_col;
              printf STDERR "%*s %s %s\n",$i,$p,'number of row', $n_row;
              for my $row   ( 0 .. $n_row-1 ) {
                  printf  STDERR "%*s|",$i,$p;
                  for my $index ( 0 .. $n_col-1 ) {
                    printf STDERR "%*s ",${$w_ref}[$index],$colum[$index][$row];
                  }#for
                  printf STDERR "|\n";
              }#for
           }# tabs
        }#if GUARD - reference TYPE is ARRAY
#}#sub   display_deepcopy
}#sub   render_worksheet




#=============================================================================================================================================================
# $format->{Font}         $format->{AlignH}                $format->{AlignV}                 $format->{Rotate}                 $format->{Font}{UnderlineStyle}
# $format->{AlignH}       0 => No alignment                0 => Top                          0 => No rotation                   0 => None
# $format->{AlignV}       1 => Left                        1 => Center                       1 => Top down                      1 => Single
# $format->{Indent}       2 => Center                      2 => Bottom                       2 => 90 degrees anti-clockwise,    2 => Double
# $format->{Wrap}         3 => Right                       3 => Justify                      3 => 90 clockwise                 33 => Single accounting
# $format->{Shrink}       4 => Fill                        4 => Distributed/Equal spaced                                       34 => Double accounting
# $format->{Rotate}       5 => Justify
# $format->{JustLast}     6 => Center across                                                                                   $format->{Font}{Super}
# $format->{ReadDir}      7 => Distributed/Equal spaced                                                                         0 => None          
#
# $format->{BdrStyle}	  [ $left, $right, $top, $bottom ]                                                                      1 => Superscript
# $format->{BdrColor}	  [ $left, $right, $top, $bottom ]									                                    2 => Subscript   
# $format->{BdrDiag}	  [ $kind, $style, $color ]																	
# $format->{Fill}		  [ $pattern, $front_color, $back_color ]
# 
# $format->{Lock}
# $format->{Hidden}
# $format->{Style}





sub		translate_format	{
		my	(	$if		)	= @_;						# input format Spreadsheet::ParseXLSX  
		my	$format	= {};								# format
		my  @sides = qw (left right top bottom);		# sides of cell
		if ( defined $if ) {               				# Translate
			${$format}{font}			= ${$if}{Font}{Name};			# Arial
			${$format}{size}			= ${$if}{Font}{Height};
			${$format}{bold}			= ${$if}{Font}{Bold};
			${$format}{color}			= ${$if}{Font}{Color};
			${$format}{italic}			= ${$if}{Font}{Italic};
#										  ${$if}{Font}{Underline}:
			${$format}{underline}		= ${$if}{Font}{UnderlineStyle};
			${$format}{font_strikeout}	= ${$if}{Font}{Strikeout};
			${$format}{font_script}		= ${$if}{Font}{Super};

			# shading
			${$format}{pattern}			= ${$if}{Fill}[0] if (defined ${$if}{Fill}[0]);
			${$format}{fg_color}		= ${$if}{Fill}[1] if (defined ${$if}{Fill}[1]);
			${$format}{bg_color}	    = ${$if}{Fill}[2] if (defined ${$if}{Fill}[2]);

			# swap fg and bg
			if ( ${$format}{pattern} == 1 ) {
				@{$format}{qw(fg_color bg_color)} = @{$format}{qw(bg_color fg_color)};
			}# if pattern is solid
			
			# alignment
			${$format}{text_h_align}	= ${$if}{AlignH};
			${$format}{text_v_align}	= (defined ${$if}{AlignV})? ${$if}{AlignV}+1 : 0;

			# borders
			foreach my $ix	( 0 .. $#sides) {
				my $side = $sides[$ix];
				my $colr = $side.'_color';
				${$format}{$side} = ${$if}{BrdStyle}[$ix] if (${$if}{BrdStyle}[$ix]);
				${$format}{$colr} = ${$if}{BdrColor}[$ix] if (${$if}{BdrColor}[$ix]);
			}# for all sides
		}#												# Excel::Writer::XLSX
		return	$format;
}#sub	translate_for

        ### my  $fullname           
        ### =   ${$opts_ref}{workbook};                 # absolute path/filename

sub     filename_generator  {
        my  (	$fullname   
			,	$opts_ref   )   =   @_;
        my  $i	= ${$opts_ref}{indent};             # indentation
        my  $p 	= ${$opts_ref}{indent_pattern};     # indentation pattern
        my	$n 	=  subroutine('name');				# identify sub by name
        my  ( $na,$pa,$su )   
        =   fileparse( $fullname, qr{[.][^.]*} );
        my  $u = strftime '_%Y-%m-%d', localtime;   # unique datestamp
        my  $d = $na.$u.'_revised'.$su;             # derived filename
        #my  $d = $na.$u.$su;                        # derived filename
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
			printf  "%10s%s %s\n",'','Source Name'  ,$fullname;
        	printf  "%10s%s %s\n",'','Date       '  ,$u;
        	printf  "%10s%s %s\n",'','Output Name'  ,$d;
        }#if debug
        ${$opts_ref}{output}    =   $d;
        return $d;
}#sub   filename_generator


sub     sheetname_generator {
        my  (   $opts_ref   )   =   @_;
        my  $i = ${$opts_ref}{indent};              # indentation
        my  $p = ${$opts_ref}{indent_pattern};      # indentation pattern
        my  $u = strftime '%Y-%m-%d', localtime;    # unique
        ${$opts_ref}{sheetname} =   $u;
        return $u;                                  # sheet name
}#sub   sheetname_generator


sub		_warn		{
		my	(	$n									# caller name
			,	$t	)	=	@_;						# type	 BOOK/SHEET
		my $f	= "\n%*s%s %s() %s %s\n";			# format
		my @l	= ( 5,'','WARNING',$n,$t,			# parameter list
					'not ARRAY reference' );
		my $message = sprintf ( $f, @l);
		return $message;
}#sub	warn


sub     insert_worksheet    {
        my  (   $book_r                             # [ workbook  ]
            ,   $data_r								# [ sheetdata ]
            ,   $opts_ref   )   =   @_;
        my $i = ${$opts_ref}{indent};               # left side indentation
        my $p = ${$opts_ref}{indent_pattern};       # indentation_pattern
		my $t = ${$opts_ref}{date};					# commandline overwrite
		$t	//=	sheetname_generator($opts_ref);		# title of worksheet
        my $n = subroutine('name');					# identify sub by name
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%*s%s %s\n",$i,$p,'Sheetname',$t;
        }#if debug
		my $worksheet	=	[];
        if ( ref($book_r) =~ m/ARRAY/ ) {
			if ( ref($data_r) =~ m/ARRAY/ ) {
				push ( @{$worksheet}, $t );			# Title
				push ( @{$worksheet}, $data_r);
				push ( @{$book_r}	, $worksheet );
			} else {
				my $msg = _warn ($n,'DATA');
            	print BLINK BOLD RED $msg, RESET;
			}# WARNING reference type Sheet
        } else {
			my $msg = _warn ($n,'BOOK');
            print BLINK BOLD RED $msg, RESET;
        }# WARNING reference type Book
		return $book_r;
}#sub   insert_worksheet


sub		new_workbook	{
		my	(	$filename			)	=	@_;
		return	Excel::Writer::XLSX->new ( $filename );
}#sub	new_workbook


sub		add_worksheet	{
		my	(	$workbook
			,	$worksheet_title	)	=	@_;
		return	$workbook->add_worksheet;
}#sub	add_worksheet


sub		close_workbook	{
		my	(	$workbook			)	=	@_;
		$workbook->close();
}#sub	close_workbook

#----------------------------------------------------------------------------
#  End of module PPCOV::EXCEL::XLSX
1
