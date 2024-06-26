package File::IO::Copy;
# File          ~/ws/perl/lib/File/IO/Copy.pm
#
# Refactored    09/13/2020
#               
# Author        Lutz Filor
# 
# Synopsis      Copy::fcopy         (   [ArrRef], destination   )
#               Copy::backup_list   (   rp() Reading UTF-8 text file ->  text string single multiline
#
#               When compiling lists, list are prone to errors, that are hard to spot
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use File::Copy;
#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.03");

use Exporter qw (import);
use parent 'Exporter';                              #   replaces base; base is deprecated


#our @EXPORT   =    qw(                      );     #   Implicite export depricated, error prone

our @EXPORT_OK =    qw(     filename
                            fcopy
                            backup_list     
                      );                            #   Explicite export

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]   );

#----------------------------------------------------------------------------
#       C O N S T A N T S


#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     fcopy   {                                   #   Copy array  -> File, quick and dirty
        my  (   $a_ref                              #   [ArrRef] with lines of text, file content
            ,   $f      )   =   @_;                 #   Fullfilename
        open    (   my  $fh,    '>:encoding(UTF-8)',$f  );
        foreach my $line ( @{$a_ref} ) {
            printf $fh  "%s\n",$line;
        close   (   $fh );
}#sub   fcopy

sub     backup_list {
        my  (   $a_ref
            ,   $dest   )   =   @_;                 #   Destination full Directory path
        my  $width  =   maxwidth( $a_ref ,  0       );  #   Innitialize column width
            $width  =   maxwidth( [$dest],  $width  );  #   Combine the column width
        check_dir ( $dest,  { width   =>  $width  }):
        check_list( $a_ref, { width   =>  $width  });
        copy_list ( $a_ref, $dest   );
}#sub   backup_list

#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D E S

sub     filename    {
        my  (   $fullname   )   =   @_;
        my  @file_path  =   split   /\//, $fullname;
        my  $basename   =   $file_path[-1];
        return  $basename;
}#sub   filename

sub     copy_list   {
        my  (   $a_ref
            ,   $destination    )   =   @_;
        foreach my $file ( @{$a_ref} ) {
            chomp   $file;                              #  Eliminate potential new line terminators
            copy    ( $a_ref, $destination) or          #  File::Copy::copy()
            die     ( "Failed copying : $!" );
        }#iterate file list
}#sub   copy_list

sub     check_file  {
        my  (   $file                                   #  FullFilename
            ,   $format     )   =   @_;                 #  Format information
        my  $width  =   $$format{width};                #  Align filenames
        chomp   $file;                                  #  Eliminate potential new line terminators
        if ( -e $file ) {
            if  ( -f $file ) {
                if ( -r $file ) {
                    $m1 =   "INFO    traget ";
                    $m2 =   " exist but is NOT readable";
                    printf  "%*s%*s%s\n",5,''
                            ,$m1,$w,$file,$m2;          #  Die with noise
                    return;                             #  Default succesfull return from
                } else {
                    $m1 =   "WARNING traget ";
                    $m2 =   " exist but is NOT readable";
                    printf  "%*s%*s%s\n",5,''
                            ,$m1,$w,$file,$m2;          #  Die with noise
                    exit    3;
                }
            } else {
                $m1 =   "WARNING traget ";
                $m2 =   " exist but is no FILE !!";
                printf  "%*s%*s%s\n",5,''
                        ,$m1,$w,$file,$m2;              #  Die with noise
                exit    2;
            }# object is not a file
        } else {
            $m1 =   "WARNING traget ";
            $m2 =   " doesn't exist";
            printf  "%*s%*s%s\n",5,''
                    ,$m1,$w,$file,$m2;                  #  Die with noise
            exit    1;
        }# file exist not
}#sub   check_file

sub     check_list  {
}#sub   check_list

sub     check_dir   {
}#sub   check_dir


#----------------------------------------------------------------------------
# End of module
1;
