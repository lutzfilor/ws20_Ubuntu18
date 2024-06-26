package ARM::Monitor::Add;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/ARM/Monitor/Add.pm
#
# Created       03/26/2019          
# Author        Lutz Filor
# 
# Synopsys      ARM::Monitor::Add::add_new_monitor()
#
#               Is the main subroutine to call for logger code generation
#
# Input         <Proj_Monitor>.xlsx Monitor Specification
#                                   Example    bg7_mon.xlsx
#               [ @of_worksheets ]  Header  :: Summary Information for USER
#                                   Monitor :: Device specific information
#                                   Signal  :: Port - Contact specific info
#                                   
# Output        axi_monitor_include.svi
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;

use Excel::Writer::XLSX;                            # Spreadsheet::WriteExcel
use Spreadsheet::ParseXLSX;
use Cwd                         qw  (   abs_path
                                        cwd         );

use File::Basename;
use POSIX                       qw  (   strftime    );			# Format string

use lib                         qw  (   ~/ws/perl/lib );        # Relative UserModulePath from user
use Dbg                         qw  (   debug           
					            		subroutine  );  # subroutine knows its own name
use Logging::Record             qw  (   log_msg
                                        log_lmsg    );
use File::Header::Add           qw  /   add_header  /;  # .xlsx controlled header
use File::IO::UTF8::UTF8        qw  /   read_utf8
                                        write_utf8  /;  
use PPCOV::DataStructure::DS    qw  /   list_ref    /;  # Data structure


#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.17");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   deepcopy_workbook
							worksheet_clone
							extract_hash
							extract_array
							add_worksheet
							insert_worksheet
							write_workbook
							revise_workbook
                            add_new_monitor
						);#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S


sub     add_new_monitor     {
        my  (   $o_r    )   =   @_;                 # Option Reference
        my  $i = ${$o_r}{indent};                   # left side indentation
        my  $p = ${$o_r}{indent_pattern};           # indentation_pattern
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
        }# debug
        if ( file_exists( $o_r, 'spec', $n)) {
            my $specification = ${$o_r}{spec};
            if ( defined ${$o_r}{output} ) {
                my $f   = ${$o_r}{output};
                my $msg = sprintf ("\n%*s%s\n\n",$i,$p
                                ,"Specified output = $f !!");
                print BLINK BOLD BLUE $msg, RESET;
            read_specification  (   $o_r
                                ,   $specification  );
            } else {
                my $msg = sprintf ("\n%*s%s\n\n",$i,$p
                ,"WARNING generate=Filename not specified !!");
                print BLINK BOLD RED $msg, RESET;
                exit;
            }#
        }
}#sub   add_new_monitor


sub     read_specification  {
        my  (   $o_r
            ,   $specification  )   =   @_;         # .xlsx Monitor specification
        my  $i  = ${$o_r}{indent};                  # left side indentation
        my  $p  = ${$o_r}{indent_pattern};          # indentation_pattern
        my  $f  = ${$o_r}{output};                  # Output scource filename
        my  $l  =   [];                             # Specification logging file
        my  $r  =   [];                             # Synthesis     logging file, reporting execptions
        my  $o  =  'axi_monitor_include.svi';       # System Verilog Output Source File 
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf "\n%*s%s( %s )  ",$i,$p,$n,$specification;
            printf "%s\n",'See:: logs/read_specificaton.log';
        }# debug
        my  $m          =   {};                     # Monitor specification
        ${$m}{svi}      =   [];                     # .svi System Verilog Include
        push ($l,sprintf "%*s%s( %s )",0,$p,$n,$specification);
        push ($r,sprintf "%*s%s( %s )",0,$p,$n,$specification);
        my  $parser     =   Spreadsheet::ParseXLSX->new();
        my  $workbook   =   $parser->parse($specification);     # from      file .xlsx
        my  $bookcopy   =   deepcopy_workbook($workbook,$o_r);
        #list_ref   ( $o_r, { name => 'AppOptions',} );                             # Development
        #list_ref   (   $bookcopy                                                   # Development
        #           ,   {   name    =>  'Raw Monitor Spec'
        #               ,   reform  =>  'ON'                } );
        #                                   workbook,worksheet,3-columnhead
        ${$m}{format}    =  $o_r;
        ${$m}{logging}   =  $r;                     # Synthesis logging file, reporting execptions
        ${$m}{protocol}  =  extract_array( $bookcopy,'Monitor','Standard'   ,$l);
        ${$m}{interface} =  extract_array( $bookcopy,'Monitor','I/F-Type'   ,$l);   # I/F-Type
        ${$m}{instance}  =  extract_array( $bookcopy,'Monitor','I/F-Name'   ,$l);   # I/F-Name
        ${$m}{dbuswidth} =  extract_array( $bookcopy,'Monitor','Dwidth'     ,$l);
        ${$m}{idwidth}   =  extract_array( $bookcopy,'Monitor','Idwidth'    ,$l);   # ID Tag bus width
        ${$m}{switch}    =  extract_array( $bookcopy,'Monitor','Switch'     ,$l);   # directives
        ${$m}{gatesim}   =  extract_array( $bookcopy,'Monitor','GATE_SIM'   ,$l);
        ${$m}{directive} =  extract_array( $bookcopy,'Monitor','Directive'  ,$l);
        ${$m}{device}    =  extract_array( $bookcopy,'Monitor','Device'     ,$l);   # Device
        ${$m}{clock}     =  extract_array( $bookcopy,'Monitor','Clock'      ,$l);
        ${$m}{reset}     =  extract_array( $bookcopy,'Monitor','Reset'      ,$l);
        ${$m}{hierachy}  =  extract_array( $bookcopy,'Monitor','Hierachy'   ,$l);
        ${$m}{wraptype}  =  extract_array( $bookcopy,'Monitor','Wrap-Type'  ,$l);   # Wrapper-Type/
        ${$m}{wrapname}  =  extract_array( $bookcopy,'Monitor','Wrap-Name'  ,$l);   # Wrapper-Name
        ${$m}{rootname}  =  extract_array( $bookcopy,'Monitor','LogRoot'    ,$l);
        ${$m}{xaction}   =  extract_array( $bookcopy,'Monitor','TRANSNAME'	,$l);
        ${$m}{ptracker}  =  extract_array( $bookcopy,'Monitor','PHASENAME'	,$l);
        ${$m}{checker}   =  extract_array( $bookcopy,'Monitor','CHECKERNAME',$l);
        ${$m}{contacts}  =  extract_array( $bookcopy,'Signal' ,'Monitor'    ,$l);   # Bundle of Signal in Interface
        my $dw =  maxwidth( ${$m}{device} );                                        # Alignment for name
        foreach my $device ( @{${$m}{device}} ) {                                   # Form Stub connection Master0, 
            unless ($device =~ m/Device/ ) {                                        # Proper exclusion of ColHeader
                ${$m}{$device} = extract_array ($bookcopy,'Signal',$device,$l);     # Wire Stub ( DEVICE ) mstr0_     leading  stub
                                                                                    #                      _gfx_m0_s0 trailing stub
                printf "%5s%*s = %s Ports\n",'',$dw,$device, $#{${$m}{$device}};
            }# unless column header
        }# for each device
        write_utf8($l,'logs/read_specification.log');                               # logging reading specification
        insert_fileheader( $m );                                                    # To be implemented
        implement_specification( $m );                                              # monitor
        write_utf8($r,'logs/monitor_synthesis.log');                                # logging monitor synthesis 
        write_utf8(${$m}{svi} ,$o);                                                 # $o = output file name
        #my $path = abs_path($0);
        my $path = cwd();
        printf "\n";
        printf "%5s%s%s\n"  ,'','Logs    are at : ',$path.'/logs';
        printf "%5s%s%s\n\n",'','Results are at : ',$path.'/'.$o;
        #test_character( $m );                                                      # experimental code
}#sub   read_specification


sub     insert_fileheader   {
        my  ( $monitor  )   =   @_;
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
            printf  "%5s%s = %s\n",''
                    ,'Number of monitors'
        }# if debug
}#sub   insert_fileheader


sub     implement_specification {
        my  ( $monitor  )   =   @_;                 # { anonymous Hash w/ information for all monitors } 
        my $ix;                                     # monitor index
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s( %s = %s )\n",'',$n
                    ,'Number of monitors'
                    ,$#{${$monitor}{instance}};
        }# if debugging
        print "\n" unless(${$monitor}{silent});     # default progress reporting
        my $logging = ${$monitor}{logging};         # [] 
        my $w = maxwidth(${$monitor}{rootname});    # Alignment for monitor name

        foreach my $inst ( @{${$monitor}{rootname}} ) {
            unless ( $inst =~ m/LogRoot/ ) {        # Most meaningfull name of monitor
                my $pr = ${$monitor}{protocol}[$ix];
                my $p  = sprintf "%5s%s( %s, %*s )",''
                                ,'implement_monitor',$pr,$w,$inst;
                push (@{$logging}, $p);             # logging progress
                print "$p\n" unless(${$monitor}{silent});
                implement_monitor( $monitor,$ix );  # monitor(index) 
            }# unless header
            $ix++;                                  # Only the index identifies the monitor in { Hash }
        }# foreach monitor in specification
}#sub   implement_specification


sub     implement_monitor  {
        my  (   $monitor                            # reference to monitor information
            ,   $ix                                 # monitor index
            ,   $l          )   =   @_;             # logging report
        my $switch = ${$monitor}{switch}[$ix];
        my $m0  = sprintf "// %s %s"
                , ${$monitor}{protocol}[$ix]        # Protocol Identifier
                , 'Monitor Instantiation';          # Message
        my $m1  = sprintf "%s %s",'`ifdef', $switch;
        push ( @{$monitor}{svi}, $m0);
        push ( @{$monitor}{svi}, $m1);
        define_monitor      ( $monitor, $ix );
        signal_connecting   ( $monitor, $ix );
        Questa_directive    ( $monitor, $ix );
        my $m2  = sprintf "%s // %s\n\n",'`endif',$switch;
        push ( @{$monitor}{svi}, $m2 );
}#sub   implement_monitor


sub     define_monitor {                                                # AXI3 and AXI4 use same interface
        my  (   $monitor  
            ,   $ix         )   =   @_;
        ${$monitor}{protocol} //= 'AXI';
        my $mon = (${$monitor}{protocol}[$ix] =~ m/AXI/ )? 'axi_if' : 'UNDEFIND';
        my $inst=  ${$monitor}{instance}[$ix];                          # I/F name
        my $hie =  ${$monitor}{hierachy}[$ix];
        my $clk =  $hie.'.'.${$monitor}{clock}[$ix];
        my $m   = sprintf "%s %s (%s);",$mon,$inst,$clk;
        push ( @{$monitor}{svi}, $m);                                   # Writeout System Verilog code
        #print "$m\n";                                                  # Silence terminal output
}#sub   define_monitor


sub     signal_connecting   {
        my  (   $monitor  
            ,   $ix         )   =   @_;                                 # device/monitor number/index
        my  $n  =  subroutine('name');                                  # identify the subroutine by name
        my $device  =   ${${$monitor}{device}}[$ix];
        if ( debug($n) ) {
            printf  "%5s%s( %s = %s, %s = %s)\n",'',$n
                    ,'Number of Ports'
                    ,$#{${$monitor}{$device}}
                    ,'Number of Signals'
                    ,$#{${$monitor}{contacts}};
        }# if debugging
        my $connector   =   [];
        my $signals     =   [];
        my $comment_c   =   [];                                         #   Exclude because of design
        my $comment_s   =   [];                                         #   Exclude because of protocol standard 
        my $raw_name    =   []; 
        my $cmd     = 'assign ';                                        #   verilog command for interface.signal = wire
        my $log     = ${$monitor}{logging};
        my $prot    = ${$monitor}{protocol}[$ix];                       #   AXI3 vs AXI4
        my $idwd    = ${$monitor}{idwidth} [$ix];                       #   ID width
        my $axi4    = ($prot =~ m/AXI4/)?$TRUE:$FALSE;                  #   Set axi4 protocol
        my $inst    = ${${$monitor}{instance}}[$ix];                    #   I/F Name or Port <xxx_axiMonif.>
        my $six     = 0;                                                #   Signal Index    NOT     $ix = Monitor index
        my $msg     = sprintf ("%5s%s\n",'',"Monitor Protocol  = $prot !!");
        print BLINK BOLD GREEN $msg, RESET if debug($n);
        my $msg2    = sprintf ("%15s%s",'',"IDwidth = $idwd !!");
        print BLINK BOLD RED "$msg2\n",RESET if ( $idwd eq "0");
        push ( @{$log}, $msg2 ) if ( $idwd eq "0");
        foreach my $contact ( @{${$monitor}{contacts}} ) {
            unless ($contact =~ m/Monitor/ ) {
                my $cmt = ($contact =~ m/\/\// )? $TRUE:$FALSE;         #   Is Signal commented out ?? wid, aclk
                (my $copy = $contact) =~ s/\/\///;                      #   $contact isn't lvalue
                push( @{$raw_name}, $copy );                            #   Functional AXI signal name, matching part of connection             
                my $sig = $inst.'.'.$copy;                              #   Port instance/Signal
                push( @{$connector}, $sig );                            #   Compile Port list/Connector of Monitor
                push( @{$comment_c}, $cmt );                            #   Commented/Excluded or NOT
            }# unless no column header
        }#for all contacts of the MONITOR
        my $hier    =   ${${$monitor}{hierachy}}[$ix];
        my $rstn    =   ${${$monitor}{reset}}[$ix];                     #   Exceptional reset signal
        my $aclk    =   ${${$monitor}{clock}}[$ix];                     #   Exceptional clock signal
        foreach my $signal ( @{${$monitor}{$device}} ) {
            unless ( $signal =~ m/$device/ ) {                          #   Exclude the Header, not a signal apendix
                #printf  "%5s%2s %s\n",'',$six, $signal;                                                                        ## Hardcoded index -> Terminal
                my $cmt = ($signal =~ m/\/\// )? $TRUE:$FALSE;          #   Commenting Signal port, aka IDW == 0
                   $signal =~ s/\/\///;                                 #   remove the comment directive
                my $hot = ($signal =~ m/^_/   )? $TRUE:$FALSE;          #   Augmenting Head or Tail == HOT
                my $xcpt= ($signal =~ m/excpt/)? $TRUE:$FALSE;          #   Exception  selecting aclk, aresetn
                (my $cpy = $signal) =~ s/\/\///;                        #   $contact isn't lvalue
                my $stub = $signal;
                my $wire = ${$raw_name}[$six];                          #   Signal iteration port signal line up
                my $tmp  = ($hot)? $wire.$stub : $stub.$wire;
                my $msg = sprintf ("%15s%s",'',"Signal  = $tmp");
                push(@{${$monitor}{logging}},$msg) if $cmt;
                $tmp  = ($xcpt)? $rstn : $tmp if ($wire =~ m/reset/ );  #   Select aresetn exception
                $tmp  = ($xcpt)? $aclk : $tmp if ($wire =~ m/aclk/ );   #   Select aclk    exception
                my $sig  = $hier.'.'.$tmp;
                if ($wire =~ m/reset/ ) {
                    my $msg1= sprintf ("%5s%s\n",'',"Selection aresetn = $xcpt!!");
                    my $msg2= sprintf ("%5s%s\n",'',"Selection aresetn = $sig !!");
                    #print BLINK BOLD BLUE $msg1, RESET;
                    print BLINK BOLD BLUE $msg2, RESET if debug($n);
                }# exception for reset signal
                if ($wire =~ m/aclk/ )  {
                    my $msg1= sprintf ("%5s%s\n",'',"Selection aclk    = $xcpt!!");
                    my $msg2= sprintf ("%5s%s\n",'',"Selection aclk    = $sig !!");
                    #print BLINK BOLD BLUE $msg1, RESET;
                    print BLINK BOLD BLUE $msg2, RESET if debug($n);
                }# exception for clock signal
                if ($wire =~ m/awid|arid|bid|rid|wid/ )  {
                    my $msg = sprintf ("%5s%s\n",'',"Signal            = $wire");
                    print BLINK BOLD RED $msg, RESET if ( $idwd eq "0");
                }# exception for awid, arid, bid, rid, wid
                #report_commented_signal( $sig ) if $cmt;               #   IDw == 0, experimental not implemented
                push( @{$signals}, $sig );
                push( @{$comment_s}, $cmt );                            #   AXI4 exclude WID from port list
                $six++;                                                 #   Increment Signal index
            }# unless no column header
        }#for all stub signals
        my  $a1  = length $cmd;
        my  $a2  = maxwidth( $connector );
        $six = 0;
        foreach my $connection  (@{$connector}) {
            my $s   = ${$raw_name}[$six];                               #   Signal ID
            my $con = ${$connector}[$six];                              #   Connection
            my $raw = ${$raw_name}[$six];                               #   Raw protocol port name
            my $ctrl= (${$comment_c}[$six])                             #   based on port protocol
                    ||(${$comment_s}[$six]);                            #   based on signal port            
            if ( $raw =~ m/^wid/ )  {                                   #   AXI3 Protocol port name Overwrite control
               $ctrl= ( $axi4 ) ? $ctrl : $FALSE;                       #   AXI3 port WID is NOT excluded
               my $msg = sprintf ("%5s%s\n",''
                        ,"Protocol Overwrite= $ctrl !!");
               print BLINK BOLD GREEN $msg, RESET if debug($n);
            }# AXI3
            my $com = ($ctrl) ? '//' : $cmd;                            #   Commenting assignment command
            my $sig = ${$signals}[$six];                                #   Signal stub
            my $line= sprintf "%-*s%-*s = %s;"
                      ,$a1,$com,$a2,$con,$sig;
            push ( @{$monitor}{svi}, $line);                            #   Writeout System Verilog Code
            #printf "%*s%s\n",5,'',$line;                               #   Terminal debug disabled
            ${$monitor}{$s}[$ix] = $sig;                                #   Preserve full sig hierachy
            $six++;
        }#for all connections
}#sub   signal_connecting


sub     Questa_directive    {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        my  $n  =  subroutine('name');                  # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
            printf  "%5s%s = %s\n",''
                    ,'Number of signals'
                    ,$#{${$monitor}{contacts}};
        }# if debugging
        my  $i  =   length 'assign ';                   # indent System Verilog code
        my $prot= ${$monitor}{protocol}[$ix];           # AXI3 vs AXI4
        my $dir = ${${$monitor}{directive}}[$ix];       # directive QUESTA_AXI4_MON
        my $mon = ( $prot =~ m/AXI4/ )?$TRUE:$FALSE;    # Monitor collar, protocol based
        my $co  = sprintf "%*s%s %s" 
                    ,$i,'','`ifdef',$dir;               # Collar for AXI4
        if ($mon) {
            push ( @{$monitor}{svi}, $co);
            #print "$co\n";                             # Silence Terminal
        }
        instantiate_wrapper ( $monitor, $ix );
        initial_statement   ( $monitor, $ix );
        my $cc  = sprintf "%*s%s // %s"
                    ,$i,'','`endif',$dir;               # Collar for AXI4
        if ($mon) {
            push ( @{$monitor}{svi}, $cc);
            #print "$cc\n";                             # Silence Terminal
        }
}#sub   Questa_directive


sub     instantiate_wrapper {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        my $s   = [];                                                                           # System Verilog sourcecode;
        my $prot= ${$monitor}{protocol}[$ix];
        my $msg =  sprintf ("%5s%s\n",'',"Monitor Protocol = $prot !!");
        #print BLINK BOLD GREEN $msg, RESET;                                                    # Silence terminal
        my $mon = ( $prot =~ m/AXI4/ )
                ? '.monAxi4' : '.monAxi';
        my $inst= ${$monitor}{instance}[$ix];
        my $hie = ${$monitor}{hierachy}[$ix];
        my $wtyp= ${$monitor}{wraptype}[$ix];
        my $name= ${$monitor}{wrapname}[$ix];
        my $clk = $hie.'.'.${$monitor}{clock}[$ix];
        my $wrap=  ($prot=~m/AXI4/)?'axi4_mon_wrap':'axi_mon_wrap';
        my $port=  ($prot=~m/AXI4/)?'.monAxi4'     :'.monAxi';                                  # Wrapper Instance Name
        my $i   =  ($prot=~m/AXI4/)?
                    length "assign `ifdef " :
                    length "assign ";
        my $i1  = (length $wrap) + 1;
        #my $i2  = maxwidth ([ qq{ $wrap $inst} ]) + 3;
        my $i2  = 20;                                                                           # Why 20 ?? [Fi] for now it works
        my $i3  = $i+$i2+4;
        my $p   = '';
        my $root= ${$monitor}{rootname} [$ix];
        my $xact= ${$monitor}{xaction}  [$ix];
        my $ptrk= ${$monitor}{ptracker} [$ix];
        my $chkr= ${$monitor}{checker}  [$ix];
        my $idwd= ${$monitor}{idwidth}  [$ix];
        my $dwdh= ${$monitor}{dbuswidth}[$ix];
        my $aclk= ${$monitor}{aclk}     [$ix];
        my $arst= ${$monitor}{aresetn}  [$ix];
        my $c1  = '// Wrapper Instance Type';                                                   # Comment - 1
        my $c2  = '// Wrapper Instance Name( .Port  ( Interface ),';                            # Comment - 2
        $xact   =~ s/\$/$root/; 
        $ptrk   =~ s/\$/$root/; 
        $chkr   =~ s/\$/$root/; 
        my $hier=   ${$monitor}{hierachy}[$ix];
        my $s1  =  sprintf "%*s%-*s #("          , $i,$p,$i2,  $wtyp;
           $s1 .=  sprintf "%*s%-*s( %*s ), \t%s",  1,$p, 15,'.TRANSNAME'  ,36,$xact,$c1;
        push ( @{$s}, $s1 );                                                                    # Instant type
        push ( @{$s}, sprintf "%*s%-*s( %*s ),  ",$i3,$p, 15,'.PHASENAME'  ,36,$ptrk );
        push ( @{$s}, sprintf "%*s%-*s( %*s ),  ",$i3,$p, 15,'.CHECKERNAME',36,$chkr );
        push ( @{$s}, sprintf "%*s%-*s( %*s ),  ",$i3,$p, 15,'.ID_WIDTH'   ,36,$idwd );         # ID bus width
        push ( @{$s}, sprintf "%*s%-*s( %*s ) ) ",$i3,$p, 15,'.BUS_WIDTH'  ,36,$dwdh );
        my $s2  =  sprintf "%*s%-*s  ("          , $i,$p,$i2,  $name;   
           $s2 .=  sprintf "%*s%-*s( %*s ), \t%s",  1,$p, 15,  $port       ,36,$inst,$c2;       # Module Port (Interface Instance)
        push ( @{$s}, $s2 );                                                                    # instant name, total freedome
        push ( @{$s}, sprintf "%*s%-*s( %*s ),  ",$i3,$p, 15,'.aclk'       ,36,$aclk );
        push ( @{$s}, sprintf "%*s%-*s( %*s ) );",$i3,$p, 15,'.aresetn'    ,36,$arst );
        foreach my $l ( @{$s} ) {
            push ( @{$monitor}{svi}, $l);                                                       # Writeout System Verilog code
            #printf "%*s%s\n",5,'',$l;                                                          # Silence terminal directive
        }
        unless ($wtyp eq $wrap) {                                                               # Warning Specification mismatch
            my $msg = sprintf ("%5s%s\n",'',"WARNING Protocol Overwrite= $wrap vs $wtyp !!");
            print BLINK BOLD RED $msg, RESET;
        }# Specification warning
}#sub   instantiate_wrapper


sub     initial_statement    {
        my  (   $monitor  
            ,   $ix         )   =   @_;
        my  $n  =  subroutine('name');              # identify the subroutine by name
        if ( debug($n) ) {
            printf  "\n%5s%s()\n",'',$n;
        }# if debugging
        my $s   = [];                                   # sourcecode;
        my $prot= ${$monitor}{protocol}[$ix];
        my $a0 = ($prot=~m/AXI4/) 
               ? length 'assign  '
               : length 'assign ';
        my $a1 = length 'initial ';
        my $a2 = $a0 + $a1;
        my $inst = ${${$monitor}{wrapname}}[$ix];   # 
        my $attr = $inst.'.'.'monitor_on';
        push ( @{$s}, sprintf "%*s%s"     ,$a0,'','initial begin');
        push ( @{$s}, sprintf "%*s%s = 1;",$a2,'',$attr);
        push ( @{$s}, sprintf "%*s%s"     ,$a0,'','end');
        foreach my $l ( @{$s} ) {
            push ( @{$monitor}{svi}, $l);                                           # Writeout System Verilog code
            #printf "%*s%s\n",5,'',$l;                                              # Silence terminal directive, development
        }# for each line
}#sub   initial_statement


sub     deepcopy_workbook   {
        my  (   $book_r     )   =   @_;
        my  $n  =  subroutine('name');                                              # identify the subroutine by name
        #printf STDERR "%5s%s()\n",'',$n;
        printf  "\n%5s%s()\n",'',$n;
        my  $clone      =   [];                                                     # reference to workbook copy
        for my $sheet ( $book_r->worksheets()  ) {                                  # aggregate workbook, sheet by sheet
			push (@{$clone},worksheet_clone($sheet));
        }#for all sheets
        printf  "%5s%s() ... done \n",'',$n;
        return $clone;                                                              # clone[ sheets [ rows[ cells [] ]]]
}#sub   deepcopy_workbook 


sub     write_workbook  {
        my  (   $book_r								# [ @worksheets ]
			,	$filename							# target output file.xlsx
            ,   $opts_ref   )   =   @_;
        my  $i = ${$opts_ref}{indent};              # left side indentation
        my  $p = ${$opts_ref}{indent_pattern};      # indentation_pattern
        my	$n =  subroutine('name');				# identify sub by name

        my  $workbook   
		= Excel::Writer::XLSX->new( $filename );    # Step 1
        $workbook->set_properties(
               title    => 'IoT - Testcoverage Report',
			   subject	=> 'Coverage Progress',
               author   => 'Lutz Filor',
               manager  => 'Ravi Kalyanaraman',
               company  => 'Synaptics',
               comments => 'Created w/ Perl lib Excel::Writer::XLSX',
			   keywords => 'CPIT, report, progress, IoT, DV',
        );
		#owner	=> 'RamyaReddy Nerabetla',
        if ( ref($book_r) =~ m/ARRAY/ ) {
            foreach my $t ( @{$book_r} ) {
                printf STDERR "%*s %s %s\n",$i,$p,'tab name', $t->[0];
                my $worksheet 
				= $workbook->add_worksheet($t->[0]);	# Step-2
                $worksheet->write_col(0,0,$t->[1]);		# Step-3
            }# for each table worksheet
        }#if NO GUARD - TYPE is ARRAY
		#workbook->close();
}#sub   write_workbook


sub		revise_workbook	{
		my	(	$filename	
			,	$opts	)	=	@_;					    # { CL-options }
        my	$n 	=  subroutine('name');				    # identify sub by name
		my	$revised_file
		= filename_generator($filename, $opts);
		#import previous workbook
		my  $parser   = Spreadsheet::ParseXLSX->new();				# Step 1
    	my  $workbook = $parser->parse( $filename );				# Step 2
    	#my $workbook = $parser->parse( $opts{workbook} );     		
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
			printf  "%10s%s %s\n",'','Source Name'  ,$filename;
			printf  "%10s%s %s\n",'','Target Name'  ,$revised_file;
        }#if debug

		#deepclone	previous	workbook
		my  $clone 	= Excel::Writer::XLSX->new( $revised_file );	# Step 3
		#copy	previous	workbook
        for my $sheet ( $workbook->worksheets()  ) {
			if( debug($n))  {
				printf  "%10s%s %s\n",'','Worksheet  ',$sheet->get_name();
			}# if debug
			my $ws = $clone->add_worksheet($sheet->get_name());		# Step 4
			deepclone	( $sheet, $ws );							# Step 5
		}
		#update add latest	coverage report
}#sub	revise_workbook


sub		extract_hash	{
		my	(	$book_r							# workbook	reference     
            ,   $sheet_name 					# worksheet name
			,	$key							# column	number 0,1,2 ... whatever
			,	$val							# column	number  ,1,2 ... whatever should be $key+1
            ,   $opts_ref   	)   =   @_;		# option	reference
        my  $i  = 5;
        my  $p  = '';
        my  $n  =  subroutine('name');                                              # identify the subroutine by name
        my  $column_c   =   [];                                                     # reference of target column data
		my	$hash_clone =	{};
        my  ($f1,$f2)   =   (0,0);													# found data, report failure
		printf "\n";
        printf "%*s%s()\n", $i,$p,$n if(debug($n));
        if ( ref($book_r) =~ m/ARRAY/ ) {
            foreach my $t ( @{$book_r} ) {                                          # tab, worksheet reference
                my  $name   =   $t->[0];                                            # tab name
                my  $data_r =   $t->[1];                                            # tab data reference
                my  @data   =   @{$data_r};                                         # array of references -> column
                my  $n_row  =   $#data;                                             # number of rows		 span vertical 
                my  $n_col  =   $#{$data[0]};                                       # number of columns		 span horizontal
				my  $k		=	maxwidth([ map{$_->[$key]} @data ]);				# max width of keys
				my	$v		=	maxwidth([ map{$_->[$val]} @data ]);				# max width of any value
                printf "%*s%s: %s",$i,$p,'Sheet',$name if(debug($n));
                if ( $name  =~  m/$sheet_name/ ) {
					printf " found \n" if (debug($n));
					for my $row ( 0 .. $n_row) {
						if(debug($n)) {
							printf "%*s%*s = > %*s\n",$i*2,$p
							,$k,$data[$row][$key]
							,$v,$data[$row][$val];
						}# if debug
						${$hash_clone}{$data[$row][$key]} = $data[$row][$val];
					}# for all entries
				} else {
					printf "\n" if (debug($n));
				}#
			}# for all worksheet tabs
		} else {
		}# if reference is an array reference
		return $hash_clone; 
}#sub	extract_hash


# Data model    [workbook]->@[sheet]->@name,[data]->@[row]->@cell

sub     extract_array  {
        my  (   $book_r																# workbook
            ,   $sheet_name															# worksheet															
            ,   $col_header            												# column
            ,   $logger     )   =   @_;                                             # logger
        my  $i  = 5;
        my  $p  = '';
        my  ($f1,$f2)	=	(0,0);													# found data, report failure
        my  $n  =  subroutine('name');                                              # identify the subroutine by name
        my  $column_c   =   [];                                                     # reference of target column data
        my  $m  = sprintf "%*s%s( %s )\n" , $i,$p,$n,$sheet_name.'::'.$col_header;
		if(debug($n)) {
            #printf "\n";                                                           # vertical spacer
			printf "%s", $m;                                                        # functional header( wks::col )
		}# if debug
        push ( @{$logger},"\n");
        push ( @{$logger}, $m );                                                    # correlate extraction
        if ( ref($book_r) =~ m/ARRAY/ ) {
            foreach my $t ( @{$book_r} ) {                                          # tab, worksheet reference
                my  $name   =   $t->[0];                                            # tab name
                my  $data_r =   $t->[1];                                            # tab data reference
                my  @data   =   @{$data_r};                                         # array of references -> column
                my  $n_row  =   $#data;                                             # number of rows   
                my  $n_col  =   $#{$data[0]};                                       # number of columns
                my  $c1     =   'Sheet: ';                                          # category
                my  $i1     =   $i+length $c1;                                      # adjust indentation
                my  $c2     =   'Column: ';
                my  $i2     =   length $c2;                                         # adjust indentation
                my  $m1  = sprintf "%*s%s%s ",$i,$p,$c1,$name;
                if ( $name  =~  m/$sheet_name/ ) {
                    $f1 = 1;														# worksheet found
                    push ( @{$logger},$m1.'found');                                 # logging wksheet found
                    for my $col ( 0 .. $n_col ) {
                        my $f = "%*s%s%s ";
                        my $m2= sprintf $f,$i1,$p,$c2,$data[0][$col];
                        if ( $data[0][$col] =~ m/^$col_header$/ )  {				# search_field over search_pattern
                            $f2 = 1;												# column found		
                            push ( @{$logger},$m2.'found' );
                            for my $row ( 0 .. $n_row ) {							# everything incl header
                                my $f = "%*s%2s %s";
                                my $d = $data[$row][$col];
                                my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING empty Entry !!");
                                my $m3= sprintf $f,$i1+$i2,$p,$row,$d;
                                if ($d eq '') {
                                    unless (    $name       eq 'Monitor'
                                           &&   $col_header eq 'Directive') {
                                    print BLINK BOLD RED $msg, RESET;
                                    }
                                }
                                push (@{$logger}, $m3);                             # logging array element
                                push (@{$column_c}, $d);                            # extract data
                            }# for each row
                        } else {# column found
                            push ( @{$logger},$m2);                                 # logging column no match
						}#
                    }#foreach
                } else { #found worksheet
                    push ( @{$logger}, $m1 );                                       # logging wksheet name no match        
				}# skipp worksheet
            }#foreach            
        }# GUARD - reference TYPE is ARRAY
        my $f = "%*s%s %s %s\n";
        unless ( $f1 )  {
            printf STDERR $f,$i*2,$p,'Worksheet',$sheet_name,'NOT found';
        }
        unless ( $f2 )  {
            printf STDERR $f,$i*2,$p,'Worksheet    ',$sheet_name,'';
            printf STDERR $f,$i*2,$p,'Column_header',$col_header,'NOT found';
        }
        #exit unless ( $f1 && $f2 );                                                # Stop at the first error
        return $column_c;															# return data
}#sub   extract_array


#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S


sub     maxwidth    {
        my  (   $array_r    )   =   @_;
        my  $max    =   0;
        foreach my $entry  ( @{$array_r} ) {
            my $tmp =   length($entry);
            $max = ( $max > $tmp ) ? $max : $tmp;
        }#for all
        return $max;
}#sub   maxwidth


sub		file_exists	{
		my	(	$hash
			,	$key
			,	$name	)	= @_;
		my	$f = ${$hash}{$key};
		my	$e = ( -e $f)? $TRUE : $FALSE;
        my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING File $f not found !!");
        print BLINK BOLD RED $msg, RESET unless $e;
		if ( debug($name)) {
			printf "%*s%s\n", 5,'',"File $f found";
			printf "%*s%s\n",10,'','ASCII/UTF-8 Text file' if ( -T $f);
			printf "%*s%s\n",10,'','Binary file'           if ( -B $f);
			printf "%*s%s\n",10,'','readable'              if ( -r $f);
			printf "%*s%s\n",10,'','writeable'             if ( -w $f);
		}#if debug
		return $e;
}#sub	file_exists



sub		worksheet_clone	{
		my	(	$sheet	)	= @_;							# original worksheet
        my $data    =   [];
        my $clone   =   [];                                 # worksheet clone           
        my ( $row_min, $row_max ) = $sheet->row_range();    # region span in y / rows
        my ( $col_min, $col_max ) = $sheet->col_range();    # region span in x / columns
        for my $row ( $row_min .. $row_max ) {
            my $row_c   =   [];                             # row copy reference
            for my $col ( $col_min .. $col_max ) {
                my $cell    = $sheet->get_cell($row,$col);	# copy
                my $cell_v  = ($cell)?$cell->value():'';    # fully determined
                push ( @{$row_c}, $cell_v);                 # paste
            }# each column -> x
            push ( @{$data}, $row_c );                      # aggregate sheet row by row
        }# each row -> y
        push (@{$clone} , $sheet->get_name());              # copy tab name
        push (@{$clone} , $data   );                        # copy 2D region of values
		return $clone;
}#sub	worksheet_clone


sub		deepclone	{
		my	(	$org										# original worksheet
			,	$clone       )	=	@_;						# cloned worksheet
        my	$n 	=  subroutine('name');						# identify sub by name
        my	($row_min,$row_max) = $org->row_range();		# region span in y / rows
        my	($col_min,$col_max) = $org->col_range();   		# region span in x / columns
		for my $row ($row_min .. $row_max) {
			printf  "%22s%s %s\n",'','row',$row	if( debug($n)); 
		    for my $col ($col_min .. $col_max) {
				printf  "%26s%s %s\n",'','col',$col	if( debug($n)); 
				my $cell = $org->get_cell($row,$col);		# CELL
				#my $form = $cell->get_format();			# FORMAT
				my $wert = $cell->unformatted();			# VALUE
				$clone->write($row,$col,$wert);
			}# for all columns
		}# for all rows
		if( debug($n))  {
			printf  "%22s%s %s\n",'',' ... done  ',$clone->get_name();
		}# if debuging
}#sub	deepclone


#sub     display_deepcopy {
sub     render_worksheet {
        my    (   $book_r
              ,   $opts_ref   )   =   @_;
                  #$opts_ref   //= \%opts;
        my $i = ${$opts_ref}{indent};                                                 # left side indentation
        my $p = ${$opts_ref}{indent_pattern};                                         # indentation_pattern
        my $n =  subroutine('name');                                                  # identify the subroutine by name
        printf STDERR "%*s%s()\n\n", $i,$p,$n;
        if ( ref($book_r) =~ m/ARRAY/ ) {
           printf STDERR "%*s %s %s %s\n",$i,$p,$n,'parameter is',ref $book_r;
           foreach my $t ( @{$book_r} ) {
              printf STDERR "\n";
              printf STDERR "%*s %s %s\n",$i,$p,'tab name', $t->[0];
              my  $b_ref = $t->[1];                                                   # reference to blatt
              my  $w_ref = $t->[2];                                                   # reference to format, 
              my  @colum = @{$b_ref};
              my  $n_row = scalar @{$colum[0]};                                       # number of columns
              my  $n_col = $#{$w_ref};
              printf STDERR "%*s %s %s\n",$i,$p,'number of col', $n_col;
              printf STDERR "%*s %s %s\n",$i,$p,'number of row', $n_row;
              for my $row   ( 0 .. $n_row-1 ) {
                  printf  STDERR "%*s|",$i,$p;
                  for my $index ( 0 .. $n_col-1 ) {
                    printf STDERR "%*s ",${$w_ref}[$index],$colum[$index][$row];
                  }#for
                  printf STDERR "|\n";
              }#for
           }# tabs
        }#if GUARD - reference TYPE is ARRAY
#}#sub   display_deepcopy
}#sub   render_worksheet


sub     test_character  {
        my  ( $monitor     )   = @_;
        #my $e   = scalar ( @{${$monitor}{checker}} );
        #my $root= ${$monitor}{rootname} [$e];    #   [$ix];
        #my $xact= ${$monitor}{xaction}  [$e];    #   [$ix];
        #my $ptrk= ${$monitor}{ptracker} [$e];    #   [$ix];
        #my $chkr= ${$monitor}{checker}  [$e];    #   [$ix];
        my $root= ${$monitor}{rootname} [ 4];    #   [$ix];
        my $xact= ${$monitor}{xaction}  [ 4];    #   [$ix];
        my $ptrk= ${$monitor}{ptracker} [ 4];    #   [$ix];
        my $chkr= ${$monitor}{checker}  [ 4];    #   [$ix];
        $chkr   =~ s/\$/$root/; 

        my $char = substr $chkr, -1;
        printf  "%5s%s\n",'',$chkr;
        printf  "%5s%s = %3s\n",'',"\"",ord("\"");
        printf  "%5s%s = %3s\n",'',$char,ord($char);
        printf  "\n";
}#sub   test_character


sub		translate_format	{
		my	(	$if		)	= @_;						# input format Spreadsheet::ParseXLSX  
		my	$format	= {};								# format
		my  @sides = qw (left right top bottom);		# sides of cell
		if ( defined $if ) {               				# Translate
			${$format}{font}			= ${$if}{Font}{Name};			# Arial
			${$format}{size}			= ${$if}{Font}{Height};
			${$format}{bold}			= ${$if}{Font}{Bold};
			${$format}{color}			= ${$if}{Font}{Color};
			${$format}{italic}			= ${$if}{Font}{Italic};
#										  ${$if}{Font}{Underline}:
			${$format}{underline}		= ${$if}{Font}{UnderlineStyle};
			${$format}{font_strikeout}	= ${$if}{Font}{Strikeout};
			${$format}{font_script}		= ${$if}{Font}{Super};

			# shading
			${$format}{pattern}			= ${$if}{Fill}[0] if (defined ${$if}{Fill}[0]);
			${$format}{fg_color}		= ${$if}{Fill}[1] if (defined ${$if}{Fill}[1]);
			${$format}{bg_color}	    = ${$if}{Fill}[2] if (defined ${$if}{Fill}[2]);

			# swap fg and bg
			if ( ${$format}{pattern} == 1 ) {
				@{$format}{qw(fg_color bg_color)} = @{$format}{qw(bg_color fg_color)};
			}# if pattern is solid
			
			# alignment
			${$format}{text_h_align}	= ${$if}{AlignH};
			${$format}{text_v_align}	= (defined ${$if}{AlignV})? ${$if}{AlignV}+1 : 0;

			# borders
			foreach my $ix	( 0 .. $#sides) {
				my $side = $sides[$ix];
				my $colr = $side.'_color';
				${$format}{$side} = ${$if}{BrdStyle}[$ix] if (${$if}{BrdStyle}[$ix]);
				${$format}{$colr} = ${$if}{BdrColor}[$ix] if (${$if}{BdrColor}[$ix]);
			}# for all sides
		}#												# Excel::Writer::XLSX
		return	$format;
}#sub	translate_for

        ### my  $fullname           
        ### =   ${$opts_ref}{workbook};                 # absolute path/filename

sub     filename_generator  {
        my  (	$fullname   
			,	$opts_ref   )   =   @_;
        my  $i	= ${$opts_ref}{indent};             # indentation
        my  $p 	= ${$opts_ref}{indent_pattern};     # indentation pattern
        my	$n 	=  subroutine('name');				# identify sub by name
        my  ( $na,$pa,$su )   
        =   fileparse( $fullname, qr{[.][^.]*} );
        my  $u = strftime '_%Y-%m-%d', localtime;   # unique datestamp
        my  $d = $na.$u.'_revised'.$su;             # derived filename
        #my  $d = $na.$u.$su;                        # derived filename
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
			printf  "%10s%s %s\n",'','Source Name'  ,$fullname;
        	printf  "%10s%s %s\n",'','Date       '  ,$u;
        	printf  "%10s%s %s\n",'','Output Name'  ,$d;
        }#if debug
        ${$opts_ref}{output}    =   $d;
        return $d;
}#sub   filename_generator


sub     sheetname_generator {
        my  (   $opts_ref   )   =   @_;
        my  $i = ${$opts_ref}{indent};              # indentation
        my  $p = ${$opts_ref}{indent_pattern};      # indentation pattern
        my  $u = strftime '%Y-%m-%d', localtime;    # unique
        ${$opts_ref}{sheetname} =   $u;
        return $u;                                  # sheet name
}#sub   sheetname_generator


sub		_warn		{
		my	(	$n									# caller name
			,	$t	)	=	@_;						# type	 BOOK/SHEET
		my $f	= "\n%*s%s %s() %s %s\n";			# format
		my @l	= ( 5,'','WARNING',$n,$t,			# parameter list
					'not ARRAY reference' );
		my $message = sprintf ( $f, @l);
		return $message;
}#sub	warn


sub     insert_worksheet    {
        my  (   $book_r                             # [ workbook  ]
            ,   $data_r								# [ sheetdata ]
            ,   $opts_ref   )   =   @_;
        my $i = ${$opts_ref}{indent};               # left side indentation
        my $p = ${$opts_ref}{indent_pattern};       # indentation_pattern
		my $t = ${$opts_ref}{date};					# commandline overwrite
		$t	//=	sheetname_generator($opts_ref);		# title of worksheet
        my $n = subroutine('name');					# identify sub by name
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%*s%s %s\n",$i,$p,'Sheetname',$t;
        }#if debug
		my $worksheet	=	[];
        if ( ref($book_r) =~ m/ARRAY/ ) {
			if ( ref($data_r) =~ m/ARRAY/ ) {
				push ( @{$worksheet}, $t );			# Title
				push ( @{$worksheet}, $data_r);
				push ( @{$book_r}	, $worksheet );
			} else {
				my $msg = _warn ($n,'DATA');
            	print BLINK BOLD RED $msg, RESET;
			}# WARNING reference type Sheet
        } else {
			my $msg = _warn ($n,'BOOK');
            print BLINK BOLD RED $msg, RESET;
        }# WARNING reference type Book
		return $book_r;
}#sub   insert_worksheet


sub		new_workbook	{
		my	(	$filename			)	=	@_;
		return	Excel::Writer::XLSX->new ( $filename );
}#sub	new_workbook


sub		add_worksheet	{
		my	(	$workbook
			,	$worksheet_title	)	=	@_;
		return	$workbook->add_worksheet;
}#sub	add_worksheet


sub		close_workbook	{
		my	(	$workbook			)	=	@_;
		$workbook->close();
}#sub	close_workbook

#----------------------------------------------------------------------------
#  End of module PPCOV::EXCEL::XLSX
1
