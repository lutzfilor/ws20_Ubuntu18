package App::Modules;
#
# File          ~/ws/perl/lib/App.pm
#               
# Created       03/155/2020
# Author        Lutz Filor
# 
# Synopsys      App::Modules::get_Symboltable()
#               App::Modules::get_all('CODE', $PackageArrRef )
# 
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;                                                                   # Required for CONSTANTS
use Switch;

use lib	"$ENV{PERLPATH}";                                                       # Add Include path to @INC

use Dbg         qw  /   debug subroutine    /;
use DS          qw  /   list_ref    /;                                          # Data structure
use DS::Array   qw  /   size_of
                        maxwidth    /;

#---------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION = version->declare("v1.01.08");

use Exporter qw (import);
use parent 'Exporter';                                                          # replaces base; base is deprecated


our @EXPORT    =    qw  (   );                                                  #   implicite import, not recommeded
                      
our @EXPORT_OK =    qw  (   get_ModuleSearchpath
                            get_ModulesInstalled
                            get_SymbolTable
                            display_Symbols
                            unify_symboltable
                            list_unifiedSymbolTable
                            get_all
                        );                                                      #   explicite import, recommended

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#Readonly my  $FAIL  =>   1;                                                    # default setting, Success must be determinated
#Readonly my  $PASS  =>   0;                                                    # PASS value ZERO as in ZERO failure count
#Readonly my  $INIT  =>   0;                                                    # Initialize to ZERO

use App::Const  qw( :ALL );                                                     #   Prove of concept, of external defined Constants


#----------------------------------------------------------------------------
#       V A R I A B L E S 

use vars            qw  (   *ENTRY *STASH  );

#----------------------------------------------------------------------------
#       S U B R O U T I N S


sub     get_ModuleSearchpath {                                                  #   Special Variable @INC
        printf "\n";                                        
        printf "%*s%s\n",5,'','Library search pathes :: ';
        foreach my $path ( @INC ) {                                             #   List of all search path lookinf doe INCluded modules
            printf "%*s%s\n",5,'',$path;
        }# for all search pathes
        printf "\n";
        return [ @INC ];                                                        #   return an [arrRef] to list of INCluded
}#sub   get_ModuleSearchpathes


sub     get_ModulesInstalled   {                                                #   Special Variable %INC
        my  (   $p )   =   @_;                                                  #   path to lib
        my  $n  =   size_of ( [( keys %INC )] );                                #   number of installed module
        my  $w  =   maxwidth( [( keys %INC )] );                                #   longest module .pm filename
        my  $m  =   [];                                                         #   modules installed
        printf "\n%*s%s %s\n",5,'','Library access path      :: ',$p;
        printf "%*s%s %s\n",5,''  ,'Number of loaded modules :: ',$n;
        foreach my $loaded ( keys %INC) {               #   loaded module
            #my $h = ($INC{$loaded} =~ $p) ? '+' : '-';
            #printf "%*s%*s :: %s %s\n",5,'',$w,$loaded, $h, $INC{$loaded};
            switch ( $p )    {                          #   path to installed perl modules .pm
                case m/\bALL\b/ { push ( @{$m}, $loaded) }
                else            { push ( @{$m}, $loaded) if ( $INC{$loaded} =~ $p ); }
            }#end switch
        }# for all loaded module
        return $m;                                                              #   local/customized distributed modules
}#sub   get_ModulesInstalled

sub     get_Packages    {
        my  ( $parameter    )   =   @_;                                         #   'ALL', path/subdirectory in the Searchpath
        my  $p  =   [];
        foreach my $pm ( keys %INC ) {                                          #   installed_perlmodules
            switch ( $parameter )   {
                case m/\bALL\b/ { push ( @{$p}, get_packagename($pm) ) }        #
                else            { push ( @{$p}, $pm) if ($INC{$pm} =~ $parameter); }
            }#switch
        }#foeach installed_perlmodule
        return $p;
}#sub   get_Packages


sub     get_SymbolTable {
        my  (   $packagename                                                    #   App::DS
            ,   $select     )   =   @_;
        $packagename    //= 'main';
        $select         //=  [ qw( CODE ARRAY HASH SCALAR ) ];
        my $list    =   [];
        my  $sthash =   {};
        no  strict;
        while ( ($entry,$typeglob) = each (%{*{"$packagename\::"}}) ) {
            local (*ENTRY) = $typeglob;
            if ( defined $typeglob ) {
                if ( defined *ENTRY{CODE} ) {  
                    printf "%5s%s : %s\n",'','function', $entry;
                    push ( @{$list}, $entry);
                    push ( @{$sthash{CODE}}, $entry);
                }
                # The SCALAR glob is always defined, must check the VALUE
                # if ( defined $glob && defined *ENTRY{SCALAR} ) {
                if ( defined ${ *ENTRY{SCALAR} } ) {
                    printf "%5s%s : %s\n",'','scalar  ', $entry;
                }
                if ( defined *ENTRY{ARRAY} ) {
                    printf "%5s%s : %s\n",'','array   ', $entry;
                }
                if ( defined *ENTRY{HASH} && $entry !~ /::$/) {
                    printf "%5s%s : %s\n",'','hash    ', $entry;
                }
                if ( defined *ENTRY{HASH} && $entry =~ /::$/ ) {
                    printf "%5s%s : %s\n",'','package ', $entry;
                } 
            }# if $typeglob is defined
        }#while iterate the Symboltable
        printf  "\n";
        return $list;
}#sub   get_SymbolTable


sub     get_all {
        my  (   $slot,
            ,   $packages   )   =   @_;                                         #   List of packages of interest/target
        my  $sthash =   {}; 
        no strict;                                                              #   Allow strings as symbolic referencres
        foreach my $packagename ( @{$packages} ) {
            printf "%*s%s %s +++++\n",5,'','packagename',$packagename;
            while ( ($entry, $typeglob) = each (%{*{"$packagename\::"}}) ) {    #   for all symbol entries
                local (*ENTRY) = $typeglob;                                     #   addressing a typeglob
                printf "%5s%s : %s\n",'','symbol', $entry;
                if ( defined $typeglob ) {                                      #   assessing typeglob slots
                    push ( @{$$sthash{CODE}}  , $entry) if ( defined   *ENTRY{CODE} );
                    push ( @{$$sthash{ARRAY}} , $entry) if ( defined   *ENTRY{ARRAY});
                    push ( @{$$sthash{SCALAR}}, $entry) if ( defined ${*ENTRY{SCALAR}} );
                    push ( @{$$sthash{HASH}}  , $entry) if ( defined   *ENTRY{HASH} && $entry !~ /::$/ );
                    push ( @{$$sthash{PACKAGE}},$entry) if ( defined   *ENTRY{HASH} && $entry =~ /::$/ );    #&& $entry ne "main::" && $entry ne "<none>::")
                }#foreach $typeglob slot
            }#foreach symbol
        }#foreach package
        my  $n  = size_of ( [( keys %{$sthash} )] ); 
        printf "%*s%s %s\n",5,''  ,'Number of slots in SystemTableHash :: ',$n;
        return $sthash;
}#sub   get_all


sub     unify_symboltable   {
        my  (   $packages   )   =   @_;                                         #   [ArrRef] list of package names
        printf "%*s%s( )\n",5,'','unify_symboltable';;
        my  $unifiedsymbols =   {};                                             #   ${$unifiedSymbols}{CODE}{SYMBOL}->PACKAGEname
        no strict;                                                              #   Allow strings a symbolic references
        foreach my $slot (qw ( CODE HASH ARRAY SCALAR PACKAGE ))  {
            printf "%*s%s\n",5,'',$slot;
            $$unifiedsymbols{$lot}    =   [];                                   #   initialized datastructure
        }#foreach slot
        foreach my $packagename ( @{$packages} ) {                              #   packagename 
            printf "%*s%s %s +++++\n",5,'','packagename',$packagename;
            while ( my ($entry, $typeglob) = each (%{*{"$packagename\::"}}) ) {    #   for all symbol entries
                my $ns = $packagename.'::';                                     #   namespace = package::
                my $s  = $ns.$entry;                                            #   symbol
                local (*ENTRY) = $typeglob;                                     #   addressing a typeglob
                #printf "%5s%s : %s\n",'','symbol', $entry;
                printf "%14s%s\n"    ,'',$s;
                if ( defined $typeglob ) {                                      #   assessing typeglob slots
                    printf "%14s%s\n"    ,'',$s;
                    push (@{$$unifiedsymbols{CODE}}   ,$s) if (defined   *ENTRY{CODE} );
                    push (@{$$unifiedsymbols{ARRAY}}  ,$s) if (defined   *ENTRY{ARRAY});
                    push (@{$$unifiedsymbols{SCALAR}} ,$s) if (defined ${*ENTRY{SCALAR}} );
                    push (@{$$unifiedsymbols{HASH}}   ,$s) if (defined   *ENTRY{HASH} && $entry !~ /::$/);
                    push (@{$$unifiedsymbols{PACKAGE}},$s) if (defined   *ENTRY{HASH} && $entry =~ /::$/); # && $entry ne "main::" && $entry ne "<none>::")
                }#foreach slot in typeglob
            }#while another symbol
            printf "%*s%s %s\n",5,'','Code    slots :: ',$#{$$unifiedsymbols{CODE}};
            printf "%*s%s %s\n",5,'','Array   slots :: ',$#{$$unifiedsymbols{ARRAY}};
            printf "%*s%s %s\n",5,'','SCALAR  slots :: ',$#{$$unifiedsymbols{SCALAR}};
            printf "%*s%s %s\n",5,'','HASH    slots :: ',$#{$$unifiedsymbols{HASH}};
            printf "%*s%s %s\n",5,'','PACKAGE slots :: ',$#{$$unifiedsymbols{PACKAGE}};
        }#foreach package
        #my  $n  = size_of ( [( keys %{$unifiedsymbols} )] ); 
        #my $n   = $#(keys %{$unifiedsymbols});
        my $n   = keys %{$unifiedsymbols};
        printf "%*s%s %s\n",5,'','Number of slots in unified SymbolTable :: ',$n;
        return $unifiedsymbols;
}#sub   unify_symboltable

###         This is first class variable collision
### sub     unify_symboltable   {
###         my  (   $packages   )   =   @_;                                         #   [ArrRef] list of package names
###         my  $unifiedsymbols =   {};                                             #   ${$unifiedSymbols}{CODE}{SYMBOL}->PACKAGEname
###         no strict;                                                              #   Allow strings a symbolic references
###         foreach my $packagename ( @{$packages} ) {                              #   packagename 
###             #printf "%*s%s %s +++++\n",5,'','packagename',$packagename;
###             while ( ($entry, $typeglob) = each (%{*{"$packagename\::"}}) ) {    #   for all symbol entries
###                 my $ns = $packagename.'::';                                     #   namespace = package::
###                 me $s  = $ns.$entry;                                            #   symbol
###                 local (*ENTRY) = $typeglob;                                     #   addressing a typeglob
###                 #printf "%5s%s : %s\n",'','symbol', $entry;
###                 if ( defined $typeglob ) {                                      #   assessing typeglob slots
###                     $$unifiedsymbols{CODE}{$entry}    = $ns  if ( defined   *ENTRY{CODE} );
###                     $$unifiedsymbols{ARRAY}{$entry}   = $ns  if ( defined   *ENTRY{ARRAY});
###                     $$unifiedsymbols{SCALAR}{$entry}  = $ns  if ( defined ${*ENTRY{SCALAR}} );
###                     $$unifiedsymbols{HASH}{$entry}    = $ns  if ( defined   *ENTRY{HASH} && $entry !~ /::$/ );
###                     $$unifiedsymbols{PACKAGE}{$entry} = $ns  if ( defined   *ENTRY{HASH} && $entry =~ /::$/ ); # && $entry ne "main::" && $entry ne "<none>::")
###                 }#foreach $typeglob slot
###             }#foreach symbol
###         }#foreach package
###         my  $n  = size_of ( [( keys %{$unifiedsymbols} )] ); 
###         printf "%*s%s %s\n",5,'','Number of slots in unified SymbolTable :: ',$n;
###         return $unifiedsymbols;
### }#sub   unify_symboltable

sub     list_unifiedSymbolTable {
        my  (   $ust 
            ,   $format )   =   @_;
        $$format{indent}    //= 5;
        $$format{indent2}   =   maxwidth ([( keys %{$ust} )]);                  #   slot width
        #$$format{indent3}   =   maxwidth ([( grep ( grep (values %{$ust{$_}) ) keys %{$ust} )]);    #   namespace width
        #$$format{indent3}   =   maxwidth ([( grep { grep { $_ } values %{$ust{$_}} } keys %{$ust} )]);    #   namespace width
        #printf "\n%*s%s( %s )\n",5,'','list_SymbolTableSlot',size(keys %{$ust});
        my  @tmp    =   (keys %{$ust});
        printf "\n%*s%s( %s )\n",5,'','list_SymbolTableSlot', $#tmp;
        printf "%*s%s %s\n",5,'','Code    slots :: ',$#{$$ust{CODE}};
        printf "%*s%s %s\n",5,'','Array   slots :: ',$#{$$ust{ARRAY}};
        printf "%*s%s %s\n",5,'','SCALAR  slots :: ',$#{$$ust{SCALAR}};
        printf "%*s%s %s\n",5,'','HASH    slots :: ',$#{$$ust{HASH}};
        printf "%*s%s %s\n",5,'','PACKAGE slots :: ',$#{$$ust{PACKAGE}};



        foreach my $slot ( sort keys %{$ust} ) {
            $$format{slot}  =   $slot;
            list_SymbolTableSlot( $$ust{$slot}, $format );
            #printf  "%*s %*s\n",$w,'',$sw,$slot;
        }#foreach slot
}#sub   list_unifiedSymbolTable


sub     list_SymbolTableSlot    {
        my  (   $SymbolSlot
            ,   $format )   =   @_;
        $$format{separator} //= '||';   
        my  $lc =   0;                                                          #   line count
        my  $sl =   $$format{slot};                                             #   slot name/type CODE, ARRAY, HASH, SCALAR, PACKAGE
        my  $s  =   $$format{separator};                                        #   
        my  $w1 =   $$format{indent};
        my  $w2 =   $$format{indent2};
        my  $w3 =   20;
        my  $f  =   "%*s%*s %s\n";                                              #   format string
        #my  $w3 =   maxwidth ([( values %{$SymbolSlot} )]);                    #   names
        #while ( my ($sym,$ns) = each ( %{$SymbolSlot} ) ) {
        #printf "\n%*s%s( %s )\n",5,'','list_SymbolTableSlot',$#{$SymbolSlot};
        foreach  my $sym ( @{$SymbolSlot} ) {
            #my $sigil   = ($sl eq 'CODE')   ? '&'
            #            : ($sl eq 'HASH')   ? '%'
            #            : ($sl eq 'ARRAY' ) ? '@'
            #            : ($sl eq 'SCALAR') ? '$' : '';
            printf  $f ,$w1,'',$w2,$sl,$sym if ($lc==0);                        #   Bitwise AND
            printf  $f ,$w1,'',$w2,' ',$sym if ($lc>0);                         #   Bitwise XOR
            $lc++;
        }#foreach Symbol in SLOT
}#sub   list_SymbolTableSlot

### sub     list_SymbolTableSlot    {
###         my  (   $SymbolSlot
###             ,   $format )   =   @_;
###         $$format{separator} //= '||';   
###         my  $lc =   0;                                                          #   line count
###         my  $sl =   $$format{slot};                                             #   slot name/type CODE, ARRAY, HASH, SCALAR, PACKAGE
###         my  $s  =   $$format{separator};                                        #   
###         my  $w1 =   $$format{indent};
###         my  $w2 =   $$format{indent2};
###         my  $w3 =   20;
###         my  $f  =   "%*s%*s %-*s %s %s%s\n";                                    #   format string
###         #my  $w3 =   maxwidth ([( values %{$SymbolSlot} )]);                     #   names
###         while ( my ($sym,$ns) = each ( %{$SymbolSlot} ) ) {
###             my $sigil   = ($sl eq 'CODE')   ? '&'
###                         : ($sl eq 'HASH')   ? '%'
###                         : ($sl eq 'ARRAY' ) ? '@'
###                         : ($sl eq 'SCALAR') ? '$' : '';
###             printf  $f ,$w1,'',$w2,$sl,$w3,$ns,$s,$sigil,$sym if ($lc==0);      #   Bitwise AND
###             printf  $f ,$w1,'',$w2,' ',$w3,$ns,$s,$sigil,$sym if ($lc>0);       #   Bitwise XOR
###             $lc++;
###         }#foreach Symbol in SLOT
### }#sub   list_SymbolTableSlot


sub     get_ModuleVersion   {
        my  ( ) =   @_;
}#sub   get_ModuleVersion


# sub     get_ModuleVersion   {
#         my  ( ) =   @_;
# }#sub   get_ModuleVersion


sub     display_Symbols {                                                       #   SymbolTabelReference
        my($hashRef) = shift;                                                   #   {HashRef} == \%App::DS::
        my(%symbols);
        my(@symbols);

        %symbols = %{$hashRef};
        @symbols = sort(keys(%symbols));

        foreach (@symbols) {
            printf("%5s%-20.20s| %s\n",'', $_, $symbols{$_});
        }
}#sub   display_Symbols


sub     get_packagename  {                                                      #   Get Package name from Module Filename
        my  (   $fn     )   =   @_;                                             #   App/DS.pm
        my @tmp1= split /\./, $fn;                                              #   break off .pm
        my @tmp2= split(/\//, $tmp1[0]);                                        #   remove [/], create name space hierachy (App, DS)
        my $package=  join '::', @tmp2;                                         #   create packagename App::DS
        return $package;                                                        #   return App::DS
}#sub   get_packagename

sub     get_namespace   {
        my  (   $fn     )   =   @_;                                             #   App/DS.pm
        my @tmp1= split /\./, $fn;                                              #   break off .pm
        my @tmp2= split(/\//, $tmp1[0]);                                        #   remove [/], create name space hierachy (App, DS)
        my $namespace=  join '::', @tmp2;                                       #   create namespace App::DS::
        $namespace  .=  "::";
        return $namespace;                                                      #   return App::DS::
}#sub   get_namespace

sub     get_symboltableRef {
        my  ( $packagename )  =   @_;
        no  strict;
        return \%{*{"$packagename\::"}};
}#sub   get_symboltableRef

#----------------------------------------------------------------------------
#       P R I V A T E  M E T H O D S

#----------------------------------------------------------------------------

sub   ListModules {                                                                 # List Module     
      no strict;                                                                    # access $VERSION by symbolic reference
      print map {
          s!/!::!g; 
          s!.pm$!!; 
          sprintf "%-20s %s\n", $_, ${"${_}::VERSION"} 
      } sort keys %INC; 
}#sub ListModules

# End of module App
1;
