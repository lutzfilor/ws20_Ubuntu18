package DS::Hash;
# File          DS/Hash.pm
#
# Created       03-022-2020          
# Author        Lutz Filor
# 
# Synopsys      Hashes are an elementary data structure and working
#               wish hashes requires, to support the data structure
#               
#               DS::Hash::SizeOfHashRef ( {$HshRef} )
#               DS::Hash::list_hash     ( {$HshRef}, {$Format} )
#               DS::Hash::prune_hash    ( {$HshRef} )
#               DS::Hash::es()  Finding the path to or the location 
#                               of an installed Perl Module
#

use strict;
use warnings;

use Switch;
#use Readonly;

use lib	"$ENV{PERLPATH}";                           #   Add Include path to @INC

use App::Dbg        qw  (   debug       
                            subroutine  );          #   Debug features

use DS::Array       qw  (   size_of
                            maxwidth    );          #   ArrayRef functions

use Terminal        qw  (   t_warn      );

#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.19");

use Exporter qw (import);
use parent 'Exporter';                              #   parent replaces use base 'Exporter';

#our @EXPORT    = qw    (   );#implicite            #   Deprecated implicite export

our @EXPORT_OK  = qw    (   SizeOfHashRef
                            determineWidth
                            max_key
                            max_value
                            list_hash

                            prune_hash
                            array2hash

                            list_modules
                        );#explicite

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ]
                        );
#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     SizeOfHashRef {
        my ($h_r) = @_;                                                         #   {$Hash_reference}
        my $size = keys %{$h_r};
        return $size;                                                           #   number of Hash value pairs
}#sub   SizeOfHashRef

sub     prune_hash  {                                                           #   remove undefined hash value entries
        my  (   $href    
            ,   $dbg    )   =   @_;                                             #   overruling debug parameter - optional
        my  $n  =   subroutine('name');                                         #   subroutine name
        my  $verbose    =  debug($n) || $dbg; 
        if( $verbose ) {
            printf  "%*s%s( %s )\n",5,'',$n,scalar( keys %{$href} );
        }
        while   ( my ($k, $v) = each ( %{$href} )) {
            printf  "%*s%10s -> ",5,'',$k if( $verbose );
            if ( defined $v ) {
                printf  "%s",$v if( $verbose );
            } else {                                                            #   if ( defined $v );
                printf  "undefined" if( $verbose );
                delete(${$href}{$k});                                           #   unless ( defined $v );
            }
            printf  "\n" if( $verbose );
        }# inspect all
        if( $verbose ) {
            printf  "%*s%s( %s ) done\n\n",5,'',$n, scalar(keys %{$href});      #   Show effectivness of pruning
        }
        return $href;
}#sub   prune_hash

sub     array2hash  {
        my  ( $ArrRef ) =   @_;
        my  $HshRef =   {};
        foreach my $entry ( @{$ArrRef} ) {
            $$HshRef{$entry}    = 1;
        }
        return $HshRef;
}#sub   array2hash

sub     determineWidth {
        my  ($h_r) =    @_;                                                     #   {$Hash_reference}
        my  $max   =    0;
        while ( my (($k, $v) ) = each(%{$h_r})) {                               #   %INC == %{$h_r}
            $max = (length($k) > $max)? length($k):$max; 
        }# while
        return $max;
}#sub   determineWidth

sub     max_key {
        my  ($h_r) =    @_;                                                     #   {$Hash_reference}
        my  $max   =    0;
        while ( my (($k, $v) ) = each(%{$h_r})) {                               #   %INC == %{$h_r}
            $max = (length($k) > $max)? length($k):$max; 
        }# while
        return $max;                                                            #   largest key size
}#sub   max_key

sub     max_value {
        my  ($h_r) =    @_;                                                     #   {$Hash_reference}
        my  $max   =    0;
        while ( my (($k, $v) ) = each(%{$h_r})) {                               #   %INC == %{$h_r}
            $max = (length($v) > $max)? length($v):$max; 
        }# while
        return $max;                                                            #   largest value size 
}#sub   max_value


sub     list_modules  {
        my  (   $list   
            ,   $attribute  )   = @_;
        my $n   =   size_of ( $list );                                          #   number of detected module
        my $w   =   maxwidth( $list );                                          #   largest module name
        my $l   =   [];                                                         #   list
        $attribute //=  'default';
        printf "\n%*s%s %s\n",5,'','Number of loaded modules :: ',$n;
        no strict 'refs';                                                       #   2020-03-22 enable string as a symbol reference
        foreach my $pmodule  ( @{$list} )   {
            my $ns  =   namespace_of( $pmodule );
            #*stash   =   *{"$ns::"};                                           #   System Table Hash
            switch  ( $attribute ) {
                case  m/\bversion\b/ {  printf "%*s%s %*s :: %s\n",5,'','VERSION    ',$w,$pmodule,${${*{"$ns\::"}}{VERSION}}; }
                case  m/\bpackage\b/ {  push( @{$l}, $ns );
                                        printf "%*s%s %*s :: %s\n",5,'','packagename',$w,$pmodule,$ns;              }
                case  m/\bnamespace/ {  push( @{$l}, $ns."::" );
                                        printf "%*s%s %*s :: %s\n",5,'','namespace  ',$w,$pmodule,$ns."::";         }
                case  m/\bpath\b/    {  push( @{$l}, $ns."::" );
                                        printf "%*s%s %*s :: %s\n",5,'','module     ',$w,$pmodule,$INC{$pmodule};   }
                else                 {  push( @{$l}, $ns."::" );
                                        printf "%*s%s %*s :: %s\n",5,'','module     ',$w,$pmodule,$INC{$pmodule};   }
            }#switch select attribute
        }#foreach
        printf  "\n";
        return $l;
}#sub   list_modules


sub     namespace_of    {                                                       #   Get Namespace or Package Name
        my  (   $fn     )   =   @_;
        my @tmp1= split /\./, $fn;                                              #   break off .pm
        my @tmp2= split(/\//, $tmp1[0]);                                        #   remove [/]
        my $namespace=  join '::', @tmp2;
        #$namespace  .=  "::";
        return $namespace;
}#sub   namespace_of


sub     modulename_from_namespace   {                                           #
        my  ( $namespace )  =   @_;
        my  $pm =   "";
        return $pm;
}#sub   modulename_from_namespace

sub     list_module_version {
        my  (   $p )   =   @_;                                                  #   path to lib
        my  $no =   size_of ( [( keys %INC )] );                                #   number of detected module
        my  $w  =   maxwidth( [( keys %INC )] );
        my  @a;
        my  $m  =   \@a;
        #my $m   =   [];                                                        #   modules installed
        printf "\n%*s%s %s\n",5,'','Library access path      :: ',$p;
        printf "%*s%s %s\n",5,'','Number of loaded modules :: ',$no;
        foreach my $loaded ( keys %INC) {                                       #   loaded module
            my $ns= namespace_from_pm( $loaded );
            #my $h = ($INC{$loaded} =~ $p) ? '+' : '-';
            #printf "%*s%*s :: %s %s\n",5,'',$w,$loaded, $h, $INC{$loaded};
            #push ( @{$m}, $loaded) if ( $INC{$loaded} =~ $p );
        }# for all loaded module
        return $m;                                                              #   local modules
}#sub   installed_modules

sub     list_hash   {
        my  (   $hash                                                           #   {HshRef}  
            ,   $format )   =   @_;                                             #   Format {HshRef}
        my  $ll     =   $$format{before};                                       #   leading lines
        my  $name   =   $$format{name};                                         #   report name of {HshRef}
        my  $size   =   $$format{size};                                         #   report size of {HshRef}
        my  $i      =   $$format{indent};                                       #   format overwrite    default 5
        my  $p      =   $$format{pattern};                                      #   pattern overwrite   default ''
        my  $s      =   $$format{separator};                                    #   separator overwrite default ' | '
        my  $tl     =   $$format{after};                                        #   trailing lines
            $ll //=  0;                                                         #   Default zero leading lines
            $i  //=  5;                                                         #   Default row header width                                            
            $p  //= '';                                                         #   Default row header pattern
            $s  //= '|';                                                        #   Default column separator for table
            $tl //=  0;                                                         #   Default zero trailing lines
        my  $ud =   [];                                                         #   collect undefined value entries
        my  $no =   size_of ( [( keys %{$hash} )] );                            #   Number of entries/subsrictions in {$hash}
        my  $w  =   maxwidth( [( keys %{$hash} )] );
        my  $l  =   '';                                                         #   Initialize empty line
        #printf  "\n";
        my  $n  =   subroutine('name');                                         #   Determine the name of THIS subroutine
        if  ( debug($n) )   {
            my  $identifier =   $name;
                $identifier //= 'HASH';
            printf  "%*s%s( %s )\n",5,'',$n,$identifier;
            printf "%*sSize of %s is %s\n",$i,$p,$name,$no; 
        }#debugging
        #if
        for my $l   (1..$ll) { printf "%*s\n"  ,$i,$p; }
        if ( defined $name ) { printf "%*s%s\n",$i,$p,$name; }
        if ( defined $size ) { 
            $name   //= 'HASH';
            printf "%*sSize of %s is %s\n",$i,$p,$name,$no; 
        }
        foreach my $key ( sort { "\L$a" cmp "\L$b"} keys %{$hash} ) {           #   alphabetical ordered loaded module
            if ( defined $$hash{$key} ) {
                $l = sprintf "%*s%*s %s %s",$i,$p,-$w,$key,$s,$$hash{$key};
                printf  "%s\n",$l;
            } else {                                                            #   /add debug warning for undefined values
                $l = sprintf "%*s%*s %s %s",$i,$p,-$w,$key,$s,'undef value';    #   create record
                push( @{$ud}, $l );                                             #   compile undefined hash entries/values
            }#
        }#foreach
        if ( @{$ud} )   {
            printf "%*sUndefined Hash entries\n",$i,$p;
            foreach my $line ( @{$ud} ) {
                printf "%s\n",$line;
            }
        }# append undefined hash entries
        return;                                                                 #   default return
}#sub   list_hash

#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D S




#----------------------------------------------------------------------------
# End of module DS/Hash.pm
1;
