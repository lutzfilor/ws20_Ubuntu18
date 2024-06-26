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
my @list = qw( Test::Simple Test::More );

foreach my $module (@list) {
    my $resp    =  `perldoc -lm "$module"`;
    push    ( @{$response}, $resp);
}# for all modules
printf "%*s%s\n\n",5,'','... perl module testing done';
#==============================================================================
# End of Program
