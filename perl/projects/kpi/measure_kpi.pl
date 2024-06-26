#!/usr/bin/perl -w
###############################################################################
#
#   Author      Lutz Filor
#               408 807 6915
#
#   Synopsis    Testing Libraries
#
#
#==============================================================================

use strict;
use warnings;

use Switch;
use version; my $VERSION = version->declare('v1.01.12');    # v-string using Perl API

use lib	    "$ENV{PERLPATH}";

#use Application         qw  (   new         );      # Create Application
use Application::CLI    qw  (   new         );      # Create Application
use DS                  qw  (   list_ref    );
use DS::Array           qw  (   list_modules
                                installed_modules
                                size_of
                                maxwidth    );      #   ArrayRef functions
use DS::Hash            qw  (   list_hash   );      #   HashRef functions
use App::Modules        qw  (   get_ModuleSearchpath
                                get_ModulesInstalled
                                get_SymbolTable 
                                display_Symbols
                                unify_symboltable
                                list_unifiedSymbolTable
                                get_all     );      #   Under development

my $list =  [   qw( DS
                    Test::Simple Test::More Application Application::CLI 
                    version POSIX Readonly Term::ANSIColor 
                    Excel::Writer::XLSX Spreadsheet::ParseXLSX
                    File::Find                      ) ];

get_ModuleSearchpath ( );
my  $all    =   get_ModulesInstalled ( "ALL" );                     #   [ArrRef]
my  $lib    =   get_ModulesInstalled ( "$ENV{PERLPATH}");           #   [ArrRef]
my  $lib2   =   get_ModulesInstalled ( "$ENV{PERLPATH}"."/DS");     #   [ArrRef]

list_modules( $lib, 'path'      );
list_modules( $lib, 'namespace' );
list_modules( $lib, 'version'   ); 

printf "     Hi\n";
my $pkg =   list_modules( $lib2, 'package' );                       #   [ArrRef] list of packages
my $pkgs=   list_modules( $lib , 'package' );                       #   [ArrRef] list of packages installed @ $ENV{PERLPATH}
my  $ns =   list_modules( $lib2, 'namespace' );

printf  "\n";
foreach my $nsn ( @{$ns} ) {
    printf "%*s%s %s <<<<<<\n",5,'','namespace  ',$nsn;
}

my $subs = get_all('CODE', $pkg);                                   #   $pkg is ArrRef with all packages of interest (also loaded)

printf  "     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";


foreach my $pkgn ( @{$pkg} ) {
    printf "%5s%s\n",'', $pkgn;
}

printf  "\n";
printf  "%*s%s\n",5,'','Symbol table';
display_Symbols(\%DS::  );                                                      #   Symbol Table Reference
list_hash ( \%INC, { separator => '||' } );                                     #   Installed fullfilename Modules
printf  "\n";
list_ref  ( $subs, { name => '$subs_ref'} );
my $ust =   unify_symboltable ( $pkgs );                                        #   [ArrRef] list of package names
#list_ref  ( $ust, { name => '$unified_SymbolTable'} );
#
printf  "     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
#
list_unifiedSymbolTable( $ust, { indent => 5 } );
exit;
#==============================================================================
# End of Program
