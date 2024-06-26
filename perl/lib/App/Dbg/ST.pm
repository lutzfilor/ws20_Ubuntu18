package App::Dbg::ST;
#   File            App/Dbg/ST.pm
#
#   Refactored      06/21/2020          
#   Author          Lutz Filor
# 
#   Synopsys        Access SymbolTable (ST) - extracting information
#
#   Warning         Experimental code - no production code !!
#
#                   SymbolTable Access are part of the Application Debugging Framework
#                   App::Dbg::ST::get_FullModulePath( $pathToModuleLibrary )
#                   App::Dbg::ST::get_Namespace     (   )
#                   App::Dbg::ST::get_Symbols       (   )
#

use strict;
use warnings;

use feature 'state';

use DS::Array       qw  /   maxwidth    
                            list_array  /;
use DS::Hash        qw  /   max_key
                            max_value   /;
use App::Dbg        qw  /   subroutine  
                            debug       /; 
#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.02.03");
use experimental 'smartmatch';                                                  #   ~~  Is this needed?

use Exporter qw (import);
use parent 'Exporter';                                                          # replaces base

#our @EXPORT    =    qw  (   );  #dbg functions                                 #   deprecated implicite export

our @EXPORT_OK =    qw  (   get_FullModulePath
                            get_Namespace
                            get_Symbols
                            
                            get_Version
                            get_Subroutines

                            list_Namespace

                            ListModules
                            DebugFeatures
                            $VERSION
                        );  #dbg functions
                            #DebugControl
#
#       getSymbolTableHash
#

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK, 'DebugFeatures' ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     get_FullModulePath {
        my ($MYLIB) = @_;                                                       #   Library path, single location of Module  
        my $lom = [];                                                           #   list of modules
        my $hom = {};                                                           #   hash of modules
        my $w1  = maxwidth( [ values %INC ] );
        my $w   = max_key(\%INC); 
        #printf "%*sSize of keyes :: %s\n",5,'',$w;
        #printf "%*sSize of values:: %s\n",5,'',$w1;
        #printf "%*sName of \$0   :: %s\n",5,'',$0;
        while ( my (($k, $v) ) = each(%INC)) {                                  #   $INC{$k} == $v
            #printf("%*s %*s :: %s\n",5,'',$w1,$INC{$k},$k);                    #   silence loop     #   All loaded Modules
            if ( $INC{$k} =~ m/$MYLIB/xms ) {                                   #   Subdirectory 
                # if ( $INC{$k} =~ m/$ENV{PERLPATH}/xms ) {
                # printf("%*s + %s\n",$w1,$INC{$k}, $k);                        #   Develpoment Vestigal
                push( @{$lom}, $INC{$k});                               
                ${$hom}{$k}  = $INC{$k};
            }# if my lib/ $PERLPATH
        }# while
        return ($lom, $hom);                                                    #   return [list] Full File Name and {hash}={HierachicalFN} => Full File Name
}#sub   get_FullModulePath                                                      #   (from /path/to/lib)

sub     get_Namespace {
        my  ($mh_r) =   @_;                                                     #   module hash w/ PERL module name as KEY
        my $namespace = {};
        #printf "%*sget_Namespace ()\n",5,'';                                   #   development vestigal
        my  $w  =   maxwidth( [ keys %{$mh_r} ] );
        while ( my (($k, $v) ) = each(%{$mh_r})) {
            my $ns = $k;                                                        #   The module name spans the Namespace
            s/\//::/g, s/\.pm// for $ns;                                        #   String conversion to Namespace notation
            #printf  "%*s%*s :: %s\n",5,'',$w,$k,$ns;                           #   Development vestigal
            ${$namespace}{$k} = $ns;
        }# while for all modules
        my  $prog = $0;
            $prog =~ s/\.\///g;                                                 #   Remove the current directory from program
        #printf "%*sName of \$0   :: %s\n",5,'',$prog;                          #   Development vestigal
        ${$namespace}{$prog} = "main";                                          #   Add the program default namespace
        return $namespace;                                                      #   Hash of Namespaces
}#sub   get_Namespace                                                           #   { ./my_script.pl => 'main', DS/Hash.pm => DS::Hash }

sub     Namespace  {
        my  ($mh_r) =   @_;                                                     #   module hash w/ PERL module name as KEY
        my  $ns_l   =   [];
        foreach my $file ( sort keys( %{$mh_r} ))  {
            my $v   =   $$mh_r{$file};
            my $ns  =   ( $file =~ m/\.pl/ ) ? $v : $file;                      #   The module name spans the Namespace
            s/\//::/g, s/\.pm// for $ns;                                        #   String conversion to Namespace notation
            push ( @{$ns_l}, $ns);
        }#foreach namespace
        return $ns_l;
}#sub   Namespace

sub     get_Version {
        my  ($mh_r) =   @_;                                                     #   Namespace HashRef $file =>  fullname App.pm => /home/lutz/ws/perl/lib/App.pm
        my  $info   =   [];                                                     #   return datastructure [table of columns]
        my  $i  =   5;
        my  $p  =   '';
        my  $w  =   max_key     ( $mh_r );
        my  $x  =   max_value   ( $mh_r );
        my  $y  =   maxwidth    ( Namespace($mh_r));
        my  $z  =   8;
        my  $sp1=   [];
        my  $sp2=   [];
        my  $sp3=   [];
        my  $sp4=   [];
        printf  "\n";
        printf  "%*s%s\n",$i,$p,'='x(13+$w+$x+$y+$z);
        printf  "%*s| %*s | %*s | %*s | %*s |\n"
                ,$i,$p,-$w,'Filename',-$x,'Fullpath',-$y,'Namespace',-$z,'Version';
        printf  "%*s%s\n",$i,$p,'='x(13+$w+$x+$y+$z);
        foreach my $file ( sort keys( %{$mh_r} ))  {
            #my $ver =   ${*{"${$ns}::VERSION"}};
            my $v   =   $$mh_r{$file};
            my $ns  =   ( $file =~ m/\.pl/ ) ? $v : $file;                      #   The module name spans the Namespace
            s/\//::/g, s/\.pm// for $ns;                                        #   String conversion to Namespace notation
            no strict;
            my $ver = get_typeglobslot( $ns,'VERSION','SCALAR' );
            printf  "%*s| %*s | %*s | %*s | %*s |\n"
                    ,$i,$p,-$w,$file,-$x,$v,-$y,$ns,-$z,$ver;
        }#foreach files/modules
        printf  "%*s%s\n",$i,$p,'='x(13+$w+$x+$y+$z);
}#sub   get_Version

sub     get_Subroutines {
        my  ($mh_r) =   @_;                                                     #   Namespace HashRef $file =>  fullname App.pm => /home/lutz/ws/perl/lib/App.pm
        my  $list   =   [];                                                     #   List of subroutines
        my  $HshL   =   {};                                                     #   Hash of subroutines and Namespaces
        #printf  "\n%5s%s()\n",'','get_Subroutines';# $debug;
        #foreach my $file ( sort { "\L$a" cmp "\L$b" } keys ( %{$nsh_r} )) {
        foreach my $file ( sort { "\L$a" cmp "\L$b" } keys ( %{$mh_r} )) {
            #printf "%5s%s >>", '', $file;
            my $v   =   $$mh_r{$file};
            my $ns  =   ( $file =~ m/\.pl/ ) ? $v : $file;                      #   The module name spans the Namespace
            s/\//::/g, s/\.pm// for $ns;                                        #   String conversion to Namespace notation
            no strict;
            push  ( @{$list}, @{get_globtypes($ns,'CODE')} );
            foreach my $sub ( @{get_globtypes($ns,'CODE')} ) {
                $$HshL{$sub} = $ns;
            }
    ###     #getSymbolTableHash($packagename);
    ###     push ( @{$subs}, @{get_Symbols($packagename,'CODE')} );
    ###     #getSymbolTableHash('Application::Constants');
    ###     #getSymbolTableHash('Dbg');
    ###     #getSymbolTableHash('DS');
    ###     #last if ( $i > 2 );
    ###     $i++;
        }# for each module file
        #printf "%5s%s\n",'','get_Subroutines() ... done';                      #   debugging
        return ( $list, $HshL );                                                #   [ArrRef],{HshRef} of subroutine names
}#sub   get_Subroutines

sub     get_globtypes   {
        my  (   $ns                                                             #   Namespace, package name
            ,   $type   )   =   @_;                                             #   SCALAR, CODE, ARRAY, HASH
        my  $set    =   [];                                                     #   list/container for all SYMBOL of one TYPE
        my  $count  =   0;                                                      #   Development vestigal - What is this purpose of this counter ??
        my  $namespace  =   $ns;                                                #   make it readable
        no strict;                                                              #   Allow string references !!
        local *stash = *{"${namespace}::"};                                     #   (ST) System Table "Hash" Reference of Namespace::
        foreach my $symbol ( sort { "\L$a" cmp "\L$b" } keys (%{*stash})) { 
            my  $GLOB   =   ${*stash}{$symbol};
            if  ( ref($GLOB) eq $type ) {                                       #   main namespace
                push( @{$set}, $symbol);
                $count++;                                                       #   Development vestigal
            } else {                                                            #   modules
                if ( defined(${*{$GLOB}{SCALAR}})  ) { 
                    if ( $type eq 'SCALAR' ) {
                        push( @{$set}, $symbol);
                        $count++;
                    }#Right type
                } else { 
                    if ( defined( *{$GLOB}{$type} )) {
                        push( @{$set}, $symbol);
                        $count++;                                               #   Development vestigal
                    }#Right type
                }
            }
        }#for all symbols
        #printf  "%s :: %s\n",$count,$type;                                     #   Development vestigal
        return  $set;                                                           #   return set of SYMBOLS [$ArrReg]
}#sub   get_globtypes

sub     get_typeglobslot    {
        my  (   $ns
            ,   $sym
            ,   $slot   )   =   @_;                                             #   SCALAR, CODE, ARRAY, HASH
        no strict;                                                              #   Allow string references !!
        my  $namespace  =   $ns;                                                #   
        local *stash = *{"${namespace}::"};                                     #   System Table "Hash" Reference of Namespace::
        while (my($symbol, $GLOB) =  each (%{*stash})) {                        #   For all Typeglobs/ entries for each symbol in Symbol table
            if ( $symbol eq $sym ) {
                if ( ref($GLOB) ) {
                    if ( ref ( $GLOB )  eq  'SCALAR' ) { 
                        return ${*{$GLOB}{SCALAR}}; 
                    }#if SCALAR 
                    # if ( ref ( $GLOB )  eq  'ARRAY'  ) { return ; }
                    # if ( ref ( $GLOB )  eq  'HASH'   ) { return ; }
                    # if ( ref ( $GLOB )  eq  'CODE'   ) { return ; }
                    # if ( ref ( $GLOB )  eq  'FORMAT' ) { return ; }
                    # if ( ref ( $GLOB )  eq  'IO'     ) { return ; }
                } else {
                    if ( defined(${*{$GLOB}{SCALAR}})  ) { 
                        return ${*{$GLOB}{SCALAR}}; 
                    }#if SCALAR
                    # if ( defined   *{$GLOB}{ARRAY}   ) { return ; }
                    # if ( defined   *{$GLOB}{HASH}    ) { return ; }
                    # if ( defined   *{$GLOB}{CODE}    ) { return ; }
                    # if ( defined   *{$GLOB}{FORMAT}  ) { return ; }
                    # if ( defined   *{$GLOB}{IO}      ) { return ; }
                }
                #$slot_ref    =  *{$typeglob}{$slot}; 
            }#if found 
        }#
        #return  $slot_ref;
}#sub   get_globslot


### sub     get_Symbols  {
###         my  ($packagename, $slot)    =   @_;
###             $slot   //= 'CODE';                                                 #   Default symbol to select
###         my  $n  =   subroutine('name');
###         my  $l  =   [];
###         #if  ( debug($n) ) {
###             printf "%*s%s( %s, %s )\n",5,'',$n,$slot,$packagename;
###         #}#  debug
###         no strict;                                                              #   Allow string references !!
###         local *stash = *{"${packagename}::"};                                   #   System Table Hash
###         while (my($symbol, $globEntry) =  each (%{*stash})) {                   #   For all Typeglobs/ entries for each symbol in Symbol table
###         #while (my($symbol, $globEntry) = sort each (%{*stash})) {               #   For all Typeglobs/ entries for each symbol in Symbol table
###         #while (my($symbol, $globEntry) = sort { "\L$a" cmp "\L$b" } each (%{*stash})) {                    #   For all Typeglobs/ entries for each symbol in Symbol table
###         #while ( my $symbol = sort { "\L$a" cmp "\L$b" } keys (%{*stash}) ) {   #   For all Typeglobs/ entries for each symbol in Symbol table
###             #my $globEntry   =   ${*stash}{$symbol};
###             my $pkg     = *{$globEntry}{PACKAGE};
###             my $idt     = *{$globEntry}{NAME};
###             my $symbol  = sprintf "%s::%s",$pkg,$idt;
###             printf  "%5s<%s>  %s\n", '',$symbol, ref *{$globEntry};                 #   Development vestigal
###             if ( defined (${*{$globEntry}{SCALAR}} ) && ( 'SCALAR' eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1"; 
###             if ( defined (  *{$globEntry}{ARRAY}   ) && ( 'ARRAY'  eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
###             if ( defined (  *{$globEntry}{HASH}    ) && ( 'HASH'   eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
###             if ( defined (  *{$globEntry}{CODE}    ) && ( 'CODE'   eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
###             if ( defined (  *{$globEntry}{FORMAT}  ) && ( 'FORMAT' eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
###             if ( defined (  *{$globEntry}{IO}      ) && ( 'IO'     eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
###             if ( defined (  *{$globEntry}{GLOB}    ) && ( 'GLOB'   eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
###             #printf  "\n";
###         }#  while 
###         return $l;                                                      #   list of symbols
### }#sub   get_Symbols
### 


sub     get_Symbols  {
        my  ($packagename, $slot)    =   @_;
            $slot   //= 'CODE';                                                 #   Default symbol to select
        my  $n  =   subroutine('name');
        my  $l  =   [];
        #if  ( debug($n) ) {
            printf "%*s%s( %s, %s )\n",5,'',$n,$slot,$packagename;
        #}#  debug
        no strict;                                                              #   Allow string references !!
        local *stash = *{"${packagename}::"};                                   #   System Table Hash
        while (my($symbol, $globEntry) =  each (%{*stash})) {                   #   For all Typeglobs/ entries for each symbol in Symbol table
        #while (my($symbol, $globEntry) = sort each (%{*stash})) {               #   For all Typeglobs/ entries for each symbol in Symbol table
        #while (my($symbol, $globEntry) = sort { "\L$a" cmp "\L$b" } each (%{*stash})) {                    #   For all Typeglobs/ entries for each symbol in Symbol table
        #while ( my $symbol = sort { "\L$a" cmp "\L$b" } keys (%{*stash}) ) {   #   For all Typeglobs/ entries for each symbol in Symbol table
            #my $globEntry   =   ${*stash}{$symbol};
            #### if ( ref *{$globEntry} eq 'GLOB' ) {
            ####     printf  " %s", 'GLOB<== ';                                #   Debugging
            #### } else {
            ####     if ( defined  *{$globEntry}{HASH} ) {
            ####         printf  " is a HASH\n";
            ####     } else {
            ####         printf  " %s | %s :: unknown\n", ref $globEntry, ref *{$globEntry};
            ####     }
            #### }
            printf "%5s%s ",'',$symbol;
            unless ( defined (  *{$globEntry}{GLOB}    ) ) {
                printf  "%5s%s | No GLOB", '',$globEntry;                       #   Debugging, what is it ??
            } else {
                printf "is a GLOB\n";
            }
            next if ( $symbol eq '*main::^');                                   #   Symbol exception !!!
            next if ( $symbol eq '*main::|');                                   #   Excluded
            next if ( $symbol eq '*main::.');                                   #   Excluded
            next if ( $symbol eq '*main::@');                                   #   Excluded
            next if ( $symbol eq '*main::=');                                   #   Excluded
            next if ( $symbol eq '*main::re');                                  #   Core Class
            next if ( $symbol eq '*main::ENV');
            next if ( $symbol eq '*main::VMS');
            next if ( $symbol eq '*main::filter');
            next if ( $symbol eq '*main::Filter');
            next if ( $symbol eq '*main::version');
            next if ( $symbol eq '*main::storable');
            next if ( $symbol eq '*main::XSLoader');
            next if ( $symbol eq '*main::UNIVERSAL');                           #   Symbol exception !!! Base Class
            next if ( $symbol eq '*main::deprecated');                          #   Symbol exception !!! Core class
            next if ( $symbol eq '*main::SizeOfHashRef');                       #   
            #my $pkg     = *{$globEntry}{PACKAGE};
            #my $idt     = *{$globEntry}{NAME};
            #my $symbol  = sprintf "%s::%s",$pkg,$idt;
            printf  "%5s<%s>  %s\n", '',$symbol, ref *{$globEntry};             #   Development vestigal
            if ( defined (${*{$globEntry}{SCALAR}} ) && ( 'SCALAR' eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1"; 
            if ( defined (  *{$globEntry}{ARRAY}   ) && ( 'ARRAY'  eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
            if ( defined (  *{$globEntry}{HASH}    ) && ( 'HASH'   eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
            if ( defined (  *{$globEntry}{CODE}    ) && ( 'CODE'   eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
            if ( defined (  *{$globEntry}{FORMAT}  ) && ( 'FORMAT' eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
            if ( defined (  *{$globEntry}{IO}      ) && ( 'IO'     eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
            if ( defined (  *{$globEntry}{GLOB}    ) && ( 'GLOB'   eq $slot) ) { push ( @{$l}, $symbol );  }    # printf ", +1";
            #printf  "\n";
        }#  while 
        return $l;                                                              #   list of symbols
}#sub   get_Symbols

sub     list_Namespace  {
        my  ( $hoNS )  =   @_;                                                  #   # Hash of Namespace
        my  $n = subroutine('name');                                                # name of subroutine
        
        my  $i  =   5;
        my  $p  =   '';
        my  $s1 =   max_key   ( $hoNS );
        my  $s2 =   max_value ( $hoNS );
        my  $s3 =   2;                                                          #   Size
        my  $s4 =   4;                                                          #   SYMBOL
        my  $s5 =   28;                                                         #   Symbol
        my  $s6 =   42;
        my  $s1h=   'File name';
        my  $s2h=   'Name space';
        my  $s3h=   'Size';
        my  $s4h=   'SYMBOL';
        my  $s5h=   'symbol';
        my  $s6h=   'typeglob';
        my  $s7h=   'SLR';
        my  $s8h=   'ARY';
        my  $s9h=   'HSH';
        my $s10h=   'CDE';
        my $s11h=   'FRT';
        my $s12h=   ' IO';

        printf  "\n%*s%s()\n",5,'',$n;
        printf  "%*s| %*s | %*s |%s|%s| <%*s>%*s | %*s |%s|%s|%s|%s|%s|%s|\n"
                ,$i,$p,-$s1,$s1h,-$s2,$s2h,$s3h,$s4h,6,$s5h,9-$s5,$p
                ,-$s6,$s6h,$s7h,$s8h,$s9h,$s10h,$s11h,$s12h;
        printf  "%*s%s\n",$i,$p,'='x($s1+$s2+$s3+$s4+$s5+18+$s6+6*4);
        foreach my $k ( sort { "\L$a" cmp "\L$b" } keys %{$hoNS} ) {            #   $k == file name
            my  $v  =   $$hoNS{$k};                                             #   $v == name space
            no strict;                                                          #   Allow string references !!
            my  $namespace  =   $v;                                             #   
            local *stash = *{"${namespace}::"};                                 #   System Table "Hash" Reference of Namespace::
            while (my($symbol, $GLOB) =  each (%{*stash})) {                    #   For all Typeglobs/ entries for each symbol in Symbol table
                my  $s  =   length $symbol;
                my  $p5 =   $s5-$s-3;                                           #   Padding
                my  $p6 =   $s6;                                                #   Padding
                my  $va =   ( $s == 1 ) ? ord ($symbol) : '--';
                    $p5+=   padding( $symbol );
                    $p6+=   padding( $symbol );
                my  $SYM=   ( ord($symbol) == 12) ? '': $symbol;                #   \v exception            ???
                #my  $glob=  ( ord($symbol) == 12) ? chop $GLOB
                #        :  $GLOB;                                              #   \v exception
                printf  "%*s| %*s | %*s | %*s | %*s | <%s>%*s | %*s |"
                        ,$i,$p,-$s1,$k,-$s2,$v,$s3,$s,$s4,$va,$SYM
                        ,$p5,$p,-$p6,$GLOB;
                my ($sl1,$sl2,$sl3,$sl4,$sl5,$sl6);
                if ( ref($GLOB) ) {
                    #printf " %-8s |\n", ref($GLOB);                            #   Development vestigal
                    $sl1 = ( ref ( $GLOB )  eq  'SCALAR' ) ?' X ':' - '; 
                    $sl2 = ( ref ( $GLOB )  eq  'ARRAY'  ) ?' X ':' - ';
                    $sl3 = ( ref ( $GLOB )  eq  'HASH'   ) ?' X ':' - ';
                    $sl4 = ( ref ( $GLOB )  eq  'CODE'   ) ?' X ':' - ';
                    $sl5 = ( ref ( $GLOB )  eq  'FORMAT' ) ?' X ':' - ';
                    $sl6 = ( ref ( $GLOB )  eq  'IO'     ) ?' X ':' - ';
                    ### printf "%s|%s|%s|%s|%s|%s|\n",
                    ###    $sl1,$sl2,$sl3,$sl4,$sl5,$sl6;
                } else {
                    ### foreach my $slot ( keys %{$GLOB} ) {
                    ###     printf " %-6s |", $slot;
                    ### }
                    ### printf  "\n";
                    $sl1 = ( defined ${*{$GLOB}{SCALAR}} ) ?' X ':' - '; 
                    $sl2 = ( defined   *{$GLOB}{ARRAY}   ) ?' X ':' - ';
                    $sl3 = ( defined   *{$GLOB}{HASH}    ) ?' X ':' - ';
                    $sl4 = ( defined   *{$GLOB}{CODE}    ) ?' X ':' - ';
                    $sl5 = ( defined   *{$GLOB}{FORMAT}  ) ?' X ':' - ';
                    $sl6 = ( defined   *{$GLOB}{IO}      ) ?' X ':' - ';
                }
                printf  "%s|%s|%s|%s|%s|%s|\n",
                        $sl1,$sl2,$sl3,$sl4,$sl5,$sl6;
                ### } else {
                ###     if      ( defined *{GLOB}{HASH} ) {
                ###         printf " %-8s |",'HASH';
                ###     } elsif ( %{$GLOB} ) {
                ###         printf " %-8s |",'TYPEGLOB';
                ###     } elsif ( @{$GLOB} ) {
                ###         printf " %-8s |",'ARRAY';
                ###     } elsif ( defined &{$GLOB} ){
                ###         printf " %-8s |",'CODE';
                ###     } elsif ( defined $GLOB{IO} ) {
                ###         printf " %-8s |",'IO-';
                ###     } elsif ( defined *{$GLOB}{IO} ) {
                ###         printf " %-8s |",'IO';
                ###     } elsif ( defined ${*{$GLOB}{SCALAR}} ) {
                ###         printf " %-8s |",'SCALAR';
                ###     } elsif ( defined *{GLOB}{FORMAT} ) {
                ###         printf " %-8s |",'FORMAT'
                ###     } elsif ( defined *{$GLOB}{GLOB} ) {
                ###         printf " %-8s |",'GLOB';
                ###     } else {
                ###         #   unknown
                ###     }
                ###     printf "\n";
                ### }
                #my  $slr=   ( defined ${ *{$GLOB}{SCALAR}} )?' X ':' - ';
                #my  $arr=   ( defined ${ *{$GLOB}{ARRAY}}  )?' X ':' - ';
                #my  $hsh=   ( defined ${ *{$GLOB}{HASH}}   )?' X ':' - ';
                #my  $cde=   ( defined ${ *{$GLOB}{CODE}}   )?' X ':' - ';
                #printf  "%*s| %*s | %*s | %*s | %*s | <%s>%*s | %*s |%s|%s|%s|%s|\n"
                #        ,$i,$p,-$s1,$k,-$s2,$v,$s3,$s,$s4,$va,$SYM
                #        ,$p5,$p,-$p6,$GLOB,$slr,$arr,$hsh,$cde;
            }
        }#foreach entry
        return;
}#sub   list_Namespace

sub     getListofSubroutines {
        my  ( $ModuleNames ) = @_;                                              #   {$HashRef} - Reference to Module Names
        my  $w  = max_key($ModuleNames);
        my  $n  = subroutine('name');
        my  $l  =   [];
        #if ( debug($n) ) {
            printf "%*s%s()\n",5,'',$n;
            printf "%*s%s %5s\n",5,'','Size of HashRef  ',SizeOfHashRef($ModuleNames);
            printf "%*s%s %5s\n",5,'','column width key ',$w;
            #printf "%*s%s %5s\n",5,'','column width val ',max_value($ModuleNames);
            #printf "%*s%s %5s\n",5,'','column width max ',determineWidth($ModuleNames);
        #}#debug
        my @l   =   sort { "\L$a" cmp "\L$b" } keys (%{$ModuleNames}); 
        #while ( my ($k,$v) = sort each (%{$ModuleNames}) ) {
        ### foreach my $k ( @l ) {
        ###     my  $v  =   $$ModuleNames{$k};
        ###     #printf "%*s%s\n",$w,'',$v;
        ###     #printf "%*s%*s  %s\n",5,'',-$w,$v,$k;
        ###     printf "%*s%*s  %s\n",5,'',-$w,$k,$v;
        ###     #getSymbolTableHash($v);
        ### }# while
        printf "\n";
        foreach my $k ( @l ) {
            my  $v  =   $$ModuleNames{$k};
            printf "%*s%*s  %s\n",5,'',-$w,$k,$v;
            #push( @{$l}, getSymbolTableHash($v) );
            #push( @{$l}, getSymbols($v) );                                     #   07-05-2020 
            push( @{$l}, get_Symbols($v) );
            # exit();
            #printf "\n";
        }# while
        return $l;                                                              #   List of Subroutines
}#sub   getListofSubroutines


sub     ListModules {                                                           #   List Module     
        no strict;                                                              #   access $VERSION by symbolic reference
        print map {
            s!/!::!g; 
            s!.pm$!!; 
            sprintf "%-20s %s\n", $_, ${"${_}::VERSION"} 
        } sort keys %INC; 
}#sub   ListModules


#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

sub     padding {                                                               #   Unprintable character
        my  ( $symbol ) =   @_;
        return      ( ord($symbol) ==  8) ? 2                                   #   
                :   ( ord($symbol) ==  5) ? 1                                   #
                :   ( ord($symbol) == 12) ? 1                                   #
                :   ( ord($symbol) == 15) ? 1 : 0;                              #   Padding exceptions
}#sub   padding

sub     globslot_is_scalar  {
        my  (   $slot_ref   )   =   @_;
        if ( ref $slot_ref) {
            printf  "%*s%s%s+\n",5,'','Slotref', ref $slot_ref;
        }# 
        #return  ( ref $slot_ref eq 'SCALAR')? $TRUE: $FALSE;
}#sub   globslot_is_scalar


sub     globslot_is_array   {
}#sub   globslot_is_array


sub     globslot_is_hash    {
        my  (   $slot_ref   )   =   @_;
        #local *slot = *{$slot_ref};                                            #   Do I need a local *slot == glob_reference pointer
        if ( ref $slot_ref) {
            printf  "%*s%s%s\n",5,'','Slotref', ref $slot_ref;
        }
        #return  ( ref $slot_ref eq 'HASH')? $TRUE: $FALSE;
}#sub   globslot_is_hash


sub     globslot_is_code    {
        my  (   $slot_ref   )   =   @_;
        if ( defined $slot_ref) {
            printf  "%*s%s%s\n",5,'','Slotref', ref $slot_ref;
        }
        #return  ( ref $slot_ref eq 'CODE')? $TRUE: $FALSE;
}#sub   globslot_is_code


sub     globslot_is_glob    {
}#sub   globslot_is_glob

sub     getSubNames {
        my  (   $nsh_r  )   =   @_;
        my $subs    =   [];
        while ( my ($k, $packagename) = each ( %{$nsh_r} )) {
        }#while
        return $subs;
}#sub   getSubNames

sub     getSymbolTableHash {
        my  (   $packagename    )   =   @_;
        my $n = subroutine('name');
        #if ( debug($n) ) {
            printf "%*s%s( %s )\n",5,'',$n,$packagename;
            #printf "%26s %s\n",'',$packagename;
        #} #debug
        no strict;
        #my *stash = *{"${packagename}::"};                                     #   System Table Hash   !!! This doesn't work !!!
        local *stash = *{"${packagename}::"};                                   #   System Table Hash
        ## while (my($symbol, $globEntry) = each ( %stash )) {
        my $kw = maxwidth([ keys   (%{*stash}) ]);
        my $vw = maxwidth([ values (%{*stash}) ]);
        my $entries =   0;
        while (my($symbol, $globEntry) = each (%{*stash})) {                    #   $symbol     VERSION
            #printf "%*s%*s >>>> %*s\n",5,'',$vw,$globEntry,$kw,$symbol;        #   $globEntry  *DS::Hash::VERSION
            my $pkg = *{$globEntry}{PACKAGE};                                   #   
            my $idt = *{$globEntry}{NAME};                                      #   
            #printf "%*s%s::%s ",47,'',$pkg,$idt;
            #printf  "%*s%s::%s ",5,'',$pkg,$idt;
            my $e   = sprintf "%s::%s",$pkg,$idt;
            printf  "%*s%s",5,'',$e;
            printf  ", %s",'SCALAR' if defined (${*{$globEntry}{SCALAR}});
            printf  ", %s",'ARRAY'  if defined (  *{$globEntry}{ARRAY}  );
            printf  ", %s",'HASH'   if defined (  *{$globEntry}{HASH}   );
            printf  ", %s",'CODE'   if defined (  *{$globEntry}{CODE}   );
            printf  ", %s",'FORMAT' if defined (  *{$globEntry}{FORMAT} );
            printf  ", %s",'IO'     if defined (  *{$globEntry}{IO}     );
            printf  ", %s",'GLOB'   if defined (  *{$globEntry}{GLOB}   );
            ####    printf "%*s%s::%s !!",30,'',$pkg,$idt;
            ####    #if ( ref (*{$globEnt} =~ m/\bCODE\b/ )) {
            ####    #    printf "%s", 'subroutine';
            ####    #}#
            printf "\n";
            $entry++ if defined (${*{$globEntry}{SCALAR}});
            $entry++ if defined (  *{$globEntry}{ARRAY}  );
            $entry++ if defined (  *{$globEntry}{HASH}   );
            $entry++ if defined (  *{$globEntry}{CODE}   );
            $entry++ if defined (  *{$globEntry}{FORMAT} );
            $entry++ if defined (  *{$globEntry}{IO}     );
            $entry++ if defined (  *{$globEntry}{GLOB}   );
            ####    globslot_is_scalar(\${$globEntry});
            ####    globslot_is_scalar(${*{$globEntry}{SCALAR}});
            ####    #globslot_is_hash(\%{*{$globEntry}{HASH}});
            ####    globslot_is_hash(*{$globEntry});
            ####    globslot_is_code(\%{$globEntry});
        }#while
        printf "%*s%s :: %s\n",5,'','#Symbols', $entry;
}#sub   getSymbolTableHash


#----------------------------------------------------------------------------
#       End of module App::Dbg::ST
1;
