package DS::Array;
#   File            DS/Array.pm
#
#   Refactored      03-04-2020          
#   Author          Lutz Filor
#
#   
#   Synopsys        DS::Array::
#                   Common tasks built on Array references
#   
#                   DS::Array::list_array   ( [ArrRef] )    1D
#                   DS::Array::list_table   ( [ArrRef] )    2D, row oriented
#                   DS::Array::list_table   ( [ArrRef] )    2D, col oriented
#
#                   $Number_of_Entries  =   size_of         ( [ArrRef] )
#                   $Largest_Entry      =   maxwidth        ( [ArrRef], DefaultMin )
#                   @array              =   clone_aref      ( [ArrRef] )
#                   $ArrRef             =   unique          ( [ArrRef] )
#                   $ArrRef             =   unpack_string   ( [ArrRef] )
#                   $ArrRef             =   intersect       ( [ArrRef], [ArrRef] )

use strict;
use warnings;

use Switch;
#use Readonly;
#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.25");

use Exporter qw (import);
use parent 'Exporter';                              #   parent replaces use base 'Exporter';

#our @EXPORT    = qw    (   );#implicite            #   deprecated, 

our @EXPORT_OK  = qw    (   list_array
                            list_table
                            list_modules
                            installed_modules
                            module_searchpath

                            unpack_string
                            intersect
                            prepend
                            append


                            unique
                            size_of
                            clone_aref
                            maxwidth
                            transpose
                            columnwidth
                        );#explicite                #   

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ]
                        );
#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       S U B R O U T I N S

#       largest_entry
#       widest_elem
#       longest_string                                    

sub     size_of {                                                               #   number of entries {N : 0 .. N-1} of [$a_ref]
        my  (   $a_ref  )   =   @_;                                             #   array reference
        return  scalar @{$a_ref};                                               #   Starting perl version 5.30, $# operator is deprecated, use scalar()
}#sub   size_of

sub     clone_aref   {                                                          #   Clone data of $aref, physically copy
        my  (   $ArrRef     )   =   @_;                                         #   [$ListReference]
        return  @{$ArrRef};                                                     #   Return Clone/Physical copy
}#sub   clone

sub     unique  {
        my  (   $ArrRef     )   =   @_;
        my  %unique =   ();
        foreach my $entry ( @{$ArrRef} ) {                                      #   inspect all entries
            $unique{$entry} = 1;                                                #   overwrite doublicate entries
        }#for all entries
        return  [ keys %unique ];                                               #   return [$ArrRef]
}#sub   unique

sub     maxwidth    {                                                           #   largest string { max : max >= $a_ref[n]} of [$a_ref]
        my  (   $ArrRef                                                         #   Array/List reference of interest
            ,   $seed       )   =   @_;                                         #   In case of rolethrough, or minimum width
        my  $max    =   $seed;                                                  #   Max can't be smaller then Minimum SEED
            $max    //= 0;                                                      #   Default SEED is ZERO
        if ( ref $ArrRef eq 'ARRAY' ) {
            foreach my $entry  ( @{$ArrRef} ) {
                my $tmp =   length($entry);
                $max = ( $max > $tmp ) ? $max : $tmp;
                #printf "%9s%*s\t%s\n",'',$max,$entry,$tmp;
            }#for all
            #printf "%9s%*s\t%s\n",'',$max,'max',$max;
        }# if array ref
        else {
            #warn input not an array reference
        }
        return $max;
}#sub   maxwidth

sub     list_array {
        my  (   $a_ref                                                          #   [ArrRef]
            ,   $f_ref  ) = @_;                                                 #   {HashRef} format information 
        my  $name   =   $$f_ref{name};                                          #   Show name of array 
        my  $size   =   $$f_ref{size};                                          #   Show number of entries of array
        my  $i      =   $$f_ref{indent};                                        #   Indentation character
        my  $p      =   $$f_ref{pattern};                                       #   Indentation pattern
        my  $ll     =   $$f_ref{leading};                                       #   Before/leading whitespace
        my  $n      =   $$f_ref{number};                                        #   Insert numbering
        my  $align  =   $$f_ref{align};                                         #   left/right alignment w/in column
        my  $tl     =   $$f_ref{trailing};
            $i      //= 5;                                                      #   Default indentation
            $p      //= '';
            $ll     //= 0;                                                      #   Default zero leading lines
            $tl     //= 0;                                                      #   Default zero trailing lines
            $align  //= 'unaligned';                                            #   Default alignment is left
        my  $a  =   ( $align eq 'right' ) ? 1 :
                    ( $align eq 'left'  ) ?-1 : -1;
        my  $w1 =   maxwidth(   $a_ref  );                                      #   Width of content column
        #printf "%5s%s()\n\n",$p,"list_array";
        #printf "%5s%s %s\n" ,$p,'indent',$i;
        #printf "%5s%s %s\n" ,$p,'maxkey',$w1;
        #printf "%5s%s %s\n" ,$p,'align' ,$align;
        for my $l   (1..$ll) { printf "%*s\n"  ,$i,$p; }                        #   Vertical whitespace before
        if ( defined $name ) { printf "%*s%s\n",$i,$p,$name; }                  #   Report name of array variable
        unless ( ref $a_ref eq 'ARRAY' ) {                                     #   Coding error, pathing wrong type
            printf  "%*sWARNING !! list_array( %s )",$i,$p,$a_ref;
            printf  " NOT array reference type\n";
            return;
        }
        if ( defined $size ) { printf "%*sSize of %s is %s\n"
                                    ,$i,$p,$name,$#{$a_ref}+1; }
        if ( defined $$f_ref{number} ) {
            my  $ln =   $#{$a_ref};
            my  $w0 =   length $ln;
            $ln     =   1;                                                      #   First entry
            foreach my $element ( @{$a_ref} ) {
                chomp $element;
                printf "%*s%*s%*s\n",$w0,$ln++,$i-$w0,$p,$a*$w1,$element;
            }# foreach
        } else { #numbered list
            foreach my $element ( @{$a_ref} ) {
                my $w =   ( $align eq 'unaligned' )? 1 : $w1;                   #   [Fi] Experiment 09-21-2020
                chomp $element;
                #printf "%*s%*s%*s\n",$i,$p,$a*$w,$element;
                 printf "%*s%*s\n",$i,$p,$a*$w,$element;                         #   Wide character !!
            }# foreach
        }# unnumbered list
        for my $l   (1..$tl) { printf "%*s\n",$i,$p}
        return;
}#sub   list_array

sub     unpack_string   {
        my  (   $ArrRef )   =   @_;
        my  $unpacked   =   [];
        foreach my  $packed ( @{$ArrRef} ) {
            if ( $packed =~ m/[,]/ ) {
                my @up  = split(/,/, $packed);
                push ( @{$unpacked}, @up );
            } else {
                push ( @{$unpacked}, $packed );
            }
        }#
        return  $unpacked;
}#sub   unpack_string

sub     prepend {
        my  (   $prefix
            ,   $ArrRef     )   =   @_;                                         #   List to be expanded
        my  $tmp    =   [];
        foreach my $entry   ( @{$ArrRef} )   {
            push ( @{$tmp}, "$prefix"."$entry" );
        }# prepend all entries
        #   Write out Logfile
        return $tmp;                                                            #   Expanded prefix.list
}#sub   prepend

sub     append  {
        my  (   $ArrRef                                                         #   List to be appended
            ,   $affix      )   =   @_;
        my  $tmp    =   [];
        foreach my $entry   ( @{$ArrRef} )   {
            push ( @{$tmp}, "$entry"."$affix" );
        }# prepend all entries
        #   Write out Logfile
        return $tmp;                                                            #   Expanded list.affix
}#sub   append

sub     intersect   {                                                           #   Schnittmenge, Intersection
        my  (   $a_ArrRef                                                       #   Set A
            ,   $b_ArrRef   )   =   @_;                                         #   Set B
        my  $tmp    =   [];                                                     #   intersection ( A, B)
        printf  "%*sintersect( [aRef], [bRef] )\n",5,'';                        #   debug vestigial
        printf  "%*s         (  %4s, %6s  )\n",5,''
                ,scalar (@{$a_ArrRef}),scalar (@{$b_ArrRef});
OUTER:  foreach my $a ( @{$a_ArrRef} )  {                                       #   dbg     small set
            #printf "%*sSearching %s\n",5,'',$a;                                #   debug vestigial
INNER:      foreach my $b ( @{$b_ArrRef} )  {                                   #   subs    large set (super set)
                if ( $a eq $b ) {                                               #   match exactly not in partial pattern
                    push( @{$tmp}, $b );                                        #   capture the symbol from symbol table
                    #last OUTER;                                                #   Escape inner loop - wrong escapes the outloop
                    last INNER;                                                 #   Escape inner loop, don't waste on search
                }# matching
            }# iterrate super-set
        }# iterate sub-set
        printf  "%*sSize of intersect() %s\n\n",5,'',$#{$tmp}+1;                #   debug   vestigial
        return $tmp;
}#sub   intersect

sub     list_table  {
        my  (   $ArrRef                                                         #   [ArrRef]
            ,   $format     )   =   @_;                                         #   {HashRef} format information 
        my  $name   =   $$format{name};    
        my  $i      =   $$format{indent};
        my  $p      =   $$format{pattern};
        my  $tlp    =   $$format{topline};
        my  $mlp    =   $$format{midline};
        my  $lf     =   $$format{leftframe};                                    #   '| '
        my  $css    =   $$format{columnseparator};                              #   ' | ' 
        my  $rf     =   $$format{rightframe};                                   #   ' |'
        my  $blp    =   $$format{botline};
        my  $ll     =   $$format{leading};
        my  $f      =   $$format{frame};
        my  $n      =   $$format{number};
        my  $align  =   $$format{align};
        my  $tl     =   $$format{trailing};
            $i      //= 5;                                                      #   Default indentation
            $p      //= '';
            $tlp    //= '-';                                                    #   Default line pattern top
            $mlp    //= '=';                                                    #   Default line pattern mid
            $blp    //= '-';                                                    #   Default line pattern bot
            $lf     //= '| ';                                                   #   Default left  frame (open)
            $css    //= ' | ';                                                  #   Default column separator
            $rf     //= ' |';                                                   #   Default right frame (close)
            $ll     //= 0;                                                      #   Default zero leading lines
            $tl     //= 0;                                                      #   Default zero trailing lines
            $align  //= 'unaligned';                                            #   Default alignment is left
        my  $trans  =   transpose   (  $ArrRef  );
        my  $w      =   columnwidth (   $trans  );                              #   [ArrRef] w/ max Width of each column
        my  $a      =   aligning    (   $trans, $align );                       #   [ArrRef] w/ default alignment of each cell
        my  $num    =   length      (   $#{$ArrRef}+1 );                        #   Space request for largest line number
        my  $rl     =   0;                                                      #   row length;
        my  $cs     =   $#{$trans} * length($css)                               #   Column separator space
                    +   length($lf) + length($rf);
        map { $rl  +=   $_ } @{$w};                                             #   sum of all columns
        my  ($v,$t,$b)  =   ( 1, 1, 1);
        for my $l   (1..$ll) { printf "%*s\n"  ,$i,$p; }                        #   Leading lines
        #printf "%*sNumber of Column %s\n",$i,$p,$num;                          #   Development vestigal
        #printf "%*sNumber of Separators %s\n",$i,$p,$#{$trans};
        #printf "%*sSeparator Space  %s\n",$i,$p,$cs;
        #printf "%*sColumn Space Separator <%s>\n",$i,$p,$css;
        if ( defined $name ) { printf "%*s%s\n",$i,$p,$name; }
        if  ( $t )  { printf "%*s%s\n",$i,$p,$tlp x ($rl+$cs) }
        for my $row ( @{$ArrRef} ) {
            printf "%*s",$i,$p;                                                 #   Row indent
            printf "%s" ,$lf    if ( defined $v );                              
            printf "%*s ",$num, if ( defined $n );                              #   if numbering is on
            for my $col (0..$#{$row}) {
                my $tmp = ($col < $#{$row})?$css:$rf;                           #   Column separator or right frame
                #$$w[$col]   //= 1;
                $$a[$col]   //= 1;                                              #   guard against incomplete occupied matrix/table
                $$row[$col] //= ' ';
                printf "%*s%s",$$a[$col]*$$w[$col],$$row[$col],$tmp;            #   Align each entry in column
            }# all columns
            printf "\n";                                                        #   Row termination
        }# all rows
        if  ( $b )  { printf "%*s%s\n",$i,$p,$blp x ($rl+$cs) }
        for my $l   (1..$tl) { printf "%*s\n"  ,$i,$p; }                        #   Trailing lines
        return;
}#sub   list_table


sub     print_line  {
        my  (   $format                                                         #   {HshRef} w/ Format info
            ,   $columns    )   =   @_;                                         #   [ArrRef] w/ Column width
        my  $i      =   $$format{indent};
        my  $p      =   $$format{pattern};
        my  $n      =   $#{$columns} + 1;                                       #   Number of Columns
        my  $l      =   0;
        map { $l += $_ } @{$columns};
        return $l;                                                              #   line = SUM of all columns
}#sub   print_line

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
        my $n   =   size_of ( [( keys %INC )] );                                #   number of detected module
        my $w   =   maxwidth( [( keys %INC )] );
        my  @a;
        my  $m  =   \@a;
        #my $m   =   [];                                                        #   modules installed
        printf "\n%*s%s %s\n",5,'','Library access path      :: ',$p;
        printf "%*s%s %s\n",5,'','Number of loaded modules :: ',$n;
        foreach my $loaded ( keys %INC) {                                       #   loaded module
            my $ns= namespace_from_pm( $loaded );
            #my $h = ($INC{$loaded} =~ $p) ? '+' : '-';
            #printf "%*s%*s :: %s %s\n",5,'',$w,$loaded, $h, $INC{$loaded};
            #push ( @{$m}, $loaded) if ( $INC{$loaded} =~ $p );
        }# for all loaded module
        return $m;                                                              #   local modules
}#sub   installed_modules

sub     transpose   {
        my  (   $ArrRef )   =   @_;
        my  $transpose  =   [];
        for my $row ( @{$ArrRef} )  {
            for my $col (0..$#{$row} )  {
                push( @{$$transpose[$col]}, $$row[$col]);
            }
        }
        return  $transpose;
}#sub   transpose

sub     columnwidth {
        my  (   $ArrRef )   =   @_;
        my  $columns    =   [];
        my  $cnt        =   0;
        for my $col ( @{$ArrRef} )  {
            #printf "%5s%3s Column width\n",'',maxwidth($col);                  #   Development vestigal, data pushed
            push( @{$columns}, maxwidth($col));
        }# iterate all columns
        return $columns;
}#sub   columnwidth

sub     aligning    {
        my  (   $ArrRef
            ,   $align  )   =   @_;
        my  $a  =   [];
        for my $col (0..$#{$ArrRef}) {
            my $tmp = ($align eq 'unaligned')
                    ?   1:$$align[$col];                                        #   default : custom alignment
            push( @{$a}, $tmp);                                                
        }# iterate all columns
        return $a;                                                              #   alignment vector for all columns (left|right)
}#sub   aligning

#----------------------------------------------------------------------------
# End of module Array.pm
1;
