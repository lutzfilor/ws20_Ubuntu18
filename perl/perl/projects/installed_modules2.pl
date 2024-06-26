#!/usr/bin/perl
###############################################################################
#
#   Author      Lutz Filor
#               408 807 6915
#
#   Synopsis    Testing Libraries
#
#
#==============================================================================
my $list = [ qw( Test::Simple Test::More ) ];
my $resp = [];

foreach my $module ( @{$list} ) {
    my $mod_available    =  `perldoc -lm "$module"`;
    push    ( @{$resp}, $mod_available );
}# for all modules

foreach my $module ( @{$resp} ) {
    printf "\n",5,'','',
}# for all modules
printf "%*s%s\n\n",5,'','... perl module testing done';
#==============================================================================
# End of Program