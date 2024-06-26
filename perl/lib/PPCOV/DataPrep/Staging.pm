package PPCOV::DataPrep::Staging;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/PPCOV/DataPrep/Staging.pm
#
# Created       02/22/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::DataPrep::Staging::extraction()
#                       input   data path reference to raw data             
#                       return  reference to intermediate data table
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Term::ANSIColor             qw  (   :constants  );                              # available
#   print BLINK BOLD RED $msg, RESET;
#   
use lib							qw  (   /mnt/ussjf-home/lfilor/ws/perl/lib );       # Add Include path to @INC
use Dbg                         qw  (   debug subroutine    );
use File::IO::UTF8::UTF8        qw  (   read_utf8   
                                        write_utf8      );
use Logging::Record             qw  (   log_msg
                                        log_lmsg        );
#use lib                        qw  (   ../lib );                                   # Relative UserModulePath
#use UTF8                       qw  (   read_utf8
#                                       write_utf8      );
#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.07");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   extraction
							build_picker
							build_aoi_table
							build_table
							build_header
							build_cpit_header
							build_cpit_picker
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # Category export 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S

sub		extraction	{
		my	(	$p_r								# Pointer reference RAW data
			,	$missing_header )	=	@_;			# [ Scope TOTAL ]
		my $correlation	=	{};						# Data hash	
        my $n =  subroutine('name');                # identify sub by name
        if( debug($n)) {
            printf "\n%5s%s() \n",'',$n;
            printf "%9s%s %s reference\n",''
                    ,'ParamType '
                    ,ref $p_r;
			printf "%9s%s \n",'',@{$missing_header};
        }# debug
		my $w   = maxwidth ( [keys %{$p_r}] );		# width of keywords
		my $s   = $missing_header;					# shorten param name
		foreach my $unit	( keys %{$p_r} ) {
			if ( debug($n) ) {
				printf "%5s%-*s = ",'',$w, $unit;
				printf "%s\n",${$p_r}{$unit}{raw}{header}[0];
				printf "%*s%s\n",8+$w,'',${$p_r}{$unit}{raw}{instances}[0];
				printf "%*s%s\n",8+$w,'',${$p_r}{$unit}{raw}{header}[1];
				printf "%*s%s\n",8+$w,'',${$p_r}{$unit}{raw}{rectable}{raw}[0];
				printf "%*s%s\n",8+$w,'',${$p_r}{$unit}{raw}{rectable}{raw}[1];
				printf "\n";
			}# if debug
			my $head1_r = ${$p_r}{$unit}{raw}{header}[0];
			my $data1_r = ${$p_r}{$unit}{raw}{instances}[0];
			my $head3_r = ${$p_r}{$unit}{raw}{header}[1];
			my $data30_r= ${$p_r}{$unit}{raw}{rectable}{raw}[0];
			my $data31_r= ${$p_r}{$unit}{raw}{rectable}{raw}[1];
			${$correlation}{$unit}{name}		= $unit;	
			${$correlation}{$unit}{TOTAL}		= corralate_data($head1_r,$data1_r ,$s);
			${$correlation}{$unit}{Statements}	= corralate_data($head3_r,$data30_r,$s);
			${$correlation}{$unit}{Branches}	= corralate_data($head3_r,$data31_r,$s);
		}# for all units
		return $correlation;
}#sub   extraction

	
sub		build_picker	{
		my	(	$kv_r	)	=	@_;					# [ key-value pair list ]
		my	$picker		=	[];
		#for my $ix	( 0 .. $#{$kv_r} )	{
		#foreach my $ix	( 0 .. $#{$kv_r} )	{
		#for my $ix	( 0 .. $#{$kv_r} )	{
		for ( my $ix = 0; $ix < $#{$kv_r} ; $ix += 2) {
			my $vpair = { ${$kv_r}[$ix], ${$kv_r}[$ix+1]};
			#$ix +=2;
			push ( @{$picker}, $vpair);
		}# for all cell picker
		return $picker;
}#sub	build_picker


sub		build_table	{
		my	(	$data_hive									# { raw_data      }
			,	$header										# [ custom header ]
			,	$chain    	)	=	@_;						# chain of cells
		my	$table	=	[];									# custom table
		push ( @{$table}, $header );						# insert header
		foreach my $instance ( keys %{$data_hive} ) {
			my $row	=	[];									# table row
			foreach my $key ( @{$chain} )	{
				my $key_chain	=	[];
				push( @{$key_chain}, $instance	);
				push( @{$key_chain}, @{$key}	);
				push( @{$row}
					, access_data($data_hive,$key_chain) );	# data cell
			}# each row
			push ( @{$table}, $row );						# build table
		}# each instance
		return $table;
}#sub	build_table


sub		build_aoi_table	{
		my	(	$aoi_r										# report area of interest
			,	$tgt_inst									# control flow
			,	$data_hive									# raw data	
			,	$sep		)	=	@_;						# seperator
			$sep	//= ' \+ ';
        my $n =  subroutine('name');						# identify sub by name
		my $w   = maxwidth ( $aoi_r );						# width of keywords
        if( debug($n)) {
            printf "\n%5s%s() \n",'',$n;
        	printf "%9s%s %s\n" ,'','#Area of Interest', $#{$aoi_r};
			printf "%9s%s(%s)\n",'','Separator        ', $sep;
		}# debug
		printf "%*s%*s | %s\n",9,''
				,$w,${$aoi_r}[0],${$tgt_inst}[0];
		foreach my $ix	( 1 .. $#{$aoi_r} ) {
			my	@tmp = split  /$sep/, ${$tgt_inst}[$ix] ;
			printf "%*s%*s = %s :: %s\n",9,''
					,$w,${$aoi_r}[$ix],$#tmp
					,${$tgt_inst}[$ix];
					foreach my $inst ( @tmp ) {
						printf "%*s(%s)\n",17+$w,'',$inst;
					}# all traget instances to be gathered
		}# for all area of interest
}#sub	build_aoi_table


# CPIT	Coverage Progress Indicator Table - Synaptics Proprietary Term
#		This is the history of the development of CPIT

#========================================================================================
#	INSTANCE	| Statement | Statement | Statement |   Branch	|  Branch   |   Branch	| 
#				|			|    Bins   |    Hits   |			|   Bins	|	 Hits   |
#========================================================================================


#============================================================================================================
#   INSTANCE	|   Scope   | Statement |  Statements	|   Statements	|   Branch	|  Branches |  Branches	|
#				|	        |		    |     Bins		|      Hits		|			|    Bins	|	 Hits	|
#============================================================================================================
# u_dut	        | TOTAL	    |     59.68 |        308483 |        184110 |     42.56 |    227246 |     96737 |
#				|			|			|				|				|			|			|			|
# u_dut,		|	u_dut,	| u_dut,	| u_dut,		| u_dut,		| u_dut,	| u_dut,	| u_dut,	|	$instance
# name			|	TOTAL,	| TOTAL,	| Statements,	| Statements,	| TOTAL,	| Branches,	| Branches, |
#				|	Scope	| Statement	| Bins			| Hits			| Branch	| Bins		| Hits		|
#
my	$cpit_picker_old=	[	[ qw( name ) ],			
							[ qw( TOTAL     Scope ) ],
							[ qw( TOTAL Statement ) ],
							[ qw( Statements Bins ) ],
							[ qw( Statements Hits ) ],
							[ qw( TOTAL    Branch )	],
							[ qw( Branches   Bins ) ],
							[ qw( Branches	 Hits ) ],
						];


#	cpit :: coverage_progress_indicator_table
#============================================================================================================ 
#   INSTANCE	|   Scope   |  Statements	|   Statements	| Statement |  Branches |  Branches	|   Branch	|
#				|	        |     Bins		|      Hits		|		    |    Bins	|	 Hits	|			|
#============================================================================================================
# u_dut	        | TOTAL	    |        308483 |        184110 |     59.68 |    227246 |     96737 |     42.56 |
#				|			|				|				|			|			|			|			|
# u_dut,		|	u_dut,	| u_dut,		| u_dut,		| u_dut,	| u_dut,	| u_dut,	| u_dut,	|	$instance
# name			|	TOTAL,	| Statements,	| Statements,	| TOTAL,	| Branches,	| Branches, | TOTAL,	|
#				|	Scope	| Bins			| Hits			| Statement	| Bins		| Hits		| Branch	|
#
my	$cpit_picker	=	[	[ qw( name ) ],			
							[ qw( TOTAL     Scope ) ],
							[ qw( Statements Bins ) ],
							[ qw( Statements Hits ) ],
							[ qw( TOTAL Statement ) ],
							[ qw( Branches   Bins ) ],
							[ qw( Branches	 Hits ) ],
							[ qw( TOTAL    Branch )	],
						];



#	cpit :: coverage_progress_indicator_table
my	$cpit_headline	=	[ qw( Instance Scope Statement Branch ) ];

splice  @{$cpit_headline}, 2,0, qq{ Statements\nBins };
splice  @{$cpit_headline}, 3,0, qq{ Statements\nHits };
splice  @{$cpit_headline}, 5,0, qq{ Branches\nBins };
splice  @{$cpit_headline}, 6,0, qq{ Branches\nHits };

sub		build_cpit_header	{
		my $cpit_header =	[ qw( Instance Scope Statement Branch ) ];
		splice @{$cpit_header}, 2,0, qq{ Statements\nBins };
		splice @{$cpit_header}, 3,0, qq{ Statements\nHits };
		splice @{$cpit_header}, 5,0, qq{  Branches\nBins  };
		splice @{$cpit_header}, 6,0, qq{  Branches\nHits  };
		return   $cpit_header;	
}#sub	build_cpit_header


sub		build_cpit_picker	{
		my	$cpit_picker	=	[	[ qw( name ) ],			
									[ qw( TOTAL     Scope ) ],
									[ qw( Statements Bins ) ],
									[ qw( Statements Hits ) ],
									[ qw( TOTAL Statement ) ],
									[ qw( Branches   Bins ) ],
									[ qw( Branches	 Hits ) ],
									[ qw( TOTAL    Branch )	],
								];
		return $cpit_picker; 
}#sub	build_cpit_picker


sub		build_header	{
		my @header	=	@_;
		return	[ @header ];
}#sub	build_header

#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S


sub     maxwidth    {
        my  (   $array_r    )   =   @_;
        my  $max    =   0;
        foreach my $entry  ( @{$array_r} ) {
            my $tmp =   length($entry);
            $max = ( $max > $tmp ) ? $max : $tmp;
            #printf "%9s%*s\t%s\n",'',$max,$entry,$tmp;
        }#for all
        #printf "%9s%*s\t%s\n",'',$max,'max',$max;
        return $max;
}#sub   maxwidth


sub		corralate_data	{
		my	(	$head_r								# packed string
			,	$data_r								# packed string
			,	$miss_h		)	= @_;				# missing header
        my $n =  subroutine('name');                # identify sub by name
		my $tmp  = get_listvalues( $head_r );		# [ @arr ]
		my $data = [ split(/,/ ,$data_r ) ];		# [ @arr ]
		my $head = [];								# [ @arr ]
		my $aggregated = {};

		push (@{$head}, @{$miss_h}) if($#{$tmp} < $#{$data});
		push (@{$head}, @{$tmp} );
		
        if( debug($n)) {
			printf "%9s%s %s\n",'','SoA head', $#{$tmp};
        	printf "%9s%s %s\n",'','SoA data', $#{$data};
			printf "%9s%s %s\n",'','SoA head+', $#{$head};
        	printf "%9s%s %s\n",'','SoA data+', $#{$data};
        }# debug

		my $w = maxwidth( $head );
		foreach my $ix ( 0 .. $#{$head} ) {
			printf "%9s%*s => %s\n",'',$w, ${$head}[$ix],${$data}[$ix];
			${$aggregated}{${$head}[$ix]} = ${$data}[$ix];
		}# all columns
		return $aggregated;
}#sub	corralate_data


sub		get_listvalues	{
		my	(	$list_r	)	= @_;
		my $tmp = [ split (',',$list_r) ];
		my $lst = [];
		foreach my $value ( @{$tmp} ) {
			if ( $value =~ m/[^']*[']([^']*)[']/xms  ) {
				push ( @{$lst}, $1);
			}# match value 
		}# for all values
		return $lst;								# list reference
}#sub	get_listvalues


sub		access_data	{
		my	(	$data_hive							# { $data_hive }
			,	$key_chain	)	=	@_;				# [ $key_chain ]
		my $access = $data_hive;
		foreach my $key ( @{$key_chain} ) {
			$access = ${$access}{$key};
		}#for all keys in chain
		return $access;
}#sub	access_data


#----------------------------------------------------------------------------
#  End of module
1

