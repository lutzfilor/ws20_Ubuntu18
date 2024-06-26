package IP_XACT::App;
# Author    Lutz Filor
# Phone     408 807 6915
# 
# Purpose   IP_XACT designer, editor, validator, for fast prototyping
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
use version; my $VERSION = version->declare('v1.01.10');                        #   v-string using Perl API

#----------------------------------------------------------------------------
#       U s e r   Perl - L i b r a r i e s
 
use lib				"$ENV{PERLPATH}";                                           #   Include path to @INC, general
use lib             "$ENV{PERLPROJ}";                                           #   Include path to @INC, specific
                           
use App             qw  (   get
                            update
                            inspect
                            get_subs

                            elaborate
                            subroutine

                            terminate   );                                      #   Create Application framework
                            
use App::Dbg        qw  (   debug
                            subroutine  );

use DS::Hash        qw  (   list_hash   );

use IP_XACT::API    qw  (   get_api     
                            get_config  );                                      #   Add Command line API, App configuration

use IP_XACT::App    qw  (   new
                            terminate   );

my  %default    =   (   Author  =>  'Lutz Filor'
                    ,   start1  =>  [localtime()],                              #   Current Time
                    ,   Created =>  '10/04/2020'    );                          #   Default Initial App configuration

my  $up =   [ qw( dbg file subs ) ];                                            #   list of parameter to unpack, application

#---------------------------------------------------------------------------
#       I N T E R F A C E

use Exporter qw (import);
use parent 'Exporter';                                                          #   replaces base; base is deprecated

#our @EXPORT   =    qw();                                                       #   Implicite import deprecated

our @EXPORT_OK =    qw(     new
                            get

                            debug
                            subroutine

                            get_options
                            terminate   );                                      #   Explicite import

our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK ]
                   );

#----------------------------------------------------------------------------
#       C O N S T A N T S

#Readonly my  $FAIL  =>   1;                                                    #   default setting, Success must be determinated
#Readonly my  $PASS  =>   0;                                                    #   PASS value      ZERO as in ZERO failure count
#Readonly my  $INIT  =>   0;                                                    #   Initialize to   ZERO

use App::Const  qw( :ALL );                                                     #   Prove of concept, of external defined Constants
#----------------------------------------------------------------------------
#       S U B R O U T I N S

sub     new {                                                                   #   Class Constructor
        my  ( $class                                                            #   Object Name
            , %options  )=  @_;                                                 #   Allow Parameter Hash input from program call
        printf "\n";                                                            #   Separate command line from execution
        my  $self   =   {   start   =>  `date +%T.%N`                           #   HH:MM:SS Time stamp & Nanoseconds - 0.### ### ### [s]
                        ,   warn    =>  $INIT                                   #   Iniate warn counter         , mendatory
                        ,   error   =>  $INIT                                   #   Iniate error counter        , mendatory
                        ,   version =>  $VERSION                                #   Version                     , mendatary
                        ,   %options                                            #   Provide default parameter   , optional on application layer
                        ,   get_options( %default )                             #   Provide default parameter
                        ,   get_config()                                        #   IP_XACT::API::get_config()  , optional
                        ,   get_api ( )                                         #   IP_XACT::API::get_api()     , optional
                        ,   get_subs( [("$ENV{PERLPATH}"
                                       ,"$ENV{PERLPROJ}"."/IP_XACT")] )         #   Provide list of all included subroutines
        };#     class storage                                                   #   build and initiate
        chomp   ${$self}{start};                                                #   Clean up, remove newline character
        #elaborate( $self );                                                    #   automate unpacking
        elaborate( $self, $up );                                                #   automate unpacking, explicite list
        debug(  '', $self   );                                                  #   initialize $debug($name, undef)
        bless   $self, $class;
        return  $self;
}#sub   new


#       P R I V A T E  -   S U B R O U T I N E S
#----------------------------------------------------------------------------

sub     get_options {
        my  (   %options    )   =   @_;
        return  %options;
}#sub   get_options

#----------------------------------------------------------------------------
#   END of IP_XACT/App.pm 
__END__
