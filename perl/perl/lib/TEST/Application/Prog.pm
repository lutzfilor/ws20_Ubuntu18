package TEST::Application::Prog;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/TEST/Application/Prog.pm
#
# Refactored    04/10/2019          
# Author        Lutz Filor
# 
# Synopsys      TEST::Application::Prog::validate_setup() 
#                       return list of blocks/areas of interest
#
# Data model    [workbook]->@[sheet]->@name,[data]->@[col]->@cell
#                                          
#               
#----------------------------------------------------------------------------
#  I M P O R T S 
use strict;
use warnings;
use Switch;                                                         # Installed 11/28/2018

use Readonly;
use POSIX						    qw  (   strftime    );			# Format string
use Term::ANSIColor				    qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;


use lib							    qw  (   ../lib );               # Relative UserModulePath
use Dbg							    qw  (   debug 
                                            subroutine    );
use PPCOV::DataStructure::DS	    qw  (   list_ref            );  # Data structure

use Create::Directory::Directory    qw  (   makepaths           );  # create subdir path
                                

#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.03");

use Exporter qw (import);                           # Import <import> method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended to use

our @EXPORT_OK  =   qw  (   testing
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # Create a category 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S


sub     testing {
        my (    $opts   )   =   @_;
        my  $format =   ${$opts}{format};                           # { } anonymous hash
        my  $n  =   subroutine('name');                             # identify the subroutine by name
        my  $i  =   ${$format}{indent};                             # indentation
        my  $p  =   ${$format}{indent_pattern};                     # indentation pattern
        ${$format}{self} = 'format';                                # hash name itself
        my $ins =   unpack_instruction ( $opts, 'create' );         # { } anonymous hash of instruction
        my $obj = (defined ${$ins}{formal} )
                ?  ${$ins}{formal}:'UNDEFINED';
        my $msg = sprintf "%*s%s%s",5,'','WARNING unknow object ',
                          ,${$ins}{formal};
        if ( debug($n) ) {
            printf  "%*s%s()\n"  ,$i,$p,$n;
            printf  "%*s%s\n" , 2*$i,$p,${$opts}{create};
            list_hash ( $ins    );
            list_hash ( $format );
        }# debug
        _instruction    ( $ins, $format );            
}#sub   testing

#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

sub     unpack_instruction {
        my  (   $opts   
            ,   $what   )   =   @_;
        my  $instruction            =   {};
        my  $argument               =   ${$opts}{$what};
        my  ($object,$objectlist)   =   split (/:/,$argument);
        ${$instruction}{self}       =   'instruction';              # referal to EigenName
        ${$instruction}{command}    =   $what;
        ${$instruction}{formal}     =   $object;
        ${$instruction}{actual}     =   [split(/,/,$objectlist)];
        return $instruction;
}#sub   unpack_argument


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


sub     list_hash   {
        my  (   $href   
            ,   $i      )   =   @_;
            $i  //= 10;                                         # indent
        my  $k  = '';    
        my  @s  = keys  %{$href};
        my  $w  = maxwidth ( [keys %{$href}] );                 # width of keywords
        my  $n  =  subroutine('name');                          # identify the subroutine by name
        if ( debug($n) ) {
            printf  "%*s%s()\n",5,'',$n;
            printf "%*s%s %s\n",$i,'','MaxWidth HashKeys',$w;
            printf "%*s%s %s\n",$i,'','Number   HashKeys',$#s;  # Number of Hash entries
        }# debug
        if ( defined ${$href}{self} ) {                         # If EigenName is defined
            my $v =  ${$href}{self};                            # hash value of {key}
               $k = '{ } self ';                                # hash key
            printf "%*s%s%s\n",$i,'',$k,$v;
            $i += length ( $k );                                # Adjust indentation
        }# 
        foreach my $key ( keys %{$href} ) {
            unless ( $key eq 'self' ) {
                printf "%*s%*s",$i,'',$w,$key;
                printf " %s\n",${$href}{$key};
            }# self reference
        }# for all entries
}#sub   list_hash


sub     default_format {
        my  (   $href   )   = @_;                               # ensure format definitions

}#sub   default_format


sub     _instruction {
        my  (   $instruction    
            ,   $format         )   =   @_;
        my  $n  =  subroutine('name');                          # identify the subroutine by name
        printf  "%*s%s()\n",5,'',$n;
        my  $instr  =   ${$instruction}{command};
        my  $objct  =   ${$instruction}{formal};
        my  $paths  =   ${$instruction}{actual};
        my  $msg    = sprintf "%*s%s%s%s\n",5,'','WARNING instruction ',
                              ,${$instruction}{command},' unknown';
        switch  ( $instr ) {
            case    m/\bcreate\b/    { _create ( $instruction, $format ); }
            #case    m/\bnamespace\b/ { _create_namespaces  ( $ins ); }
            #case    m/\bproject\b/   { _create_projects    ( $ins ); }
            #case    m/\bdocx\b/      { _create_docx        ( $ins ); }
            else    { print BLINK BOLD RED $msg, RESET; exit 1; }
        }#switch
}#sub   _instruction


sub     _create {
        my  (   $instruction
            ,   $format         )   =   @_;
        my  $n  =  subroutine('name');                          # identify the subroutine by name
        my  $i  =   ${$format}{indent};                         # indentation
        my  $p  =   ${$format}{indent_pattern};                 # indentation pattern
        my  $d  =   ${$format}{dryrun};                         # suppress execution
        my  $instr   =   ${$instruction}{command};              # instruction
        my  $object  =   ${$instruction}{formal};               # formal parameter
        my  $objects =   ${$instruction}{actual};               # actual parameter list
        my  $msg    = sprintf "%*s%s%s%s",5,'','WARNING object ',
                              ,${$instruction}{formal},' unknown';
        printf  "%*s%s()\n",$i,$p,$n;
        printf  "%*s%s %s\n",$i,$p,'Debug ',(debug($n))?'    set':'not set';
        if ( debug($n) ) {
            printf  "%*s%s()\n",$i,$p,$n;
            printf  "%*s%s%s\n",$i*2,$p,'reference ',ref $objects;
            printf  "%*s%s  \n",$i*2,$p,'NO execution' if ${$format}{dryrun};
        }# debug
        switch  ( $object ) {
            case    m/\bdirectory\b/    { makepaths ( $objects, $format ); }
            case    m/\bnamespace\b/    { _create_namespaces  ( $objects, $format ); }
            case    m/\bproject\b/      { _create_projects    ( $objects, $format ); }
            case    m/\bdocx\b/         { _create_docx        ( $objects, $format ); }
            else    { print BLINK BOLD RED $msg, RESET; }
        }#switch
        printf  "%*s%s() ... done \n",$i,$p,$n;
}#sub   _create

sub     _create_namespaces  {
        printf  "%*s%s\n",5,'','namespaces()';
}#sub   _create_namespaces

sub     _create_projects    {
        printf  "%*s%s\n",5,'','projects()';
}#sub   _create_projects

sub     _create_docx        {
        printf  "%*s%s\n",5,'','projects()';
}#sub   _create_docx

#----------------------------------------------------------------------------
#  End of module Test::Application::Prog
1

