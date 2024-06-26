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
use lib				"$ENV{PERLPATH}";

#use Application         qw  (   new         );      # Create Application
use Application::CLI    qw  (   new         );      # Create Application
#use DS::Array           qw  (    

my $list = [ qw(    DS
                    Test::Simple Test::More Application Application::CLI 
                    version POSIX Readonly Term::ANSIColor 
                    Excel::Writer::XLSX Spreadsheet::ParseXLSX
                    File::Find                      
                    Module::Starter                                         ) ];
my $resp = [];

printf "\n";
printf "%*s%s\n",5,'','Library search pathes :: ';
foreach my $path ( @INC ) {
    printf "%*s%s\n",5,'',$path;
}# for all search pathes
printf "\n";

foreach my $module ( @{$list} ) {
    my $mod_available    =  `perldoc -lm "$module"`;
    push    ( @{$resp}, $mod_available ) if $mod_available;
}# for all modules

printf "\n";
foreach my $module ( @{$resp} ) {
    printf "%*s%s",5,'',$module;
}# for all modules

printf "\n";
my $nkeys = keys %env;
printf "%*s%s %s",5,'','Number of loaded modules :: ',$nkeys;
foreach my $loaded ( keys %env) {
    printf "%*s%s",5,'',$loaded;
}# for all loaded module
printf "\n%*s%s\n\n",5,'','... perl module testing done';


printf "%*s%s %s\n",5,'','Number of loaded modules :: ',scalar keys %INC;
#my $w = 
foreach my $entry ( keys %INC ) {
    printf "%*s%s\n",5,'',$entry;
}# for all loaded modules
#==============================================================================
# End of Program
