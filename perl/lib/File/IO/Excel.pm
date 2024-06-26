package File::IO::Excel;
# File          ~/ws/perl/lib/File/IO/Excel.pm
#
# Refactored    09/14/2020
#               
# Author        Lutz Filor
# 
# Synopsis      Excel::open_workbook()       Reading (.xlsx file ) ->  [workbook]
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Spreadsheet::ParseXLSX;							                                # Spreadsheet::ReadExcel 
#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.02");

use Exporter qw (import);
use parent 'Exporter';                              # replaces base; base is deprecated


#our @EXPORT   =    qw(                      );     #   deprecated implicite export

our @EXPORT_OK =    qw( open_workbook
                        read_worksheet
                        list_worksheets
                      );                            #   explicite export

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]   );

#----------------------------------------------------------------------------
#       C O N S T A N T S


#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     open_workbook   {
        my  (   $filename   )   =   @_;
        file_exists (   $filename   );
        my  $parser =   Spreadsheet::ParseXLSX->new();          #   Step-1
    	my  $workbook = $parser->parse( $filename );			#   Step-2
        printf  "%5sStep-1\n",'';
        return  $workbook;
}#sub   open_workbook

sub     list_worksheets {
        my  (   $workbook   )   =   @_;
        for my $sheet ( $workbook->worksheets()  ) {
			printf  "%10s%s %s\n",'','Worksheet'
                    ,$sheet->get_name();
			#my $ws = $clone->add_worksheet($sheet->get_name());#   Step 4
			#deepclone	( $sheet, $ws );						#   Step 5
		}
        return;
}#sub   list_worksheets

sub     read_worksheet   {
        my  (   $workbook
            ,   $sheetname  )   =   @_;
        printf  "%5sStep-2\n",'';
        for my $sheet ( $workbook->worksheets()  ) {
            if  ( $sheet->get_name() eq $sheetname )    {
                printf  "%10sFound Worksheet %s\n",''
                        ,$sheet->get_name();
                my $table   =   copy_worksheet( $sheet );
                return $table;                                  #   2D [ArrRef]
            }#Found worksheet
        }#Looking for worksheet
        exit 1;                                                 #   Couldn't find Worksheet
}#sub   read_worksheet

sub     copy_worksheet  {
        my  (   $worksheet  )   =   @_;
        my  $data   =   [];                                     #   [ArrRef] of [ArrRef] 2D array
        my	($row_min,$row_max) = $worksheet->row_range();		#   region span in y / rows
        my	($col_min,$col_max) = $worksheet->col_range();   	#   region span in x / columns
        printf "%5s[%s..%s] row range\n",'',$row_min,$row_max;
        printf "%5s[%s..%s] col range\n",'',$col_min,$col_max;
		for my $row ($row_min .. $row_max) {
            my  $rdata  =   [];                                 #   row data
		    for my $col ($col_min .. $col_max) {
                #printf "%*s<%2s|%2s>\n",5,'',$row,$col;
				my $cell = $worksheet->get_cell($row,$col);		#   CELL
                if ( defined $cell ) {
                    push( @{$rdata}, $cell->unformatted() );    #   Copy Cell.Value
                } else {
                    push( @{$rdata}, '' );                      #   Create completely occupied table
                }#
            }# copy entire row
            push(   @{$data}, $rdata );
        }#  for all rows
        return $data;
}#sub   copy_worksheet

#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D S

sub		file_exists	{
		my	(	$filename	)	=	@_;
		unless ( -e $filename ) {
			printf "%5sFile%s%s%s\n",'',' 'x16,$filename,' not found !!';
			exit 1;                                                             #   Protective Termination
		}# 
}#sub	file_exists


#----------------------------------------------------------------------------
# End of module     File::IO::Excel
1;
