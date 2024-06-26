package File::Header::Add;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/File/Header/Add.pm
#
# Created       04/01/2019          
# Author        Lutz Filor
# 
# Synopsys      File::Header::Add::add_header()
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


use Spreadsheet::ParseXLSX;
use Excel::Writer::XLSX;                            # Spreadsheet::WriteExcel

use File::Basename;
use POSIX                       qw  (   strftime    );			                # Format string


use Dbg                         qw  (   debug 
						            	subroutine  );
use Logging::Record             qw  (   log_msg
                                        log_lmsg    );
use PPCOV::DataStructure::DS    qw  (   list_ref    );                          # Data structure
use File::IO::UTF8::UTF8        qw  (   read_utf8   );

#use lib             qw  (   ../lib );                  # Relative UserModulePath
#use lib             qw  (   ~/ws/perl/lib );            # Relative UserModulePath
#use UTF8            qw  (   read_utf8   );              # 05/08/2019 refactor File::IO::UTF8::UTF8
#use Safe::Isa;
#use Excel::CloneXLSX::Format;
#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.02");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   add_header
						);#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S

sub     add_header      {

}#sub   add_header

sub     add_new_monitor     {
        my  (   $o_r    )   =   @_;                 # Option Reference
        my  $i = ${$o_r}{indent};                   # left side indentation
        my  $p = ${$o_r}{indent_pattern};           # indentation_pattern
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
        }# debug
        if ( file_exists( $o_r, 'spec', $n)) {
            my $specification = ${$o_r}{spec};
            if ( defined ${$o_r}{output} ) {
                my $f   = ${$o_r}{output};
                my $msg = sprintf ("\n%*s%s\n\n",$i,$p
                ,"Specified output = $f !!");
                print BLINK BOLD BLUE $msg, RESET;
            read_specification  (   $o_r
                                ,   $specification  );
            } else {
                my $msg = sprintf ("\n%*s%s\n\n",$i,$p
                ,"WARNING generate=Filename not specified !!");
                print BLINK BOLD RED $msg, RESET;
                exit;
            }#
        }
}#sub   add_new_monitor


sub     read_specification  {
        my  (   $o_r
            ,   $specification  )   =   @_;
        my  $i  = ${$o_r}{indent};                  # left side indentation
        my  $p  = ${$o_r}{indent_pattern};          # indentation_pattern
        my  $f  = ${$o_r}{output};                  # Output scource filename
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
        }
        my  $m          =   {};                     # Monitor specification
        my  $parser     =   Spreadsheet::ParseXLSX->new();
        my  $workbook   =   $parser->parse($specification);     # from      file .xlsx
        my  $bookcopy   =   deepcopy_workbook($workbook,$o_r);
        #list_ref   ( $o_r, { name => 'AppOptions',} );
        #list_ref   (   $bookcopy
        #           ,   {   name    =>  'Raw Monitor Spec'
        #               ,   reform  =>  'ON'                } );
        #                                   workbook, worksheet,columnhead
        ${$m}{protocol}  =  extract_array( $bookcopy,'Monitor','Standard'   );
        ${$m}{dbuswidth} =  extract_array( $bookcopy,'Monitor','dwidth'     );
        ${$m}{instance}  =  extract_array( $bookcopy,'Monitor','instance'   );
        ${$m}{device}    =  extract_array( $bookcopy,'Monitor','device'     );
        ${$m}{switch}    =  extract_array( $bookcopy,'Monitor','switch'     );
        ${$m}{interface} =  extract_array( $bookcopy,'Monitor','interface'  );
        ${$m}{clock}     =  extract_array( $bookcopy,'Monitor','clock'      );
        ${$m}{reset}     =  extract_array( $bookcopy,'Monitor','reset'      );
        ${$m}{directive} =  extract_array( $bookcopy,'Monitor','directive'  );
        ${$m}{hierachie} =  extract_array( $bookcopy,'Monitor','hierachie'  );
        ${$m}{rootname}  =  extract_array( $bookcopy,'Monitor','LogRoot'    );
        ${$m}{xaction}   =  extract_array( $bookcopy,'Monitor','TRANSNAME'	);
        ${$m}{ptracker}  =  extract_array( $bookcopy,'Monitor','PHASENAME'	);
        ${$m}{checker}   =  extract_array( $bookcopy,'Monitor','CHECKERNAME');
        
        ${$m}{contacts}  =  extract_array( $bookcopy,'Signal' ,'Monitor'  );
        foreach my $device ( @{${$m}{device}} ) {                               # Form the Stub connection
            unless ($device =~ m/device/ ) {
                ${$m}{$device} = extract_array ($bookcopy,'Signal',$device);
            }# unless column header
        }# for each device
        printf "\n";
        implement_specification( $m );
        test_character( $m );
}#sub   read_specification


sub     implement_specification {
        my  ( $monitor  )   =   @_;
        my $ix;
        add_header( $monitor );
        foreach my $inst ( @{${$monitor}{instance}} ) {
            unless ( $inst =~ m/instance/ ) {
                conditional_directive( $monitor, $ix );
            }# unless header
            $ix++;
        }# foreach
}#sub   implement_specification


sub     conditional_directive  {
        my  (   $monitor
            ,   $ix         )   =   @_;
        my $switch = ${$monitor}{switch}[$ix];
        printf  "%s %s\n",'`ifdef', $switch;
        define_monitor ( $monitor, $ix );
        signal_connecting   ( $monitor, $ix );
        Questa_directive    ( $monitor, $ix );
        printf  "%s // %s\n\n",'`endif', $switch;
}#sub   conditional_directive


sub     define_monitor {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        ${$monitor}{protocol} //= 'AXI';
        my $mon = (${$monitor}{protocol}[$ix] =~ m/AXI/ )? 'axi_if' : 'UNDEFIND';
        my $inst= ${$monitor}{instance} [$ix];
        my $hie = ${$monitor}{hierachie}[$ix];
        my $clk = $hie.'.'.${$monitor}{clock}[$ix];
        printf "%s %s (%s);\n",$mon,$inst,$clk;
}#sub   define_monitor


sub     signal_connecting   {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
            printf  "%5s%s = %s\n",''
                    ,'Number of signals'
                    ,$#{${$monitor}{contacts}};
        }# if debugging
        my $connector   =   [];
        my $signals     =   [];
        my $comment     =   [];
        my $raw_name    =   [];
        my $cmd     = 'assign ';
        my $inst    = ${${$monitor}{instance}}[$ix];
        my $six     = 0;                                #   Signal index
        foreach my $contact ( @{${$monitor}{contacts}} ) {
            unless ($contact =~ m/Monitor/ ) {
                my $cmt = ($contact =~ m/\/\// )? $TRUE:$FALSE;
                (my $copy = $contact) =~ s/\/\///;      #   $contact isn't lvalue
                push( @{$raw_name}, $copy );            #   matching part of connection             
                my $sig = $inst.'.'.$copy;
                push( @{$connector}, $sig );
                push( @{$comment}, $cmt );
            }# unless no column header
        }#for all contacts
        my $device  =   ${${$monitor}{device}}[$ix];
        my $hier    =   ${${$monitor}{hierachie}}[$ix];
        foreach my $signal ( @{${$monitor}{$device}} ) {
            unless ( $signal =~ m/$device/ ) {
                my $stub = $signal;
                my $wire = ${$raw_name}[$six];
                my $sig  = $hier.'.'.$stub.$wire;
                push( @{$signals}, $sig );
                $six++;
            }# unless no column header
        }#for all stub signals
        my  $a1  = length $cmd;
        my  $a2  = maxwidth( $connector );
        $six = 0;
        foreach my $connection  (@{$connector}) {
            my $s   = ${$raw_name}[$six];               #   Signal ID
            my $con = ${$connector}[$six];              #   Connection
            my $com = (${$comment}[$six])? '//': $cmd;  #   Commenting 
            my $sig = ${$signals}[$six];                #   Signal stub
            printf "%-*s%-*s = %s;\n"
                    ,$a1,$com,$a2,$con,$sig;
            ${$monitor}{$s}[$ix] = $sig;                #   Preserve full sig hierachie
            $six++;
        }#for all connections
}#sub   signal_connecting


sub     Questa_directive    {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        my  $n  =  subroutine('name');                  # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
            printf  "%5s%s = %s\n",''
                    ,'Number of signals'
                    ,$#{${$monitor}{contacts}};
        }# if debugging
        my  $i  =   length 'assign ';                   # indent
        my  $dir= ${${$monitor}{directive}}[$ix];       # directive QUESTA_AXI4_MON
        printf "%*s%s %s\n"     ,$i,'','`ifdef',$dir;
        instantiate_wrapper ( $monitor, $ix );
        initial_statement   ( $monitor, $ix );
        printf "%*s%s // %s\n"  ,$i,'','`endif',$dir;
}#sub   Questa_directive


sub     instantiate_wrapper {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        #${$monitor}{protocol} //= 'AXI4';
        my $prot= ${$monitor}{protocol}[$ix];
        my $mon = ( $prot =~ m/AXI4/ )
                ? '.monAxi4' : '.monAxi';
        my $inst= ${$monitor}{instance}[$ix];
        my $hie = ${$monitor}{hierachie}[$ix];
        my $clk = $hie.'.'.${$monitor}{clock}[$ix];
        my $wrap= ($prot=~m/AXI4/)?'axi4_mon_wrap':'axi_mon_wrap';
        my $i   = length "assign `ifdef ";
        my $i1  = (length $wrap) + 1;
        #my $i2  = maxwidth ([ qq{ $wrap $inst} ]) + 3;
        my $i2  = 20;
        my $i3  = $i+$i2+4;
        my $p   = '';
        my $root= ${$monitor}{rootname} [$ix];
        my $xact= ${$monitor}{xaction}  [$ix];
        my $ptrk= ${$monitor}{ptracker} [$ix];
        my $chkr= ${$monitor}{checker}  [$ix];
        my $dwdh= ${$monitor}{dbuswidth}[$ix];
        my $aclk= ${$monitor}{aclk}     [$ix];
        my $arst= ${$monitor}{aresetn}  [$ix];
        $xact   =~ s/\$/$root/; 
        $ptrk   =~ s/\$/$root/; 
        $chkr   =~ s/\$/$root/; 
        my $hier=   ${$monitor}{hierachie}[$ix];
        printf "%*s%-*s #("            , $i,$p,$i2,$wrap;
        #printf "%*s%-*s( \"%*s\" ), \n",  1,$p, 15,'.TRANSNAME'  ,36,$xact;
        printf "%*s%-*s( %*s ), \n" ,  1,$p, 15,'.TRANSNAME'  ,36,$xact;
        printf "%*s%-*s( %*s ), \n" ,$i3,$p, 15,'.PHASENAME'  ,36,$ptrk;
        printf "%*s%-*s( %*s ), \n" ,$i3,$p, 15,'.CHECKERNAME',36,$chkr;
        printf "%*s%-*s( %*s ) )\n" ,$i3,$p, 15,'.BUS_WIDTH'  ,36,$dwdh;
        printf "%*s%-*s  ("         , $i,$p,$i2,$inst;
        printf "%*s%-*s( %*s ), \n" ,  1,$p, 15,'.monAxi4'    ,36,$inst;
        printf "%*s%-*s( %*s ), \n" ,$i3,$p, 15,'.aclk'       ,36,$aclk;
        printf "%*s%-*s( %*s ) );\n",$i3,$p, 15,'.areset'     ,36,$arst;
        printf "\n";
}#sub   instantiate_wrapper


sub     initial_statement    {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
        }# if debugging
        my $a0 = length 'assign  ';
        my $a1 = length 'initial ';
        my $a2 = $a0 + $a1;
        my $inst = ${${$monitor}{instance}}[$ix];
        my $attr = $inst.'.'.'monitor_on';
        printf "%*s%s\n"    ,$a0,'','initial begin';
        printf "%*s%s = 1;\n",$a2,'',$attr;
        printf "%*s%s\n"    ,$a0,'','end'
}#sub   initial_statement


sub     deepcopy_workbook   {
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
			,	$opts	)	=	@_;					    # { CL-options }
        my	$n 	=  subroutine('name');				    # identify sub by name
		my	$revised_file
		= filename_generator($filename, $opts);
		#import previous workbook
		my  $parser   = Spreadsheet::ParseXLSX->new();				# Step 1
    	my  $workbook = $parser->parse( $filename );				# Step 2
    	#my $workbook = $parser->parse( $opts{workbook} );     		
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
			printf  "%10s%s %s\n",'','Source Name'  ,$filename;
			printf  "%10s%s %s\n",'','Target Name'  ,$revised_file;
        }#if debug

		#deepclone	previous	workbook
		my  $clone 	= Excel::Writer::XLSX->new( $revised_file );	# Step 3
		#copy	previous	workbook
        for my $sheet ( $workbook->worksheets()  ) {
			if( debug($n))  {
				printf  "%10s%s %s\n",'','Worksheet  ',$sheet->get_name();
			}# if debug
			my $ws = $clone->add_worksheet($sheet->get_name());		# Step 4
			deepclone	( $sheet, $ws );							# Step 5
		}
		#update add latest	coverage report
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


sub		file_exists	{
		my	(	$hash
			,	$key
			,	$name	)	= @_;
		my	$f = ${$hash}{$key};
		my	$e = ( -e $f)? $TRUE : $FALSE;
        my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING File $f not found !!");
        print BLINK BOLD RED $msg, RESET unless $e;
		if ( debug($name)) {
			printf "%*s%s\n", 5,'',"File $f found";
			printf "%*s%s\n",10,'','ASCII/UTF-8 Text file' if ( -T $f);
			printf "%*s%s\n",10,'','Binary file'           if ( -B $f);
			printf "%*s%s\n",10,'','readable'              if ( -r $f);
			printf "%*s%s\n",10,'','writeable'             if ( -w $f);
		}#if debug
		return $e;
}#sub	file_exists



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
        my	$n 	=  subroutine('name');						# identify sub by name
        my	($row_min,$row_max) = $org->row_range();		# region span in y / rows
        my	($col_min,$col_max) = $org->col_range();   		# region span in x / columns
		for my $row ($row_min .. $row_max) {
			printf  "%22s%s %s\n",'','row',$row	if( debug($n)); 
		    for my $col ($col_min .. $col_max) {
				printf  "%26s%s %s\n",'','col',$col	if( debug($n)); 
				my $cell = $org->get_cell($row,$col);		# CELL
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


sub     test_character  {
        my  ( $monitor     )   = @_;
        #my $e   = scalar ( @{${$monitor}{checker}} );
        #my $root= ${$monitor}{rootname} [$e];    #   [$ix];
        #my $xact= ${$monitor}{xaction}  [$e];    #   [$ix];
        #my $ptrk= ${$monitor}{ptracker} [$e];    #   [$ix];
        #my $chkr= ${$monitor}{checker}  [$e];    #   [$ix];
        my $root= ${$monitor}{rootname} [ 4];    #   [$ix];
        my $xact= ${$monitor}{xaction}  [ 4];    #   [$ix];
        my $ptrk= ${$monitor}{ptracker} [ 4];    #   [$ix];
        my $chkr= ${$monitor}{checker}  [ 4];    #   [$ix];
        $chkr   =~ s/\$/$root/; 

        my $char = substr $chkr, -1;
        printf  "%5s%s\n",'',$chkr;
        printf  "%5s%s = %3s\n",'',"\"",ord("\"");
        printf  "%5s%s = %3s\n",'',$char,ord($char);
        printf  "\n";
}#sub   test_character



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
