package Dbg;
# File          Dbg.pm
#
# Refactored    01/17/2019          
# Author        Lutz Filor
# 
# Synopsys      Dbg::debug()            utility controling verbosity subs from the command line
#               Dbg::subroutine()       return the name of the caller subroutine
#                  ::subroutine('name')
#                  ::subroutine('space')
#               Dbg::Debugfeatures()    check for --dbg0 option, --dbg1 is a deeper reporting
#
# Revision  VERSION     DATE            Description
# ================================================================================================
# History   1.01.01     01/17/2019      Create general purpose debug methods         
#                                       Extracte from tsg.pl                       
#           1.01.02     01/30/2019      Bug fix in subroutine() support deeper name spaces
#           1.01.03     04/23/2019      Bug fix terminate library correctly with magic value 1;
#                                       Expanded DebubFeatures
#                                       Exported DebugFeatures
#                                       Add private method maxwidth()

use strict;
use warnings;
use feature 'state';

#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.03");

use Exporter qw (import);
use parent 'Exporter';                              # replaces base

our @EXPORT    = qw(    subroutine
                        debug
                   );   #dbg functions

our @EXPORT_OK = qw(    subroutine
                        debug
                        DebugControl
                        ListModules
                        DebugFeatures
                        $VERSION
                   );   #dbg functions

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK, 'DebugFeatures' ]
                   );

#----------------------------------------------------------------------------
# C O N S T A N T S

#----------------------------------------------------------------------------
# S U B R O U T I N S


sub   ListModules {                                                                 # List Module     
      no strict;                                                                    # access $VERSION by symbolic reference
      print map {
          s!/!::!g; 
          s!.pm$!!; 
          sprintf "%-20s %s\n", $_, ${"${_}::VERSION"} 
      } sort keys %INC; 
}#sub ListModules


sub   DebugFeatures{                                                                # How to debug the debug feature
      my    (   $opts_ref   )   = @_;                                               # Command line input
      
      my $msg = 'Debug feature dgb  ';                                              # Debug setting message
      printf "%*s%s%s%s\n",5,'',$msg
             ,(defined ${$opts_ref}{dbg})?' ':'un','defined';                       # Showing that the DebugControl is now observable
      my $msg0 = 'Debug feature dgb0 ';                                             # Debug setting message
      printf "%*s%s%s%s\n",5,'',$msg0
             ,(defined ${$opts_ref}{dbg0})?' ':'un','defined';                      # Showing that the DebugControl is now observable
      my $msg1 = 'Debug feature dbg1 ';
      printf "%*s%s%s%s\n",5,'',$msg1
             ,(defined ${$opts_ref}{dbg1})?' ':'un','defined';                      # Showing that the DebugControl is now observable
}#sub DebugFeatures


sub   subroutine {
      my ($r)    = ( @_, 'name');                                                   # full, namespace, name
      #my ($space,$name) = split(/::/, (caller(1))[3]);                             # Name of the function which called subroutine
      my @tmp = split(/::/, (caller(1))[3]);                                        # Name of the function which called subroutine
      my $name = pop @tmp;                                                          # Separate  name
      my $namespace = join '::', @tmp;                                              # Separate  namespace
      return    ( $r =~ m/full/ ) ?  (caller(1))[3]                                 #           return package::subname
              : ( $r =~ m/space/) ?  $namespace                                     #           return subroutin name
              : ( $r =~ m/name/ ) ?  $name                                          #           return namespace/package
              : $name;                                                              # default   return subroutin name
}#sub subroutine


sub   debug {
      my    (   $name
            ,   $phase
            ,   $dbg    )   =   @_;

      $phase    //= 'probe';            # default setting !defined
      $dbg      //= 0;                  # Overwrite
      state %holding;                   # holding all debug setting
      my $size = keys %holding;

      printf "     debug(phase=%s, name=%s)\n",$phase, $name if $dbg;              # Need to think how to debug subroutine debug
      if      ( $phase =~ m/set/    ) { # setup debugging feature
         #printf "%*sholding hash has %s entries\n",5,'',$size;
         #printf "%*s%s setting\n",5+4,'',$name;
         $holding{$name} = 1; $size = keys %holding;
         #printf "%*sHolding hash is %s\n",5,'', $size;
      } elsif ( $phase =~ m/probe/  ) { # probe debugging feature
         if ( defined $holding{$name} ) {
             #printf "%*s%s::%s\n",5+4,'',$name,$holding{$name};
             return $holding{$name};
         } else {
             return 0;
         }
      } elsif ( $phase =~ m/debug/  ) {
         printf "%*s%s :: debugging\n",5,'',subroutine('name');
         foreach my $e ( keys %holding) {
             printf "%*s%s::%s\n",5+4,'', $holding{$e}, $e;
         }#foreach
      } else  {                                                                     # do nothin
      }#default
}#sub debug


sub   DebugControl {
      my    (   $opts_ref   )   =   @_;                                             # Input     Command Line Options
                                                                                    # Output    Logging Control of all log files
      my $i = ${$opts_ref}{indent};                                                 # Uniform   indentation
      my $p = ${$opts_ref}{indent_pattern};                                         #           indentation pattern
      my @ulist;                                                                    # unpacked list

      printf "%*s%s()\n",$i,$p,subroutine('name')   if( defined ${$opts_ref}{dbg0} );

      if ( defined ${$opts_ref}{dbg}    ) {
          printf "%*s%s :: %s\n",$i,$p
                                ,'DebugOptions'
                                ,'unpacking'        if( defined ${$opts_ref}{dbg0} );
          foreach my $entry (@{${$opts_ref}{dbg}}   ){                              # Command line packed input list
              printf "%*s%s\n",$i+4,$p,$entry       if( defined ${$opts_ref}{dbg0} );
              my @unpacked = split /,/ ,$entry;                                 
              foreach my $e (@unpacked) {                                           
                  printf "%*s%s +\n",$i+4,$p,$e     if( defined ${$opts_ref}{dbg1} );
                  push (@ulist, $e);
              }#unpack
          }#each entry
          ${$opts_ref}{dbg} = \@ulist;                                              # Unpacked list, stored
          printf "%*s%s :: %s :: %s\n"  ,$i,$p
                                        ,'DebugOptions'
                                        ,'self check'
                                        , $#ulist+1 if( defined ${$opts_ref}{dbg1} );
          foreach my $entry ( @ulist ){
              #printf "%*s%s\n",$i+4,$p,$entry;
              if ($entry =~ m/all/ ) {
                foreach my $e ( @{${$opts_ref}{subs}} ){                            # ALL enabled subroutines
                    printf "%*s%s::%s\n",5,''
                                        ,'set',$e   if( defined ${$opts_ref}{dbg1} );;
                    debug($e,'set',${$opts_ref}{dbg1});
                }#foreach
              }#
              if ( $entry ~~ @{${$opts_ref}{subs}} ) {                              # Selected subroutines
                    printf "%*s%s::%s\n",5,''
                                        ,'set'
                                        ,$entry     if( defined ${$opts_ref}{dbg1} );
                    debug($entry,'set',${$opts_ref}{dbg1});
              }
          }#foreach entry in unpacked list
      }#if dbg is defined
}#sub DebugControl

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

#----------------------------------------------------------------------------
#  End of module
1;
