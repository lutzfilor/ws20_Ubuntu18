#!/usr/bin/perl -w
#use strict;
package DUMPVAR;
sub dumpvar {
    my ($packageName) = @_;
    local (*alias);                         # a local typeglob
    no strict "refs";
    no strict "vars";
    # We want to get access to the stash 
    # corresponding to the package name
    *stash = *{"${packageName}::"};         # Now %stash is the symbol table
    $, = " ";                               # Output separator for print
    # Iterate through the symbol table, 
    # which contains glob values
    # indexed by symbol names.
    while (($varName, $globValue) = each %stash) {
        print "$varName ============================= \n";
        *alias = $globValue;
        if (defined ($alias)) {
            print "\t \$$varName $alias \n";
        } 
        #if (defined (@alias)) {        #  
        if ( @alias ) {
            print "\t \@$varName @alias \n";
        } 
        #if (defined (%alias)) {
        if ( %alias ) {
            print "\t \%$varName ",%alias," \n";
        }
     }
}

package XX;
#no strict "vars";
#no strict "refs";
#no strict "subs";
$x = 10;
@y = (1,3,4);
%z = (1,2,3,4, 5, 6);
$z = 300;
$x = $x + 10;
push ( @y, 5);
DUMPVAR::dumpvar("XX"); 
