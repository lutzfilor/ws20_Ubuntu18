#!/usr/bin/perl -w
use strict;
use warnings;
use version; our $VERSION = version->declare('v1.01.15');                           #   v-string using Perl API

use lib				"$ENV{PERLPATH}";                                               #   Add Include path to @INC
use DS::Array       qw  /   maxwidth
                            list_array      /;                                      #   DS::Array::Functions
use DS::Hash        qw  /   SizeOfHashRef
                            determineWidth
                            max_key     
                            max_value
                            list_hash       /;                                      #   DS::Hash::Functions
use App             qw  /   new             /;                                      #   Create  Application
use App::Const      qw  /   :ALL            /;                                      #   Global  defined Constants
use App::Dbg::ST    qw  /   get_FullModulePath 
                            get_Namespace
                            get_Symbols
                            get_Version
                            get_Subroutines
                            list_Namespace  /;                                      #   Debug Information from System table
use Dbg             qw  /   subroutine
                            debug           /;                                      #   Debug information on Terminal

use Terminal        qw  /   :ALL            /;                                      #   Data presentation on Terminal

package foo;
   our $some_var;
   sub func1 { return 'func1'}
   sub func2 { return 'func2'}

package main;
my $w   = 0;
my %opts    =   (   owner               =>  'Lutz Filor',                           # Author    Maintainer
                    call                =>  join (' ', @ARGV),                      # Capture   command line input 
                    program             =>  $0,                                     # Script    Name
                    version             =>  $VERSION,                               # Script    Version
                    log_path_default    =>  'logs',                                 # Default   logging path appendix for each trace
                    subs                =>  [   qw  (   debug
                                                        DebugControl
                                                        check_command_line
                                                        flush_test_sequence
                                                        parse_init
                                                        observe_extraction
                                                        valid_init
                                                        store_init
                                                        compile_sequence
                                                        scan_sequence
                                                        writing_sequence
                                                        comment_line
                                                        convert_baseaddress
                                                        convert_blockrange
                                                        convert_databussize
                                                        convert_reserve
                                                        is_subset
                                                        map_subdirectory
                                                        map_subroutines
                                                        write_array_to_file
                                                        initialize
                                                        new
                                                        extract_array
														extract_hash 
                                                        process_instances
                                                        get_references
                                                        get_subsection
                                                        get_attribute
                                                        get_accesspath
                                                        get_zrecord
                                                        get_section
                                                        get_headers
                                                        get_objlst
                                                        get_record
                                                        get_values
                                                        get_zdata
                                                        get_vpair
                                                        grep_data
														build_table
														build_aoi_table
														insert_worksheet
														get_list
                                                        get_span
                                                        test_json
                                                        list_ref
                                                        get_uri
                                                        merge_data
														extraction
														revise_workbook
														deepclone
														discard_logs
														validate_setup
														overwrite_setup
														_printf_scalar
														_printf_scalar2
                                                        add_new_monitor
                                                        signal_connecting
                                                        read_specification
                                                        implement_specification
                                                        getSymbolTableHash
                                                    )                               # List of Subroutines for debugging
                                            ],
					setup				=>	{	initial =>	{},
												ovrwrit	=>	{},
												final	=>	{},
											},										# Hash of control flow
 
                    units_of_data_size  =>  [   qw  (   bit byte    )   ],          # Default unit of data size
                    legal_data_prefixes =>  [   qw  (   k M G T P E Z Y )   ],      # Legal   prefixes for units of data
                    indent              =>  5,                                      # Default indentation
                    preamble            =>  ' ... ',                                # Default preamble
                    indent_pattern      =>  '',                                     # Default indent pattern Whitespace
                ); 
 
#################################################################################################################################
#
# main entry
#
#=================================================================================================================================

sub     callable {
        my ($x) = @_;
        return defined(&$x);
}#sub   callable

sub     forAllModules {
        my ($l) = @_;
}#SUB   forAllModules

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
            push( @{$l}, get_Symbols($v) );
            # exit();
            #printf "\n";
        }# while
        return $l;                                                              #   List of Subroutines
}#sub   getListofSubroutines



    #exit;

    ### printf "\n\n%5s%s\n",'',$ENV{PERLPATH};
###    printf "\n*********\n\n";
    my ($ml_r,$mh_r) =  get_FullModulePath($ENV{PERLPATH});
###    printf "%*s%s\n",5,'','List Module Array : ';
###    list_array ($ml_r);
    #printf "\n";
    #exit(); 
    ### printf "\n\n";
    ### printf "%*s%s%2s\n",5,'','Size of Hash : ',SizeOfHashRef($mh_r);
    ### printf "%*s%s\n",5,'','List MyModule Hash : ';
###    printf "\n*********\n\n";
###    list_hash ($mh_r);
###    printf "\n*********\n\n";

    ### printf "\n\n";
    printf "%*s%s\n",5,'','get_Namespace() : ';
    my $nsh_r = get_Namespace($mh_r);
    printf "\n*********\n\n";
    list_hash ($nsh_r);
    printf "\n*********\n\n";
    list_Namespace( $nsh_r );
    get_Version( $mh_r );
    #exit(); 

    my $subs_r = get_Subroutines( $nsh_r );

    list_array( $subs_r, {align=>'left', newline=>1} );

    ### #while (my($k,$v) = each ( %{$nsh_r} )) {
    ### my $i = 1;
    ### my $subs    =   [];
    ### while ( my ($k, $packagename) = each ( %{$nsh_r} )) {
    ### foreach my $packagename ( sort { "\L$a" cmp "\L$b" } keys ( %{$nsh_r} )) {
    ###      printf "%5s%s >>\n", '', $packagename;
    ### ###     #getSymbolTableHash($packagename);
    ### ###     push ( @{$subs}, @{get_Symbols($packagename,'CODE')} );
    ### ###     #getSymbolTableHash('Application::Constants');
    ### ###     #getSymbolTableHash('Dbg');
    ### ###     #getSymbolTableHash('DS');
    ### ###     #last if ( $i > 2 );
    ### ###     $i++;
    ### }# while
    ### printf "\nResults";
    ### printf "\n*********\n\n";
    ### printf "\nList the subroutines::";
    ### list_array ($subs, {align=>'left'});
    ### printf "\n*********\n\n";

    #my $lofs = getListofSubroutines($nsh_r);
    #list_array ( $lofs, {align=>'left', newline=>1} );
    ### printf "\nFinal Results";
    ### printf "\n*********\n\n";
    ### list_array ($subs, {align=>'left'});
    ### printf "\n*********\n\n";
    exit;

