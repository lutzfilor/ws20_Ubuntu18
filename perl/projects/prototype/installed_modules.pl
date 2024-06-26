#!/usr/bin/perl -W
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
#use version; my $VERSION = version->declare('v1.01.01');                        # v-string using Perl API

my @list = qw( Test::Simple Test::More );
my $response    = [];

foreach my $module (@list) {
    my $resp    =  `perldoc -lm "$module"`;
    push    ( @{$response}, $resp);
}# for all modules
printf "%*s%s\n\n",5,'','... perl module testing done';
#==============================================================================
# End of Program
