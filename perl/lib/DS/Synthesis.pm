package DS::Synthesis;
#   File            DS/Synthesis.pm
#
#   Refactored      03-04-2020          
#   Author          Lutz Filor
#
#   
#   Synopsys        DS::Synthesis
#                   Common tasks built on Array references
#   
#                   @array              =   clone_aref  ( [ArrRef] )
#                   $Number_of_Entries  =   size_of     ( [ArrRef] )
#                   $Largest_Entry      =   maxwidth    ( [ArrRef], MinSeed )

use strict;
use warnings;

use POSIX;
use Switch;
#use Readonly;
#----------------------------------------------------------------------------
# I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.12");

use Exporter qw (import);
use parent 'Exporter';                              # parent replaces use base 'Exporter';

use DS::Array     qw    /   list_array
                            maxwidth        /;

#our @EXPORT    = qw    ();#implicite               #   deprecated, 

our @EXPORT_OK  = qw    (   generate_api
                            code_block   
                        );#explicite                #   

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ]
                        );
#----------------------------------------------------------------------------
#       C O N S T A N T S

#----------------------------------------------------------------------------
#       S U B R O U T I N S

my $codelines   =   [(   'if ($value$plusarge("CLI_P=%s",CLI_T)) begin'
                    ,   '    message = $sprintf("DSP_0= %s",CLI_T);'
                    ,   '    if      ( CLI_T == PATTERN )) begin CLI_C = CLI_V; end'
                    ,   '    else if ( CLI_T == PATTERN )) begin CLI_C = CLI_V; end'
                    ,   '    else if ( CLI_T == PATTERN_A )) begin'
                    ,   '         $display("%5s%s you are rediculous\n","",message);'
                    ,   '         $finish();'
                    ,   '         end'
                    ,   '    else begin'
                    ,   '         $display("%5s%s NOT defined --> exit test\n","",message)'
                    ,   '         $finish();'
                    ,   '    end'
                    ,   '    $display("%5s%s :: %b",message,CLI_C);'
                    ,   'end'                       )];# @codelines
my  @blockindent=   (   0, 4, 4, 4, 4, 9, 9, 9, 4, 9, 9, 4, 4, 0  );

sub     get_entry   {
        my  (   $ArrRef )   =   @_;
        my  $itr    = 0;
        my  $tmp;
        foreach my $entry  ( @{$ArrRef} ){
            chomp   $entry;
            $tmp    = $entry if($itr == 0);
            $itr++;
        }#foreach
        return $tmp;
}#sub   get_entry

sub     generate_api    {
        my  (   $TmpFile
            ,   $ArrRef     )   =   @_;
        printf "%*sgenerate_api()\n",5,'';

        my  $info   =   {   taskname    =>  get_entry ( $ArrRef )
                        ,   keywords    =>   [ qw ( task endtask ) ]
                        ,   bf_tasks    =>   $ArrRef
                        ,   temp_file   =>   $TmpFile
                        ,   indent      =>   0                                  #   left bound               
                        ,   rawcode     =>   $codelines
                        };# synthesis information
        shift   (@{$ArrRef});                                                   #   Crazy Hash !!! Tbd
        
        my  $keyw       =   $$info{keywords};                                   #   reduce indirection
        my  $w0         =   maxwidth( $$info{keywords} );                       #   $w0     
        $$info{c0_width}=   ceil(($w0+1)/4) * 4;                                #   Need to compensate (':') character +1
        $$info{c1_width}=   maxwidth( $$info{bf_tasks} );                       #   $w1     
        $$info{open_kw} =   $$keyw[ 0];                                         #   $key_o  
        $$info{close_kw}=   $$keyw[-1].':';                                     #   $key_c 

        $TmpFile    =   declare_CLI_text_parameter ( $info );
        $TmpFile    =   declare_CLI_code_parameter ( $info );
        $TmpFile    =   define_BF_tasks ( $info );
        $TmpFile    =   call_BF_tasks   ( $info );
        return  $TmpFile;
}#sub   generate_api


sub     call_BF_tasks   {
        my  (   $info   )   =   @_;
        printf "%*scall_BF_tasks()\n",5,'';
        my  $TmpFile    =   $$info{temp_file};
        code_block  (   $info,  'open'  );
            foreach my $dataset   ( @{$$info{bf_tasks}} ) {
                chomp $dataset;
                my  @data    =   split (/,/, $dataset);
                my  $taskname=   $data[0];
                call_task   (   $info,  $taskname   );
            }#for all BF tasks
        code_block  (   $info,  'close' );
        return  $TmpFile;                                                       #   development vestigal
}#sub   call_BF_tasks

sub     unpack_data {
        my  (   $info
            ,   $dataset    )   =   @_;
        chomp $dataset;
        my  @data    =  split (/,/, $dataset);
        $$info{taskn}=  $data[0];                                               #   taskname (BF)
        $$info{cli_p}=  $data[1];   
        $$info{cli_t}=  $data[2];  
        $$info{cli_c}=  $data[3];  
        $$info{dsp_0}=  $data[4];
        $$info{cli_a}=  $data[5];
        $$info{pairs}=  $data[6];
        $$info{litrl}=  [@data[7..$#data]];                                     #   slice text & binary literals
        #my  $UL      =  6 + 2 * ($data[6]+1);
        #$$info{litrl}=  [@data[7..$UL]];
        #printf  "\n";
        #printf  "%*s%s\n",5,'>>>>',$$info{taskn};
        #printf  "%*s%s\n",5,'',$$info{cli_p};
        #printf  "%*s%s\n",5,'',$$info{cli_t};
        #printf  "%*s%s\n",5,'',$$info{cli_c};
        #printf  "%*s%s\n",5,'',$$info{dsp_0};
        #printf  "%*s%s\n",5,'>>>>',$$info{pairs};
        return;
}#sub   unpack_data            

sub     define_BF_tasks {
        my  (   $info   )   =   @_;
        printf "%*sdefine_BF_tasks()\n",5,'';
        my  $TmpFile    =   $$info{temp_file};
        foreach my $dataset   ( @{$$info{bf_tasks}} ) {
            unpack_data ( $info, $dataset );
            code_block  ( $info, 'open' );
            statementblk( $info );
            code_block  ( $info, 'close');
            empty_line  ( $info );
            empty_line  ( $info );
        }#for all blocks
        return $TmpFile;                                                        #   development vestigal
}#sub   define_BF_tasks

#----------------------------------------------------------------------------
#       P R I V A T E - S U B R O U T I N E S

sub     declare_t_parameter {
        my  (   $info
            ,   $line   )   =   @_;
        my  $TmpFile    =   $$info{temp_file};
        printf  "%*s%s()\n",5,'','declare_t_parameter';
        $line   =~  s/PLACE_HOLDER/$$info{cli_t}/g;
        push    (   @{$TmpFile}, $line );
        return $TmpFile;                                                        #   development vestigal
}#sub   declare_t_paramter

sub     declare_CLI_text_parameter {
        my  (   $info   )   =   @_;
        my  $TmpFile    =   $$info{temp_file};
        printf  "%*s%s()\n",5,'','declare_CLI_text_parameter';
        comment_line(   $info,  '//  CLI - Command line parameter'  );
        foreach my $bf_set   ( @{$$info{bf_tasks}} ) {
            unpack_data ( $info, $bf_set );
            declare_t_parameter (   $info
                                ,   'string                      PLACE_HOLDER;');
        }#for all blocks
        empty_line  (   $info   );
        return $TmpFile;                                                        #   development vestigal
}#sub   declare_CLI_text_parameter

sub     declare_c_parameter {
        my  (   $info   )   =   @_;
        my  $TmpFile    =   $$info{temp_file};
        printf  "%*s%s()\n",5,'','declare_t_parameter';
        my  $N  =   floor(log($$info{pairs})/log(2) + 1);
        my  $i  =   8;
        my  $t  =   'logic';
        my  $v  =   sprintf "[%s:0]",$N;                                        #   [N:0]
        my  $s  =   ($$info{pairs} > 1)?$v:'';                                  #   bit vector or bit
        my  $line   =   sprintf "%*s%*s%*s%s;",-$i,$t,-$i,$s,12,'',$$info{cli_c}; #   declare variable;
        push    (   @{$TmpFile}, $line );
        return $TmpFile;                                                        #   development vestigal
}#sub   declare_CLI_c_parameter

sub     declare_CLI_code_parameter {
        my  (   $info   )   =   @_;
        my  $TmpFile    =   $$info{temp_file};
        printf  "%*s%s()\n",5,'','declare_CLI_code_parameter';
        comment_line(   $info,  '//  TB testbench - BF bit field initialization parameter values'  );
        foreach my $bf_set   ( @{$$info{bf_tasks}} ) {
            unpack_data ( $info, $bf_set );
            declare_c_parameter (   $info   );
        }#for all blocks
        empty_line  (   $info   );
        return $TmpFile;                                                        #   development vestigal
}#sub   declare_CLI_code_parameter

sub     empty_line  {
        my  (   $info       )   =   @_;
        my  $TmpFile    =   $$info{temp_file};
        my  $line       =   '';
        push    (   @{$TmpFile}, $line );
        return  $TmpFile;                                                       #   development vestigal
}#sub   empty_line

sub     comment_line    {
        my  (   $info       
            ,   $line   )   =   @_;
        my  $TmpFile    =   $$info{temp_file};
        push    (   @{$TmpFile}, $line );
        return  $TmpFile;                                                       #   development vestigal
}#      comment_line

sub     insert_line {
        my  (   $info
            ,   $line
            ,   $ln )   =   @_;                                             #   line number
        my  $TmpFile    =   $$info{temp_file};
        my  $i          =   $$info{c0_width};                               #   indentation
            $line       =   sprintf "%*s%s",$i,'',$line;
            $line       =~  s/CLI_P/$$info{cli_p}/g;   
            $line       =~  s/CLI_T/$$info{cli_t}/g;   
            $line       =~  s/CLI_C/$$info{cli_c}/g;   
            $line       =~  s/DSP_0/$$info{dsp_0}/g;
            $line       =~  s/PATTERN_A/$$info{cli_a}/g;                    #   Alternative text literal
            if ($ln  == 2)  {
                $line   =~  s/PATTERN/${$$info{litrl}}[0]/g;
                $line   =~  s/CLI_V/${$$info{litrl}}[1]/g;
                #printf "%*s%s\n",5,'',$line;                                   #   debug vestigal
                push (@{$TmpFile}, $line);
            } elsif ($ln  == 3)  {
                #printf  "%*sCheck on me\n",5,'>>>> ';
                for my $i   ( 1..$$info{pairs} ){
                    my  $l  =   $line;                                          #   create a clone
                    #printf  "%5sCopy %s\n",'',$i;                              #   development vestigal
                    $l   =~  s/PATTERN/${$$info{litrl}}[$i*2+0]/g;
                    $l   =~  s/CLI_V/${$$info{litrl}}[$i*2+1]/g;
                    #printf "%*s%s\n",5,'',$l;                                  #   debug vestigal
                    push (@{$TmpFile}, $l);
                }
            } else {
                #printf "%*s%s\n",5,$ln,$line;                                  #   debug vestigal
                push (@{$TmpFile}, $line);
            }
}#sub   insert_line

sub     statementblk {
        my  (   $info   )   =   @_;
        my  $TmpFile    =   $$info{temp_file};
        my  $statements =   $$info{rawcode};
        my  $ln         =   0;
        foreach my $line    ( @{$statements} ) {
            chomp $line;
            insert_line ( $info, $line, $ln );
            $ln++;
        }#for all statements
        return $TmpFile;
}#sub   statement



#task    bf_task;   // open
#endtask:bf_task    // close

sub     code_block  {
        my  (   $info
            ,   $selection  )   =   @_;
        #printf "%*scode_block( %s )\n",5,'',$selection;                        #   debug
        #printf "%*sTASKNAME :: %s\n",5,'',$$info{bf_tasks};
        #printf "%*sTASKNAME :: %s\n",5,'',$$info{taskn};
        my  $TmpFile    =   $$info{temp_file};
        my  $taskname   =   $$info{taskn};                                      #   taskname (BF)
        my  $bf_list    =   $$info{bf_tasks};
        my  $i          =   $$info{indent};
        my  $w0         =   $$info{c0_width};
        my  $keyword    =   ($selection eq 'open' )
                        ?   $$info{open_kw}:$$info{close_kw};
            #$taskname   =   chomp $taskname;                                    #   remove potential newlines
            $taskname   =   ($selection eq 'open' )
                        ?   $taskname.';' : $taskname;
        #printf  "%*sAPI task name :: %s,%s\n", 5,'',$$info{taskname},$selection;
        #printf  "%*sAPI task name :: %s,%s\n", 5,'',$taskname,$selection;
        my  $line       =   sprintf "%*s%*s%s",$i,'',-$w0,$keyword,$taskname;
        push    (   @{$TmpFile}, $line );
        #printf "%*scode_block( %s ) ... done\n",5,'',$selection;
        return  $TmpFile;                                                       #   This return value is a development vestigal
}#sub   code_block

sub     call_task   {
        my  (   $info
            ,   $taskname   )   =   @_;
        chomp $taskname;                                                        #   remove potential newlines
        my  $TmpFile    =   $$info{temp_file};
        my  $i          =   $$info{c0_width};                                   #   indent first colume
        my  $line       =   sprintf "%*s%s;",$i,'',$taskname;
        push (  @{$TmpFile}, $line );
        return  $TmpFile;                                                       #   development vestigal
}#sub   call_task


#----------------------------------------------------------------------------
# End of module Array.pm
1;
