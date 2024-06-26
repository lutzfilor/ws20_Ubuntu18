#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Simple 'no_plan';

sub     hello_world {
        return  "Hello, World";
}#sub   hello_world

ok ( hello_world() eq "Hello, World");

