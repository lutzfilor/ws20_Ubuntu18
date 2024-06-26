package Porting;
# File          ~/ws/perl/lib/Porting.pm
#
# Author        Lutz Filor
# 
# Synopsys      Migration Rubicon AMS   ->  Rubicon UVM dig_top TB
#
#               Derive Test Information from AMS testbench  derive_test_info()
#               Create      dig_top_uvc_test_seq_lib.sv     create_test_seq_lib()
#               Create      dig_top_uvc_test_lib.sv         create_test_lib()
# 
#----------------------------------------------------------------------------
#       I M P O R T S 

use strict;
use warnings;
use Switch;                                             # Multi choice selection

use lib "$ENV{PERLPATH}";                               # Add Include path to @INC

use Term::ANSIColor qw  (   :constants  );              # available
#   print BLINK BOLD RED $msg, RESET;
use Terminal    qw  (   t_warn
                        t_info
                        t_note
                        t_okay
                        t_exit
                        t_usage );

use DS      qw  (   list_ref    );
use List    qw  (   max_width
                    clone_aref  );                      # find max size entry [$ArrRef]
use Hash    qw  (   list_HashRef    );                  # list formated content of {$HashRef}
use File::IO::UTF8  qw  (   read_utf8
                            write_utf8  );


#---------------------------------------------------------------------------
#       I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.13");

use Exporter qw (import);
use parent 'Exporter';                                  # replaces base; base is deprecated


our @EXPORT    =    qw(
                      ); # Porting                      # Deprecate implicite exports

our @EXPORT_OK =    qw(     get_setup
                            merge_info
                            update_test_lib
                            get_fullname
                            porting_dms_2_uvm
                            check_project_setup
                      ); # Porting                      # PREFERED explicite exports

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       V A R I A B L E S

my $rubicon =   {   project         =>  'Rubicon'
                ,   user            =>  'lfilor'
                ,   path            =>  $ENV{PERLPATH}.'/Porting'                           #   /users/lfilor/ws/perl/lib/Porting
                ,   testcase        =>  'bias_power_up'
                ,   test_lib        =>  $ENV{DIGWORKAREA}.'/dig_top/verif/tb_uvm/test_lib.sv'
                ,   test_lib_log    =>  $ENV{PERLPROJ}.'Rubicon/logs/test_lib.log'
                ,   testcase_log    =>  $ENV{PERLPROJ}.'Rubicon/logs/testcase.log'
                ,   testcaselist    =>  $ENV{PERLPROJ}.'/TCG/Rubicon/Testcase.list'         #   Fix me
                ,   log_sdir        =>  $ENV{PERLPROJ}.'Rubicon/logs'
                ,   dms_sdir        =>  $ENV{DIGWORKAREA}.'/dig_top/verif/tb/tests'
                ,   uvm_sdir        =>  $ENV{DIGWORKAREA}.'/dig_top/verif/tb_uvm/tests_uvm'
                ,   tasklibs        =>  [   $ENV{DIGWORKAREA}.'/dig_top/verif/tests_uvm/chgr_top_base_test.sv'
                                        ,   $ENV{DIGWORKAREA}.'/dig_top/verif/tests_uvm/i2c_api_tasks.sv'
                                        ,   $ENV{DIGWORKAREA}.'/dig_top/verif/tests_uvm/reg_model_tasks.sv'
                                        ,   $ENV{DIGWORKAREA}.'/dig_top/verif/tests_uvm/tb_api_tasks.sv'
                                        ]#[EndOfArray]
                ,   keywords        =>  [   qw  (   //
                                                    initial
                                                    begin
                                                    init_ports
                                                    init_i2c
                                                    init_OTP
                                                    wait
                                                    dig_top
                                                    real_force_ramp
                                                    check_real
                                                    test_timeout
                                                    end_of_test
                                                    end             )   
                                        ]#[EndOfKeywords]
                ,   keywords2       =>  [   qw  (   include         )   
                                        ]#[EndOfKeywords] for test_lib.sv
                ,   substitution    =>  {   end_of_test     =>  "end_of_test\(\)\;"
                                        ,   initial         =>  'initial'
                                        ,   dig_top         =>  '`dig_top'
                                        }#{substitution strings}
                ,   replace         =>  {   dig_top         =>  'p_sequencer'
                                        ,   initial         =>  '`TEST_SEQUENCE_BEGIN' 
                                        ,   end_of_test     =>  '`TEST_SEQUENCE_END'
                                        }#{EndOfHash} replacements for substitutions
                ,   remap           =>  {   force_VBAT      =>  'p_sequencer.misc_vif.force_VBAT'
                                        ,   force_VBUS1     =>  'p_sequencer.misc_vif.force_VBUS1'
                                        ,   force_VBUS2     =>  'p_sequencer.misc_vif.force_VBUS2'
                                        }#{Signal Interface} remappiing
                ,   files           =>  [   qw  (   test_lib
                                                    testcase    )
                                        ]#[Files] to be tested
                ,   pathes          =>  [   qw  (   dms_sdir
                                                    uvm_sdir
                                                    path        )
                                        ]#[AccessPathes]
                };

#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     get_setup   {
        my  (   $select )  =    @_;                             #   select $project
        my  $f  =   {   fullcolor   =>  1                       #   configure message, whole message colored
                    ,   newline     =>  2   };                  #   vertical format 2 newlines
        my  $project;                                           #   {HashRef}
        my  $msg    =   'Project not defined';
        printf  "%*s%s : %s\n",5,'','Select project  ', $select;
        switch ( $select ) {
            case    m/\bRubicon\b/ { $project   =   $rubicon; }
            else    { t_warn( $msg, $f); exit;  }               #   
        }#switch
        return  $project;
}#sub   get_setup


sub     check_project_setup {
        my  (   $setup                                          #   {$projectHashRef}   
            ,   $file   )  =   @_;                              #   $filename
        my  $testcase   =   ${$setup}{testcase};                #   testcase Name
        foreach my $p   (   keys %{$$setup{parameter}} )  {
            test_parameter( $setup, $p  );
        }#for all parameter, to be tested
        test_setup( $setup, 'files'  );
        test_setup( $setup, 'pathes' );
        #my $tmp =   update_test_lib( $setup, 'test_lib' );
}#sub   check_project_se


sub     merge_info  {                                           #   wo HashRef
        my  (   $primary                                        #   {Primary   sourceHashRef}, to be overwritten
            ,   $secondary )  =   @_;                           #   {Secondary sourceHashRef}, be be prevailing information
        my  $s1 = max_width( [keys %{$primary}] );
        my  $s2 = max_width( [keys %{$secondary}], $s1 );
        foreach my $key ( keys %{$secondary} ) {
            if ( defined $$primary{$key} ) {                    #   Providing overwriting Notice
                my  $w =    sprintf "%-*s : %s",$s2, $key
                                ,'comand line owerwrite';
                t_warn (    $w, {   newline =>  1  });
            }#
            $$primary{$key}  = $$secondary{$key};
        }#for all parameter
        return $primary;                                        #   Return Merged Data Structure
}#sub   merge_info


sub     update_test_lib  {
        my  (   $setup  
            ,   $library    )   =   @_;                         #   'test_lib' Name NOT file name
        my  $tmp        =   [];
        my  $out        =   [];
        my  $lib        =   {};
        my  $testcase   =   ${$setup}{testcase};                #   testcase Name
        my  $keyw       =   ${$setup}{keywords2};               #   [KeywordArrayRef]
        my  $test_lib   =   get_fullname($setup, $library);     #   test_lib.sv
        @{$tmp} = read_utf8($test_lib);
        #$out    = analyze_lib( $setup, $tmp, $keyw, $testcase );        #   updated source code w/ injectect test case
        $out    = analyze_lib( $setup, $tmp );                  #   updated source code w/ injectect test case
        return $out;                                            #   return 
}#sub   update_test_lib


sub     get_fullname    {
        my  (   $setup
            ,   $name   )   =   @_;
        my $tmp = 'ToBeImplemented';
        my $tc = $$setup{dms_sdir}.'/'.$$setup{testcase}.'.sv';
        my $op = $$setup{uvm_sdir}.'/'.$$setup{testcase}.'.sv';
        switch ( $name ) {
            case /test_lib/ {   return $$setup{$name}; }      #   library of tests
            case /dms_sdir/ {   return $$setup{$name}; }      
            case /uvm_sdir/ {   return $$setup{$name}; }
            case /path/     {   return $$setup{$name}; }
            case /testcase/ {   return $tc;              }      #   input 
            case /output/   {   return $op;              }      #   output
            else            {   return $tmp;             }
        }#switch
}#sub   get_fullname


sub     porting_dms_2_uvm   {
        my  (   $dmsf                                           #   DMS testcase full filename 
            ,   $setup  )   =   @_;                             #   {ProjSetupHashRef}
        my  $tmp    =   get_dms_sourcecode($dmsf);
        my  $keyw   =   ${$setup}{keywords};                    #   [KeywordArrayRef]
        my  $tc     =   ${$setup}{testcase};
        #list_ref    (   $tmp    );                             #   Testing, development
        my  $log    =   port_dms_to_uvm (   $tmp
                                        ,   $keyw
                                        ,   $setup  );
}#sub   porting_dms_2_uvm

#----------------------------------------------------------------------------
#       P R I V A T E - M E T H O D S


sub     analyze_lib {
        my  (   $setup
            ,   $source     )   =   @_;                         #   [Source Code]
        my  $key;                                               #   detected key in determine()
        my  $lib=   {};
        my  $tmp=   [];
        my  $log=   [];
        my  $testcase   =   ${$setup}{testcase};                #   testcase Name  Testcase filename
        my  $logf       =   ${$setup}{test_lib_log};
       #my  $keyw       =   ${$setup}{keywords2};               #   [KeywordArrayRef] [ListOfKeywords]
        my  $keys       =   ${$setup}{keywords2};               #   [KeywordArrayRef] [ListOfKeywords]
        my  $w  =   length ($#{$source}+1);                     #   Number digits in lines of code
        my  $ln =   0;
        foreach my $line    ( @{$source} )  {
            chomp $line;
            my $file;
            my $found = determine( $line, $keys, \$key );       #   $$SalarRef $key
            my $marker= ($found)?' >>> ':'     ';
            my $ll  =   sprintf "%5s%*s%s%*s %s"
                        ,'',$w,$ln++,$marker,15,$key,$line;
            #printf  "%s\n",$ll;                                #   Turn off terminal
            push ( @{$log}, $ll );                              #   log source code analysis
            if ( $found ) {
                ( $file )   =   $line =~ /"(.*)\"/g; 
               #printf "%36s< %s >\n",'',$file;                 #   Turn off terminal
                $$lib{$file}=   $file;
            }# analyze all library
            push(@{$tmp}, $line);                               #   clone soure code
        }#all lines
        my $m   = sprintf "%s %s",'LogfileName',$logf;
        t_warn  ( $m, { newline => 1, fullcolor =>  1 } );
        write_utf8( $log, $logf );                              #   projects/Rubicon/logs/test_lib.log
        $testcase   .=  ".sv";
        if ( defined $$lib{$testcase} ) {
            my $m   = sprintf "%s %s %s"
                    ,'Testcase',$testcase
                    ,'exists already in   test_lib.sv';
            t_info  ( $m, { newline => 2, fullcolor => 1 } );
        } else {
            my $m   = sprintf "%s %s %s",'Testcase',$testcase,'to be inserted into test_lib.sv';
            t_info  ( $m, { newline => 2, fullcolor => 1 } );
            my  $code   =   sprintf "%s \"%s\"",' `include',$testcase;
            t_info  ( $code, { newline => 2, fullcolor => 1 } );
            push(@{$tmp}, $code);                               #   inject update testcase
        }
        return $tmp;                                            #   return the source code NOT
}#sub   analyze_lib


sub     get_dms_sourcecode  {
        my  ( $filename )   =   @_;                             #   filename
        my  $tmp    =   [];                                     #   initialize output list
        my  $format =   {   before      =>  1
                        ,   fullcolor   =>  1   
                        ,   newline     =>  2   };
        printf  "%5sget_dms_sourcecode( %s )\n",'',$filename;
        if ( -e $filename )  {
            my  $m1 = sprintf   "%s%s%s",'filepath : ',$filename,' exits';
            t_info  ( $m1, $format );
            @{$tmp} = read_utf8( $filename );
            ### my $i   =   0;                                      # development vestigal
            ### my $s   = $#{$tmp}+1;                               # size of array
            ### my $w   = length $s;                                # Number of places
            ### foreach my $n   (@{$tmp}) {
            ###     chomp $n;
            ###     printf "%5s%*s %s\n",'',$w,$i++,$n;
            ### }#debugging read file -> aref
        } else  {
            my  $m1 = sprintf   "%s%s%s",'filepath : ',$filename,' exists NOT';
            t_warn  ( $m1, $format );
            exit -1;
        }# if file not found
        return  $tmp;
}#sub   get_dms_sourcecode

sub     port_dms_to_uvm {
        my  ( $code, $keys, $setup )   =   @_;
        my  $keyw   =   ${$setup}{keywords};                        #   [KeywordArrayRef]
        my  $key;                                                   #   detected key
        my  $hdr    =   1;                                          #   Insert Header
        my  $edr    =   0;                                          #   Remove Tail
        ${$setup}{hstatus} = 1;
        ${$setup}{bstatus} = 0;
        ${$setup}{fstatus} = 0;
        my  $log    =   [];                                         #   Translation logfile
        my  $tmp    =   [];                                         #   Translated UVM source code
        my  $ln     =   0;                                          #   line numbers
        my  $s      =   length ($#{$keys}+1);                       #   horizontal alignment, size
        my  $w      =   length ($#{$code}+1);                       #   horizontal alignment, width
        printf  "%5s%s : %s\n",'','Number of keywords',$#{$keys}+1;
        foreach my $k ( @{$keys} )  {
            printf  "%5s%*s %s\n",'',$w,$ln++,$k;
        }#
        printf  "\n";
        $ln =   0;
        foreach my $line   (   @{$code}    ) {
            chomp $line;
            my $found = determine( $line, $keys, \$key);            #   $$SalarRef
            my $marker= ($found)?' >>> ':'     ';
            my $ll  =   sprintf "%5s%*s%s%*s %s"
                        ,'',$w,$ln++,$marker,15,$key,$line;
            printf  "%s\n",$ll;
            push    ( @{$log}, $ll);
            my $pl= porting ( $line, $key, $ln, $setup);
            push    ( @{$tmp}, $pl );
        }# for all lines
        return  $tmp;
}#sub   port_dms_to_uvm


sub     determine   {
        my  ( $l, $keys, $keyRef )   =   @_;
        my  $hit    = 0;
SEARCH: foreach my $k ( @{$keys} )  {
            $hit    =   _t( $l, $k ); 
            my $key = $keyRef;
            $$key   =   ($hit)?$k:'unknown';
            #$keyRef = \$key;
            last if $hit;
        }#
#LAST:                                                              #   Commented Marker LAST:
        return $hit;
}#sub   determine

sub     _t {                                                        #   testing
        my  (   $l, $p  )   =   @_;                                 #   $line, $pattern
        my $hit;
        if ( $p eq "//" ) {
            $hit = ( $l =~ m/^$p/);
            #printf  "%5s%s\n",'','Coment' if $hit;
        } else {
            $hit = ( $l =~ m/\b$p\b/);
        }
        return $hit;
}#sub   testing

sub     porting {
        my  ( $l, $k, $ln, $setup )  =   @_;
        my  $tmp;
        my  $tc     =   ${$setup}{testcase};                        #   testcase Name
        my  $header =   ${$setup}{hstatus};                         #   Insert Class Macro
        my  $beginr =   ${$setup}{bstatus};                         #   Remove  first Begin-statement
        my  $footer =   ${$setup}{fstatus};                         #   Remove  last  End-statement
        if  ( $header == 1 &&  $k  ne  '//' ) {
            $tmp    =   sprintf "\n`TEST(%s)\n", $tc;
            $tmp   .=   $l;                                         #   ??? Why
            ${$setup}{hstatus}  =   0;                              #   Need to handle 
        } else {
            $tmp    =   $l;
            switch  ( $k )  {
                #case m/[/][/]/     {   $tmp = $l; }
                case m/\/\//        {   $tmp = $l; }
                case m/wait/        {   $tmp =   $l;
                                        $tmp =~  s/\`dig_top/p_sequencer.misc_vif/;
                                       #$tmp = replace ( $k);  
                                    }
               #case m/initial/     {   $tmp = replace( $l, $k, $setup); }
                case m/initial/     {   $tmp =  $l;
                                       #$tmp =~ replace( $l, $k, $setup); 
                                        $tmp =~ s/initial/`TEST_SEQUENCE_BEGIN/g;
                                        ${$setup}{header}   =   0;  #   Header war inserted
                                    }
                case m/begin/       {   if  ( $beginr == 0 ) {
                                            $tmp    =   '';
                                            ${$setup}{bstatus}  =   1;
                                        } else  {
                                            $tmp    =   $l;
                                        }
                                    }
                case m/test_timeout/{   $tmp    =~  s/test_timeout/uvm_top.set_timeout/;
                                    }
                case m/init_ports/  {   $tmp    =   ''; }           #   Removal
                case m/init_i2c/    {   $tmp    =   ''; }           #   Removal
                case m/init_OTP/    {   $tmp    =   ''; }           #   Removal
               #case m/dig_top/     {  $tmp     =   replace( $l, $k, $setup); }
                case m/dig_top/     {   $tmp    =   $l;
                                        $tmp    =~  s/\`dig_top/p_sequencer.misc_vif/;
                                    }
                case m/check_real/  {   $tmp    =   remapping( $l, $k, $setup );
                                    }
               #case m/end_of_test/ {   $tmp    =   replace( $l, $k, $setup); }
                
                case m/end_of_test/ {   $tmp    =   $l;
                                        if  ( $k eq "end_of_test" )  {
                                            printf "%5s%s\n",'','END OF TEST statement';
                                            printf "%5s%s\n",'',$tmp;
                                            $tmp  =~  s/\s*end_of_test\(\)\;/`TEST_SEQUENCE_END/g;
                                            ${$setup}{fstatus}  =   1;
                                        }#
                                    }
                case m/end/         {   $tmp = $l;                  #   Remove only LAST end-statemne
                                        if ( $footer == 1 ) {
                                            printf "%5s%s\n",'','Last END statement';
                                            $tmp  =~  s/^\s*end//g; #   Remove end statment
                                            ${$setup}{fstatus}  =   0;  #   Reset status
                                        } else {
                                            printf "%5s%s\n",'','NOT Last END statement';
                                        }
                                    }
                case m/unknown/     {   $tmp = $l; }
                else                {   $tmp = 'To be translated'; 
                                    }
            }#end of 
        }
        return  $tmp;
}#sub   porting

sub     remapping   {
        my ( $l, $k, $setup )   =   @_;
        my  $tmp    =   $l;
        my  $key = 'unknown';
        my  $rubicon ='not assigned';
        foreach my $sig ( keys %{${$setup}{remap}} ) {
            if  ( $l =~ m/$sig/) {
                $key    =   $sig;
                $rubicon=   ${${$setup}{remap}}{$key};
                printf  "%5s%s( %s ) = %s\n"
                        ,'','remapping',$sig,$rubicon;
                $tmp    =~  s/$sig/$rubicon/;
            }# if match
        }#search of interface
        printf  "%5s%s\n",'',$l;
        printf  "%5s%s\n",'',$tmp;
        return $tmp;
}#sub   remapping


sub     replace {
        my  (   $l, $k, $setup  )   =   @_;

        printf  "%5s%s : %s\n",'','Substitution',${$setup}{substitution}{$k};
        printf  "%5s%s : %s\n",'','Replacement ',${$setup}{replace}{$k};
        if ( $l =~ m/${$setup}{substitution}{$k}/ )   {
            printf  "%5s%s\n",'','Found substitution pattern :';
        } else {
            printf  "%5s%s\n",'','Found substitution pattern : NOT';
        }
        #$l  =~  s/${$setup}{substitution}{$k};/${$setup}{replace}{$k}/g;
        #$l  =~  tr/${$setup}{substitution}{$k};/${$setup}{replace}{$k}/g;
        $l  =~  s/${$setup}{substitution}{$k};/${$setup}{replace}{$k}/;
        printf  "%5s%s : %s\n",'','Output      ',$l;
        return $l;
}#sub   replace


sub     test_parameter  {
        my  (   $setup
            ,   $parameter  )   =   @_;
        #printf "%5stest_parameter( %s )\n",'',$parameter;
        my  $warn   =   $$setup{parameter}{$parameter}{warning};
        my  $conf   =   $$setup{parameter}{$parameter}{confirm};
        my  $usag   =   $$setup{parameter}{$parameter}{usage};
        my  $w  =   max_width([keys %{$$setup{parameter}}]);
        my  $f1 =   {   before  =>  0   
                    ,   newline =>  1   };
        if  ( defined $$setup{$parameter} )  {
            my  $msg  = sprintf "%-*s : %s",$w,$parameter,  $$setup{$parameter};        #   confirmaation  
            t_info  ( $msg, $f1 );
        } else {
            my  $msg  = sprintf "%-*s : %s",$w, $parameter, $warn;                      #   warning
            my  $ndl  = sprintf "%s", $usag;                                            #   usage
            t_warn  ( $msg, $f1 );
            t_usage ( $ndl, {   newline =>  2   } );
            #exit;
        }
}#sub   test_parameter

 
sub     test_setup   {
        my  (   $setup
            ,   $object   )   =   @_;
        printf "%*stest_file( %s )\n",9,'',$object;
        foreach my $f ( @{${$setup}{$object}} ) {
            test_filesetup( $setup, $f );
        }#for all object
}#sub   test_setup


sub     test_filesetup  {
        my  (   $setup                                            #   setup
            ,   $fn         )   =   @_;                             #   fileobj name
        my  $fulln  =   get_fullname( $setup, $fn );              #   full file object name
        my  $set    =   $$setup{parameter}{$fn}{attributes};      #   set of attributes to be tested
        printf "%*s%s : %s\n",20,'',$fn, $fulln;
        printf "%*s%s : %s\n",20,'',$fn, $set;
        foreach my $attribute ( split /\|/, $set  ){
            printf "%*s%s : %s\n",20,'',$fn, $attribute;
            my  $t  =   test_fileobj    ( $fulln, $attribute );
            my  $a  =   defined_action  (   $setup                #   setup
                                        ,   $t                      #   test result (positive logic), action when failing
                                        ,   $fn                     #   file name
                                        ,   $attribute );           #   attribute being tested
            my  $m  =   sprintf "%s %s %s",$a,'defined action for',$fn;
            t_info  ( $m, { newline => 1 }); 
            execute_action( $a, $fulln );                           #   Action on full filename
        }#check all attributes
}#sub   test_filesetup


sub     test_fileobj    {
        my  (   $fobj                                               #   full filename
            ,   $a          )   =   @_;                             #   attribute
        my $fp   =  { newline => 1 };                               #   Format passing
        my $ff  =   { newline => 2, fullcolor => 1 };               #   Format failing
        my  $t  =   0;                                              #   Default fail, false negative
        my $m2  =   sprintf "%s %s",'Unknown    file attribute',$a;
        switch  ($a) {                                              #   attribute
            case /exists/       {   $t = ( -e $fobj ) ? 1 : 0; }
            case /readable/     {   $t = ( -r $fobj ) ? 1 : 0; }
            case /writeable/    {   $t = ( -w $fobj ) ? 1 : 0; }
            case /isLink/       {   $t = ( -l $fobj ) ? 1 : 0; }
            case /isFile/       {   $t = ( -f $fobj ) ? 1 : 0; }
            case /isPath/       {   $t = ( -d $fobj ) ? 1 : 0; }
            else                {   t_warn( $m2, $fp ); }
        my $m2  =   sprintf "%s %s",'Unknown    file attribute',$a;
        }#switch
        my  $v  =   ( $a eq 'exists' ) 
                ?  ( $t == 1 ) ?   "does  " : "does\'t" 
                :  ( $t == 1 ) ?   "is    " : "isn\'t" ;
        my $m   =   sprintf "%s %s %s",$fobj,$v,$a;
        my $m1  =   sprintf "%s %s %s",$fobj,$v,$a;
        t_info ($m, $fp ) if ( $t == 1 );
        t_warn ($m, $ff ) if ( $t == 0 );
        return $t;
}#sub   test_fileobj

sub     defined_action {
        my  (   $setup                                            #   {setupHashRef}}
            ,   $tr                                                 #   test result
            ,   $fn                                                 #   file name
            ,   $a      )   =   @_;                                 #   attribute
        if ( $tr == 0 ) {
            return ( defined $$setup{parameter}{$fn}{$a} )        # action for filename (Obj)
                        ?    $$setup{parameter}{$fn}{$a}
                        :    'none';
        } else {
            return 'none';                                          #   no mitigatiing action
        }# Polarity of the test (positive/negative)                 #   may need review !!
}#sub   defined_action

sub     execute_action    {                                         #   corrective actions
        my  (   $action 
            ,   $fullname   )   =   @_;
        my  $m  =   sprintf "%s : %s",$action,'Unknown ACTION specified';
        my  $f  =    { newline => 2, fullcolor  => 1 };
        switch  ($action)   {
            case /\bnone\b/     {   return; }                       #   no action specified
            case /\bpanic\b/    {   exit;   }                       #   terminate unexpectatly
            case /\bcheckout\b/ {   my  @cmd =  ( "dssc"
                                                , "co"
                                                , "-lock"
                                                , "$fullname" );
                                    system ( @cmd ) == 0
                                    || die "system @cmd failed: $?";
                                }
            else                {   t_warn ( $m, $f );
                                    exit;
                                }#  Undefined action, maintenance required
        }#switch
}#sub   execute_action

#----------------------------------------------------------------------------
# End of module Porting.pm
1;
