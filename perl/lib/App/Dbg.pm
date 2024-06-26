package App::Dbg;
# File          App/Dbg.pm
#
# Refactored    2019/01/17          
#               2020/10/18
#
# Author        Lutz Filor
# 
# Synopsys      Dbg::debug()            utility controling verbosity subs from the command line
#               Dbg::debug('',{%debug}) initialize static associated hash
#               Dbg::debug($name)       return true/false of selected --dbg=subroutine,list 
#
#               Dbg::subroutine()       return the name of the caller subroutine
#               Dbg::subroutine('full')
#               Dbg::subroutine('name')
#               Dbg::subroutine('namespace')
#
#               Add a new static debug feature

use strict;
use warnings;
use feature 'state';

#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v2.01.10");

use Exporter qw (import);
use parent 'Exporter';                                                          #   replaces base

#our @EXPORT    = qw(               );                                          #   implicite export

our @EXPORT_OK = qw(    subroutine
                        debug
                        $VERSION    );                                          #   explicite export dbg functions

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
# C O N S T A N T S

use App::Const  qw( :ALL );                                                     #   Prove of concept, of external defined Constants
#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     subroutine {
        my ($r)    =  @_;                                                       #   full, namespace, name
        #my ($r)    = ( @_, 'name');                                            #   full, namespace, name
        #my ($space,$name) = split(/::/, (caller(1))[3]);                       #   Name of the function which called subroutine
        my @tmp = split(/::/, (caller(1))[3]);                                  #   Name of the function which called subroutine
        my $name      = pop @tmp;                                               #   Separate  name
        my $namespace = join '::', @tmp;                                        #   Separate  namespace
        return    ( $r =~ m/full/ ) ?  (caller(1))[3]                           #             return package::subname fully qualified
                : ( $r =~ m/space/) ?  $namespace                               #             return subroutin name
                : ( $r =~ m/name/ ) ?  $name                                    #             return namespace/package
                : $name;                                                        #   default   return subroutin name
}#sub   subroutine


sub     debug   {
        my  (   $name                                                           #   $subroutine name
            ,   $self   )   =   @_;                                             #   {$self} application storage
        state   %debug  =   %{$$self{debug}};                                   #   initialize static variable
        return ( defined $debug{$name} )? $debug{$name} :  $FALSE;
}#sub   debug



#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

sub     ListModules {                                                           # List Module     
        no strict;                                                              # access $VERSION by symbolic reference
        print map {
            s!/!::!g; 
            s!.pm$!!; 
            sprintf "%-20s %s\n", $_, ${"${_}::VERSION"} 
        } sort keys %INC; 
}#sub   ListModules

#----------------------------------------------------------------------------
#  End of module
1;
