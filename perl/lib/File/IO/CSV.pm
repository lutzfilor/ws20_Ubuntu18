package File::IO::CSV;
# File          ~/ws/perl/lib/File/IO/CSV.pm
#
# Created       09/18/2020
#               
# Author        Lutz Filor
# 
# Synopsis      UTF8::read_utf8()       Reading UTF-8 text file ->  text string arrary
#               UTF8::read_utf8_slurp() Reading UTF-8 text file ->  text string single multiline
#               UTF8::read_utf8_string()Reading UTF-8 text file ->  text string single line \n removed
#               UTF8::write_utf8()      Writing text array      ->  UTF-8 encoded file
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use File::IO::UTF8  qw  /   read_utf8
                            write_utf8      /;          #   Import

#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.08");

use Exporter qw (import);
use parent 'Exporter';                                  #   replaces base; base is deprecated


#our @EXPORT   =    qw(                      );         #   deprecate implicite 

our @EXPORT_OK =    qw(     read_csv
                            write_csv        );         #   comma separated values

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]   );

#----------------------------------------------------------------------------
#       C O N S T A N T S


#----------------------------------------------------------------------------
#       S U B R O U T I N S


sub     read_csv    {                                   #   [$ArrRef]   <== read_csv( $filename )
        my  (   $f  )   =   @_;
        my  $ArrRef =   [];
        file_exists ( $f );                             #   
        @{$ArrRef} =  read_utf8 (     $f  );            #   Readin UTF8 encoded file
        $ArrRef =   csv_unpack  ( $ArrRef );            #   Array of Scalar => Array of Array of Scalar
        $ArrRef =   fully_occupy( $ArrRef );            #   Fully occupy all table cells 
        return $ArrRef;                                 #   [$ArrRef]   2D array, table
}#sub   read_csv

sub     write_csv   {                                   #   write_csv ( $filename, [$ArrRef] )
        my  (   $f  
            ,   $ArrRef )   =   @_;
        my  $pArrRef    =   csv_pack( $ArrRef );        #   2D [$ArrRef]    =>  CSV packed ArrRef
        write_utf8  (   $f, $pArrRef    );              #   Writeback UTF8 encoded file
        return;                                         #   Default return statement
}#sub   write_csv

#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D S

sub		file_exists	{
		my	(	$filename	)	=	@_;
		unless ( -e $filename ) {
			printf "%5sFile%s%s%s\n",'',' 'x16,$filename,' not found !!';
			exit 1;                                                             #   Protective Termination
		}# 
}#sub	file_exists


sub     max_rows   {                                                            #   max table rows 
        my  (   $ArrRef )   =   @_;
        return  $#{$ArrRef} + 1;                                                #   return #of rows, not index
}#sub   max_rows

sub     max_cols    {                                                           #   max table columns
        my  (   $ArrRef )   =   @_;
        my  $max    =   0;
        for my $datasets( @{$ArrRef} )  {
            my $tmp =   $#{$datasets} +1;                                       #   Number of cells in dataset
            $max    =   ( $tmp > $max ) ? $tmp : $max;
        }# all
        return $max;                                                            #   return  #of columns
}#sub   max_cols

sub     fully_occupy    {
        my  (   $ArrRef )   =   @_;
        my  $fot    =   [];                                                     #   Fully occupied table
        my  $mcl    =   max_cols( $ArrRef );                                    #   Find max number of columns
        for my $sets ( @{$ArrRef} ) {
            for ( ($#{$sets}+1)..($mcl-1) )   {
                push( @{$sets}, '');
            }# fill up set to be fully occupied/defined
            push( @{$fot}, $sets);
        }#
        return $fot;                                                            #   return Fully Occupied Tabke
}#sub   fully_occupy

sub     csv_unpack  {
        my  (   $ArrRef     )   =   @_;
        my  $uArrRef    =   [];                                                 #   Unpacked Array Ref
        for my $lines   ( @{$ArrRef} )  {
            chomp $lines;                                                       #   Remove line separator
            my @line    =   split(/,/, $lines);
            push( @{$uArrRef}, \@line );
        }# for all lines
        #printf  "%5sNumber of rows    :: %s\n",'',max_rows( $uArrRef );         #   Development
        #printf  "%5sNumber of columns :: %s\n",'',max_cols( $uArrRef );         #   Development
        return $uArrRef;                                                        #   return 2D [$uArrRef]
}#sub   csv_unpack

sub     csv_pack    {
        my  (   $ArrRef     )   =   @_;
        my  $pArrRef    =   [];                                                 #   Packed Array Ref
        for my $data    (   $ArrRef )   {
            my  $set    =   join(",", @{$data} );                               #   @data
            push    (   @{$pArrRef}, $set   );                                  #   create CSV pArray
        }# for all rows/ data sets
        return  $pArrRef;
}#sub   csv_pack

#----------------------------------------------------------------------------
# End of module
1;
