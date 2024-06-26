package App;
#
# File          ~/ws/perl/lib/App.pm
#               
# Created       05/15/2019
# Author        Lutz Filor
# 
# Synopsys      App::CLI::new()
#               Wall clock time of application program
#
#               elaborate ( )
#                   -   unpack_string   (  $string  )
#                   -   intersect       ( [$setA], [$setB] )
# 
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use lib "$ENV{PERLPATH}";                                                       #   Add Include path to @INC

use File::IO::Log       qw  (   log_hashref
                                log2_hashref
                                log_arrayref            );                      #   Aiding debugging of setup procedures

use App::Dbg            qw  (   debug
                                subroutine              );                      #   Must be imported 

use App::Dbg::ST        qw  (   get_FullModulePath 
                                get_Namespace
                                get_Symbols
                                get_Version
                                get_Subroutines
                                list_Namespace          );                      #   Debug Information from System table

use App::Modules        qw  (   get_ModuleSearchpath
                                get_ModulesInstalled
                                get_SymbolTable 
                                display_Symbols 
                                get_all                 );                      #   Under development, Debugging

use App::Performance    qw  (   sample_timingresolution
                                set_postamble
                                run_time
                                elapsedtime 
                                terminate               );                      #   Measure run time/wall clock

use DS                  qw  (   list_ref                );                      #   List unknown Data structures

use DS::Array           qw  (   list_modules

                                unpack_string
                                intersect
                                
                                size_of
                                maxwidth                );                      #   ArrayRef functions

use DS::Hash            qw  (   array2hash              );                      #   HashRef functions

use Terminal            qw  (   t_info                  );                      #   Use for terminal output

#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v3.01.26");

use Exporter qw (import);
use parent 'Exporter';                                                          #   replaces base; base is deprecated


#our @EXPORT   =    qw();                                                       #   deprecated implicite export
                      
our @EXPORT_OK =    qw(     new
                            get

                            elaborate
                            debug
                            subroutine

                            update
                            inspect

                            inspect_api
                            get_subs
                            run_time
                            terminate  );                                       #   explicite export

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#Readonly my  $FAIL  =>   1;                                                    # default setting, Success must be determinated
#Readonly my  $PASS  =>   0;                                                    # PASS value ZERO as in ZERO failure count
#Readonly my  $INIT  =>   0;                                                    # Initialize to ZERO

use App::Const  qw( :ALL );                                                     #   Prove of concept, of external defined Constants
#----------------------------------------------------------------------------
#       S U B R O U T I N S

#       Experimental Code
sub     new {                                                                   # constructor
        my  ( $class                                                            # Object Name
            , %options  )=   @_;                                                # Allow Parameter Hash input
        #my  $class       =   shift;                                            # Object Name
        #my  %options     =   @_;                                               # Allow Parameter Hash input
        my  $self    =   {
            start_n =>  `date +%N`,
            start_t =>  `date +%T`,
            start   =>  `date +%T.%N`,
            version =>  $VERSION,
            nano1   =>  `date +%N`,                                             #   Nanoseconds     - 0.### ### ### [s]
            time1   =>  `date +%T`,                                             #   HH:MM:SS        - Time stamp
            date1   =>  `date +%F`,                                             #   YYYY-MM-DD      - Date stamp
            time    =>  `date +%s%N`,                                           #   Current Time
            date    =>  `date`,                                                 #   Current Date
            start1  =>  [localtime()],                                          #   Current Time
            status  =>  $FAIL,                                                  #   Default exit    - status set to $FAIL
            error   =>  $INIT,                                                  #   Error   count   - innitialization
            warn    =>  $INIT,                                                  #   Warning count   - innitialization
            #status =>  1,                                                      #   Default exit    - status set to $FAIL
            #error  =>  0,                                                      #   Error   count   - innitialization
            #warn   =>  0,                                                      #   Warning count   - innitialization
            #
            subs    =>  compile_subroutines(),                                  #   List of soubroutines loaded in application
            %options,                                                           #   Provide more parameter
            #
            elapse  =>  `date +%s%N`,
            elapse2  =>  `date +%S%N`,                                          #   This is relative time no absolute time
        };

        chomp   ${$self}{start};
        chomp   ${$self}{elapse};
        chomp   ${$self}{start_n};
        chomp   ${$self}{start_t};
        ${$self}{start_}    =   ${$self}{start_t}.'.'.${$self}{start_n};
        ${$self}{self} = $self;                                                   #   reference to unblessed HASH
        ${$self}{status} = $INIT;
        #printf  "%5s%s%19s\n",'','Create Object      : ', $class;
        #printf  "%5s%s%19s\n",'','Object status      : ', ${$self}{status};

        #my      $delta = ${$self}{elapse} - ${$self}{start};
        #printf  "%5s%s%19s\n"  ,'','Number of Warnings : ', ${$self}{warn};
        #printf  "%5s%s%19s\n"  ,'','Number of Errors   : ', ${$self}{error};
        #printf  "%5s%s%19s\n"  ,'','Status             : ', ${$self}{status};
        #printf  "%5s%s%19s\n"  ,'','Date               : ', ${$self}{date};
        #printf  "%5s%s%20s\n"  ,'','Time HH:MM:SS      : ', ${$self}{time1};
        #printf  "%5s%s%s\n"    ,'','Start  Time        : ', ${$self}{start};
        #printf  "%5s%s%s\n"    ,'','Elapse Time        : ', ${$self}{elapse};
        #printf  "%5s%s%20s\n"  ,'','Elapse Time New    : ', ${$self}{elapse2};
        #printf  "%5s%s%19s s\n",'','Run    Time        : ', $delta/1000/1000/1000;

        #printf  "%5s%s%s\n",'','Create Timing      : ', join ' ',@{${$self}{start1}};
        bless   $self, $class;
        return  $self;
}#sub   new

sub     elaborate   {
        my  (   $self                                                           #   [Application storage]
            ,   $select )   =   @_;                                             #   [Named parameter]       list of parameter to unpack
        my  $n  =   subroutine ('name');                                        #   App::Dbg::subroutine('name')
        my  $w  =   maxwidth( [ keys %{$self} ] );
        #printf  "%*selaborate( %s )\n",5,'', $self     if ( $$self{debugging} );    #   --debubgging
        printf  "%*s%s( %s )\n",5,'', $n, $self  if ( $$self{debugging} );    #   --debubgging
        my  $cnt=   0;
        foreach my $key ( @{$select} ) {                                        #   Evaluate these keys in applicaiton
        if ( exists $$self{$key} ) {                                            #   if the subscription exits in application
            #   Controll what needs to be unpacked (only selected
            printf "%2s%*s%*s ",$cnt++,5,'',$w,$key    if ( $$self{debugging} );
            my  $nk =   $key.'_up';                                             #   new key _up unpacked
            if ( ref    $$self{$key} eq 'ARRAY' ) {
                printf " %*s Ref",10, ref $$self{$key} if ( $$self{debugging} );            
                $$self{$nk} =   unpack_string(   $$self{$key}   );
            } else { # handle array reference
                if ( ref    $$self{$key} eq '' ) {                              #   SCALAR and not Reference !!
                   printf " %*s %s",10,'SCALAR', $key  if ( $$self{debugging} );
                   printf " <%s>", $$self{$key}        if ( $$self{debugging} );
                   if ( $$self{$key} =~ m/[,]/ ) {                              #   packed string to unpack
                       $$self{$nk} =   unpack_string( [ $$self{$key} ] );       #   convert string into [ArrRef] ,newkey
                   }# if CS packed string                                       #   comma separate
                }# if ref

            }# if not array reference
            printf "\n" if ( $$self{debugging} );
        }# for all existent (real) entries/subscription/keys
        }#iterarte data structure
        #   Log::log_arrayref       ( [ArrRef], $Logfile, format )

        $$self{d1}    =   intersect_api ( $$self{dbg_up}, $$self{subs} );       #   Create the list of reporting subroutines
        $$self{debug} =   array2hash    ( $$self{d1} );                         #   Create an associate hash of subroutines
        inspect_api( $self,'tags' )  if ( $$self{debugging} );                  #   --debugging on CL command line
        if( exists $$self{logging} ) {
            if( exists $$self{debugging} ) {
                t_info( $$self{logpath}    , { newline  => 1 } ) if( -e $$self{logpath} );
                #t_info( $$self{raw_dbg_log}, { newline  => 1 } );   # if( $$self{debugging} );
                #t_info( $$self{raw_sub_log}, { newline  => 1 } );   # if( $$self{debugging} ); 
                #t_info( $$self{debug_log}  , { newline  => 1 } );   # if( $$self{debugging} );
            }
            log_arrayref ( $$self{dbg_up}, $$self{raw_dbg_log}, { number    =>  1 } );
            log_arrayref ( $$self{subs}  , $$self{raw_sub_log}, { number    =>  1 } );
            log_arrayref ( $$self{d1}    , $$self{debug_log}  , { number    =>  1 } );
        }# enable logging
        return;                                                                 #   No derivative shall be build, default return;
}#sub   elaborate

sub     get     {
        my  (   $self
            ,   $parameter  )   =   @_;
        my  $n  =   subroutine('name');                                         #   Determine the name of THIS subroutine
        printf  "%*s%s( \$self{%s} )\n",5,'',$n,$parameter if ( debug($n) );
        my  $v  =   'unknown/unused parameter';
        if  (   defined $$self{$parameter}  ) {
            my  $type   =   ref $$self{$parameter};
            printf  "%5s'Reference Type : '%s\n",'',$type  if ( debug($n) );
            $v  =   $$self{$parameter};                                         #   Select the appliction parameter
        } else {
            if ( debug($n)) {
                printf  "\n";
                printf  "%*s%s( \$self{%s} )\n",5,'',$n,$parameter;
                printf  "%*sParameter      : %s %s\n",5,'',$parameter,$v;       #   Keep the warning
            }#if debug
        }
        return  $v;                                                             #   Return reference, identified by parameter
}#sub   get

sub     update  {
        my  (   $self
            ,   $options )  =   @_;                                             #   {Secondary sourceHashRef}, Prevalent over new()
        my  $w  =   maxwidth ( [ keys %{$options} ] );
        foreach my $k   (  keys %{$options} )  {
            #printf  "%*s%*s = %s\n",$i,$p,$w,$k,${$self}{$k};                  <<< false statment
            #printf  "%*s%*s = %s\n",5,'',$w,$k,${$options}{$k};
            ${$self}{$k} =  ${$options}{$k};                                    #   
        }#for all new value pairs
        #my  %options    =   @_;
        #return  { %{$self, %options };
        #$self   =  { %{$self}, %{$options} }; 
        return;                                                                 #   avoid implicite return value 
}#Sub   update



sub     inspect {
        my  ( $self, $format )  =   @_;
        my  $i  =   ${$format}{indent};
        my  $p  =   ${$format}{pattern};
        my  $s  =   ${$format}{spacer};
            $i  //= 5;
            $p  //= '';
            $s  //= 0;
        my  $w  =   maxwidth ( [ keys %{$self} ] );
        if  ( ${$format}{header} )   {
            printf "%*s>>%s<<\n",$i,$p,${$format}{header};
        }# Header
        my  $h_ref  =   $$self{self};
        #list_ref ( $self, $format );                                           #   DataStructure DS.pm
        list_ref ( $h_ref, $format );                                           #   DataStructure DS.pm
        foreach ( 1..$s )   {
            printf  "\n";
        }#vertical terminal format
        return;
}#sub   inspect

#sub     get_subs    {
#        my  (   $paths  )   =   @_;                                             #   [ArrRef] w/ general, application specific Libraries
#        my  $list   =   [];
#        my  %subs   =   (   subs    =>  $list   );
#        for my  $lpath  ( @{$paths} )   {                                       #   library path; $ENV{PERLPATH}, $ENV{PROJPATH}.APPLICATION
#            my  $subs   =   get_lib_subs( $lpath );  
#            push( @{$list}, @{$subs} );                                         #   Collect all linked module subroutines
#        }# for all libraries
#        return  %subs;                                                          #   %options    =   (   subs    =>  [ ListOfSubroutines ]   )
#}#sub   get_subs


sub     get_subs    {
        my  (   $paths  )   =   @_;                                             #   [ArrRef] w/ general, application specific Libraries
        my ($ml_r,$mh_r)    =   ( [], {} );                                     #   Initialize data structure
        for my  $lpath  ( @{$paths} )   {                                       #   library path; $ENV{PERLPATH}, $ENV{PROJPATH}.APPLICATION
            my ($mlr,$mhr)  =   get_FullModulePath  ( $lpath  );                #   return absolute/full path module filename .pm
            push( @{$ml_r}, @{$mlr} );                                          #   merge $ArrRef
            $mh_r   =   { %{$mh_r}, %{$mhr} };                                  #   merge $HshRef
        }# for all libraries
        my  $nsh_r  =   get_Namespace   ( $mh_r  );
        my  ($list
            ,$Hshl) =   get_Subroutines ( $nsh_r );                             #   $list = [$ArrRef]
        my  %subs   =   (   subs    =>  $list    );

        my  $logf1= "$ENV{PERLPROJ}"."/IP_XACT/logs/filename_fullfilename.log"; #   better description
        my  $logf2= "$ENV{PERLPROJ}"."/IP_XACT/logs/pkgname_namespace.log";
        my  $logf3= "$ENV{PERLPROJ}"."/IP_XACT/logs/subroutines.log";
        my  $logf4= "$ENV{PERLPROJ}"."/IP_XACT/logs/subroutines2.log";
        my  $logf5= "$ENV{PERLPROJ}"."/IP_XACT/logs/subroutines3.log";

        log_hashref ( $mh_r , $logf1 );                                         #   Module Path HshRef
        log_hashref ( $nsh_r, $logf2 );                                         #   Namespace HshRef
        log_arrayref( $list , $logf3 );
        log_hashref ( $Hshl , $logf4 );                                         #   Namespace HshRef
        log2_hashref( $Hshl , $logf5 );                                         #   Namespace HshRef

        return  %subs;                                                          #   %options    =   (   subs    =>  [ ListOfSubroutines ]   )
}#sub   get_subs


#----------------------------------------------------------------------------
#       P R I V A T E  M E T H O D S



sub     get_all_subroutines {
        my  $all_modules=   get_ModulesInstalled ( "$ENV{PERLPATH}");           #   [ArrRef] w/ all installed module file names
        my  $all_pkg    =   list_modules( $all_modules, 'package' );            #   [ArrRef] Theoretical a module could contain multiple packages
        my  $all_symbol =   get_all('CODE', $all_pkg);                          #   {HshRef} w/ all symbols from all packages of interest (also loaded)
        return $$all_symbol{CODE};                                              #   [ArrRef] w/ all subroutines                   
}#sub   get_all_subroutines

sub     compile_subroutines {
        my ($ml_r,$mh_r)    =   get_FullModulePath  ( $ENV{PERLPATH}    );
        my  $nsh_r          =   get_Namespace       ( $mh_r             );
        my  $subs_r         =   get_Subroutines     ( $nsh_r            );
        return  $subs_r;
}#sub   compile_subroutines

sub     get_lib_subs    {
        my  (   $path   )   =   @_;
        printf  "%*sget_lib_subs( %s )\n",5,'',$path;
        my ($ml_r,$mh_r)    =   get_FullModulePath  ( $path  );
        my  $nsh_r          =   get_Namespace       ( $mh_r  );
        my  $subs_r         =   get_Subroutines     ( $nsh_r );                 #   [ArrRef] or list of subroutines
        log_hashref ( $mh_r,  "$ENV{PERLPROJ}"."/IP_XACT/logs/filename_fullfilename.log" );   #   better description
        log_hashref ( $mh_r,  "$ENV{PERLPROJ}"."/IP_XACT/logs/filename_pkgname.log"      );
        log_hashref ( $nsh_r, "$ENV{PERLPROJ}"."/IP_XACT/logs/pkgname_namespace.log"     );
        return  $subs_r;
}#sub   get_lib_subs

sub     inspect_api {
        my  (   $self                               
            ,   $section    )   =   @_;                                         #   subcategory of configuration options
        my  @tmp=   ( split(/::/, (caller(1))[3]) );                            #   FunctionName which called THIS subroutine == App::Dbg::subroutine('name')
        my  $n  =   pop @tmp;                                                   #   [Fi]    Work around - Experimental pop on scalar is now forbidden at
        my  $w  =   maxwidth( $$self{$section} );
        my  $verbose    =  $$self{debugging};                                   #   Commandline --debugging
        if( $verbose ) {
            printf  "%*s%s( \$\$self{%s}, )\n",5,'',$n,$section;
            printf  "%*s%*s %s %s \n",5,'',$w,'Entries','Exist','Define';
            printf  "%*s%s\n",5,'','='x 20;
            foreach my $k ( sort @{$$self{$section}} ) {                        #   $$self{tags} [$ArrRef] list of keys
                printf  "%*s%*s %4s %5s",5,'',$w,$k
                        , exists $$self{$k}, defined $$self{$k};
                printf  "\n";
            }#
            printf  "\n";
        }#if verbose CL --debugging
        return;                                                                 #   Default return statement
}#sub   inspect_api

#
#       DS::intersect() keep them synchronized
#

sub     intersect_api   {                                                       #   Schnittmenge, Intersection
        my  (   $a_ArrRef                                                       #   Set A
            ,   $b_ArrRef                                                       #   Set B
            ,   $verbose    )   =   @_;                                         #   expernally set
        my  $tmp    =   [];                                                     #   intersection ( A, B)
        my  @tmp=   ( split(/::/, (caller(1))[3]) );                            #   FunctionName which called THIS subroutine == App::Dbg::subroutine('name')
        my  $n  =   pop @tmp;                                                   #   [Fi]    Work around - Experimental pop on scalar is now forbidden at
        printf  "%*s%s( [aRef], [bRef] )\n",5,'',$n         if ($verbose);      #   debug vestigial
        printf  "%*s             (  %4s, %6s  )\n",5,''
                ,scalar(@{$a_ArrRef}),scalar(@{$b_ArrRef})  if ($verbose);
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
        printf  "%*sSize of %s() %s\n\n",5,'',$n,$#{$tmp}+1 if ($verbose);      #   debug   vestigial
        return $tmp;
}#sub   intersect_api


#----------------------------------------------------------------------------
# End of module App
1;
