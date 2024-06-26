#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Simple    tests   =>  1;

sub     hello_world {
        return  "Hello, World";
}#sub   hello_world

ok ( hello_world() eq "Hello, World");

