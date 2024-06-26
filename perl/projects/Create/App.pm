package Create::App;
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   Create Perl project designer, for fast prototyping
#           
#           [$up]   is a list of explicite parameter, that need to be expanded
#
#           elaborate()     is a methode to, elaborate the class structure
# 
#----------------------------------------------------------------------------
#       I N S T A L L E D  Perl - L i b r a r i e s

use strict;
use warnings;

use feature 'state';
use version; my $VERSION = version->declare('v1.01.07');                        #   v-string using Perl API

#----------------------------------------------------------------------------
#       U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                           #   Include path to @INC, general
use lib             "$ENV{PERLPROJ}";                                           #   Include path to @INC, specific

use Terminal        qw  (   t_info
                            t_list
                            t_warn
                            t_blank
                            t_function_header   );                              #   Provide standard Terminal presentation

use App             qw  (   get
                            update
                            inspect
                            inspect_api
                            
                            get_subs

                            elaborate
                            subroutine
                            debug

                            terminate   );                                      #   Create Application framework
                            
use DS::Hash        qw  (   list_hash   );

use Create::API     qw  (   get_api     
                            get_config  );                                      #   Add Command line API, App configuration

my  %default    =   (   Author  =>  'Lutz Filor'
                    ,   start1  =>  [localtime()],                              #   Current Time
                    ,   Created =>  '10/29/2020'    );                          #   Default Initial App configuration

my  $up =   [ qw( dbg file subs project) ];                                     #   list of parameter to unpack, application

#---------------------------------------------------------------------------
#       I N T E R F A C E

use Exporter qw (import);
use parent 'Exporter';                                                          #   replaces base; base is deprecated

#our @EXPORT   =    qw();                                                       #   Implicite import deprecated

our @EXPORT_OK =    qw(     new
                            create_guard
                            get

                            debug
                            subroutine

                            checking_environment

                            get_options
                            terminate   );                                      #   Explicite importn

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

use App::Const  qw( :ALL );                                                     #   Prove of concept, of external defined Constants

#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     new {                                                                   #   Class Constructor
        my  ( $class                                                            #   Object Name
            , %options  )=  @_;                                                 #   Allow Parameter Hash input from program call
        printf "\n";                                                            #   Separate command line from execution
        my  $self   =   {   start   =>  `date +%T.%N`                           #   HH:MM:SS Time stamp & Nanoseconds   - 0.### ### ### [s]
                        ,   today   =>  `date -u +"%Y/%m/%d"`                   #   YYYY/MM/DD      `date -u +"%Y/%m/%d"` YYYY-MM-DD
                        ,   warn    =>  $INIT                                   #   Iniate warn counter         , mendatory
                        ,   error   =>  $INIT                                   #   Iniate error counter        , mendatory
                        ,   version =>  $VERSION                                #   Version                     , mendatary
                        ,   %options                                            #   Provide default parameter   , optional on application layer
                        ,   get_options ( %default )                            #   Provide default parameter   , default from local/this file
                        ,   get_config  (   )                                   #   Create::API::get_config()   , optional from applicaiton 
                        ,   get_api     (   )                                   #   Create::API::get_api()      , optional, Commandline options
                        #==============================
                                                                                #   $options{debugging} available past this marker
                        #==============================
                        ,   get_subs( [("$ENV{PERLPATH}"                        #   Based on ENVIRONMENT vars for general, specific applic modules
                                       ,"$ENV{PERLPROJ}"."/Create" )] )         #   Automatically compile list of all used/linked subroutines of Application
        };#     class storage                                                   #   Build and initiate
        chomp   ${$self}{start};                                                #   Clean up, remove newline character
        chomp   ${$self}{today};                                                #   Clean up, remove newline character
        inspect_api( $self, 'tags' );                                           #   Debugging vestigial, looking into CL options 
        elaborate( $self, $up   );                                              #   Automate unpacking, explicite list
        debug    ( ''   , $self );                                              #   Initialize $debug($name, undef), name is not used for initialization
        #========================
                                                                                #   Commandline debugging available past this marker
        #========================
        create_guard    ( $self );                                              #   Early termination against required parameter EXIT !!
        prepare_cloning ( $self );                                              #   Add hash w/ search & replace pairs for cloning
        printf  "%*s%s\n\n",5,'','=' x 75 if ( $$self{debugging} );
        bless   $self, $class;
        return  $self;
}#sub   new


#       P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------

sub     get_options {
        my  (   %options    )   =   @_;
        return  %options;
}#sub   get_options

sub     create_guard    {
        my  (   $self   )   =   @_;
        my  $n  =   subroutine('name');                                         #   subroutine name
        printf "%*s%s()\n",5,'',$n if( debug($n) );
        my  $msg    =   "Useage --project=<Projectname> not specified !!";
        unless  (   $$self{project}     )    {
            t_warn  ( $msg,   {   before  =>  1,  after   =>  2   }  );
            exit 1;                                                             #   Termin
        }
        return;                                                                 #   Default return Statement
}#sub   create_guard

sub     checking_environment    {
        my  (   $self   )   =   @_;
        return;
}#sub   checking_environment

sub     prepare_cloning {
        my  (   $self   )   =   @_;
        my  $n  =   subroutine('name');                                         #   subroutine name
        printf "%*s%s()\n",5,'',$n if( debug($n)    );
        if  (   defined $$self{project} )   {
            my  $clone  =   {   '<DATUMTAG>'    =>  $$self{today}
                            ,   '<project>'     =>  $$self{project}[0]
                            ,   '<Module>'      =>  ucfirst($$self{project}[0])    };
            $$self{clone}   =   $clone;
        }#if --project=ProjectName defined
        return;
}#sub
#----------------------------------------------------------------------------
#   END of Create/App.pm 
__END__
