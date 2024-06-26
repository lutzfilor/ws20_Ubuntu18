#!/usr/bin/perl -w
  
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   create  Perl Projects
# 
#----------------------------------------------------------------------------
#   I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;

use version; my $VERSION = version->declare('v1.01.03');                        #   v-string using Perl API

#----------------------------------------------------------------------------
#   U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                           #   Include path to @INC, general
use lib             "$ENV{PERLPROJ}";                                           #   Include path to @INC, specific
                           
use Create::App     qw  (   new
                            create_guard
                            get
                            
                            debug
                            subroutine

                            terminate   );

use DS::Hash        qw  (   list_hash   );
use DS::Array       qw  (   list_array
                            maxwidth
                            prepend
                            append      );
use DS::String      qw  (   lowercase   
                            capitalized );

use Terminal        qw  (   t_info
                            t_list
                            t_warn
                            t_exit
                            t_blank
                            t_function_header   );

use File::IO::UTF8  qw  (   read_utf8
                            write_utf8  );

my  $a  =   Create::App->new(   );
    $a  ->  create_guard( );                                                    #   Early termination against required parameter
#=========================================================
debug_debugging( $a );
#=========================================================

create_environment( $a );                                                       #   test debug feature

#=========================================================
$a->terminate();                                                                #   Application planned termination ?? - why did this work w/out import

#   P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------

sub     debug_debugging {
        my  (   $a  )   =   @_;                                                 #   Create a wrapper for this funciotns
        my  $n  =   subroutine('name');                                         #   subroutine name
        if ( debug($n) ) {
            t_function_header( $n );
            my  $dbg    =   $a->get ( 'dbg_up'  );
            my  $subs   =   $a->get ( 'subs_up' );                              #   Get [ArrRef]    list of subroutines
            my  $dhash  =   $a->get ( 'debug'   );                              #   Schnittmenge    associated array
            my  $clone  =   $a->get ( 'clone'   );                              #   Return {HshRef} w/ clone information
        
            list_hash   (   $dhash
                        ,   {   name    =>  '{$dhash}, final dbg reporting list'
                            ,   size    =>  1
                            ,   before  =>  1
                            ,   after   =>  1   }   );
        
            list_array  (   $dbg
                        ,   {   name    =>  '[$dbg], raw list of target subs'
                            ,   size    =>  1
                            ,   trailing=>  1
                            ,   number  =>  'ON'
                            ,   leading =>  1           }   );
            
            #list_array  (   $subs,  {   name    =>  '[$subs]'   
            #                        ,   size    =>  1
            #                        ,   leading =>  2           }   );
            
            list_hash   (   $clone
                        ,   {   name    =>  '{$clone}, list of substitutions'} );   # 
        }# if debug
        return;
}#sub   debug_debugging

sub     create_environment  {
        my  (   $self   )   =   @_;
        my  $project    =   $a->get( 'project_up'   );
        my  $environment=   $a->get( 'environment'  );                          #   application environment
        my  $templates  =   $a->get( 'templates'    );
        my  $n  =   subroutine('name');                                         #   subroutine name
        if ( debug($n) ) {
            t_function_header( $n, 'directory path' );
            #printf "%*s%s()\n",5,'',$n if( debug($n)    );
            #t_info  (  $project,    {}  );                                         #   blinking
            t_list  (  $project,    {   before  =>  1
                                    ,   info    =>  'Create Project'
                                    ,   number  =>  'ON'
                                    ,   color   =>  'GREEN'
                                    ,   after   =>  1           }   );
        }# debug peeking
        $$self{proj}=   capitalize  (   $$project[0] );                         #   project name
        $$self{app} =   lowercase   (   $$project[0] );                         #   application name
        my  $env    =   prepend (   $$project[0],$environment   );
        bulldozer   (   $env    );                                              #   create directory structure
        clone_file  (   $self
                    ,   $a->get ( 'cloning' ) );                                #   $filelist
        create_files(   $self   );
return;
}#sub   create_environment

sub     bulldozer   {
        my  (   $ArrRef    )   =   @_;
        my  $n  =   subroutine('name');                                         #   subroutine name
        t_function_header( $n, 'directory path' );
        my  $w  =   maxwidth( $ArrRef );
        foreach my $path ( @{$ArrRef} ) {
            if( debug($n) ) {
                my  $msg = 
                sprintf  "%*s exists %s",$w,$path,(-e $path)?'':'NOT';
                t_blank( $msg,  {   bold    =>  1
                                ,   newline =>  1   }   );
            }# debugging
            ` mkdir -p "$path"` unless (-e $path);                              #   create directory brench/path
        }# for all $path
        return;
}#sub   bulldozer

sub     clone_file{
        my  (   $self
            ,   $ArrRef                                                         #   file template
            ,   $filename   )   =   @_;                                         #   filenanme to create
        my  $n  =   subroutine('name');                                         #   subroutine name
        my  $w  =   maxwidth( $ArrRef );
        my  $tmp    =   [];
        my  %info   =   %{$$self{clone}};                                       #   Cloning information
        #   read    file
        foreach my $file ( @{$ArrRef} ) {
            if( debug($n) ) {
                my  $msg = 
                sprintf  "%*s exists %s",$w,$file,(-e $file)?'':'NOT';
                t_blank($msg,{ bold    =>  1
                            ,  newline =>  1   } );# if ( -e $file );
            }# enable debugging
            $tmp    =   [ read_utf8   ( $file ) ];
        }#  for all files
        #   modify  file
        foreach my  $line   ( @{$tmp} )  {
            chomp   $line;
            printf  "%*s%s\n",5,'',$line;
            #t_blank(    $line,  {   newline =>  1   }   );
        }# for all lines
        foreach my  $tag ( keys %{$$self{clone}} ){
            #printf  "%*s%s %s\n",5,'',$tag, $info{$tag};
            printf  "%*s%s %s\n",5,'',$tag, ${$$self{clone}}{$tag};
        }
        #   write   file
        return;
}#sub   clone_file

sub     create_files    {
        my  (   $self   )   =   @_;
        my  $n  =   subroutine('name');                                         #   subroutine name
        t_function_header( $n, 'list of files' ) if( debug($n) );
        if  ( !defined $self ) {
            t_exit  ( "Coding Error :: Parameter \$self is undefined",
                    { after   => 2 , fullcolor  => 1 } );
            exit;                                                               #   Do I want this statement here ??
        }# parameter defined, when called
        iterate_files   (   $self, 'clonelist'  );
        return;
}#sub   create_files

sub     iterate_files   {
        my  (   $self
            ,   $list   )   =   @_;
        foreach my $f   ( @{$$self{$list}}  )   {                               #   clonelist selected
            printf  "%*s%s %s %s\n",5,'',$$f{destination}, ${$$self{project}}[0], $$f{subpath};
        }# iterate over all files
        return;
}#sub   iterate_files

#----------------------------------------------------------------------------
#   END of create.pl
__END__
