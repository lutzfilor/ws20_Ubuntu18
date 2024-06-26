#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Foo::Bar' ) || print "Bail out!\n";
    use_ok( 'Foo::Bat' ) || print "Bail out!\n";
}

diag( "Testing Foo::Bar $Foo::Bar::VERSION, Perl $], $^X" );
