package PPCOV::Control;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/PPCOV/Control.pm
#
# Refactored    01/30/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::Control::validation_interest() 
#                       return list of blocks/areas of interest
#
#               PPCOV::Control::deepcopy_worksheet()
#                       return  [ workbook ]
#
#               PPCOV::Control::display_deepcopy()
#                       inspect [ workbook ] on terminal formatted
#
#               PPCOV::COntrol::extract_columndata()
#                       return  [ column data ]
#
# Data model    [workbook]->@[sheet]->@name,[data]->@[col]->@cell
#                                          
#               
#----------------------------------------------------------------------------
#  I M P O R T S 
use strict;
use warnings;

use lib             qw  (   ../lib );               # Relative UserModulePath
use Dbg             qw  (   debug subroutine    );

#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.02");

use Exporter qw (import);                           # Import <import> method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export             # NOT recommended to use

our @EXPORT_OK  =   qw  (   readout_worksheet
                            display_deepcopy
                        );#explicite export             # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],        # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

#----------------------------------------------------------------------------
#  S U B R O U T I N S

sub     readout_worksheet   {                                                       # unformated readout of workbook data
        my  (   $book_r     )   =   @_;
        for my $sheet ( $book_r->worksheets()  ) {
            printf "%5s%s %s\n"     , '','#worksheet :'    , $sheet->get_name();
            my ( $row_min, $row_max ) = $sheet->row_range();
            my ( $col_min, $col_max ) = $sheet->col_range();
            
            for my $row ( $row_min .. $row_max ) {
                for my $col ( $col_min .. $col_max ) {

                    my $cell = $sheet->get_cell( $row, $col );
                    next unless $cell;

                    print "Row, Col    = ($row, $col)\n";
                    print "Value       = ", $cell->value(),       "\n";
                    print "Unformatted = ", $cell->unformatted(), "\n";
                    print "\n";
                }#for each column                                               
            }#for each row
        }#for each sheet
}#sub   readout_worksheet



sub     display_deepcopy {
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
}#sub   display_deepcopy

#----------------------------------------------------------------------------
#  End of module
1;
