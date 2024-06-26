package PPCOV::DataAccess::JSON;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/PPCOV/DataAccess/JSON.pm
#
# Created       01/31/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::DataAccess::JSON::process_instances()
#                       input   col Instance from Coverage Specification tab
#                       return  list of design instances
#
#               PPCOV::DataAccess::JSON::get_zdata();
#                       input   zrecord Reference to the target instance
#                               scope   String with name of scope
#                       return  array   Reference to sample data
#
#               PPCOV::DataAccess::JSON::get_uri();
#                       input   root    of Testbench hierachy
#                               html_r  index.html
#                       return  zfile, zrecord
#
#               PPCOV::DataAccess::JSON::get_section();
#                       input   zrecord Reference to the target instance
#                               scope   Intro into section
#                               limiter Termination of the section
#                       return  array   Reference to matching sections
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Term::ANSIColor qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;
#   
use lib             qw  (   ../lib );               # Relative UserModulePath
use Dbg             qw  (   debug subroutine    );
use UTF8            qw  (   read_utf8   );
use Logging::Record qw  (   log_msg
                            log_lmsg    );

#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.08");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   process_instances
                            get_references
                            get_attribute
                            get_accesspath
                            get_headers
                            get_section
                            get_record
                            get_zdata
                            get_root
                            get_uri
                            maxwidth
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S
Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;
Readonly my $LIMITx     =>  qr  { '\],$ }xms;       # Limitor headers


Readonly my $LIMIT1     =>  qr  { '\}\]\},\n\]\n      } ;   # Limitor instances

#Readonly my $LIMIT1     =>  qr  { '\}\]\},\n\]\n }xms;   # Limitor instances
#Readonly my $LIMIT10    =>  qr  { \}\]\},\n }xms;   # Limitor ln{object}
#Readonly my $LIMIT10    =>  qr  { '\}\]\},\n }xms;   # Limitor ln{object}
Readonly my $LIMIT10    =>  qr  { '\}\]\}, }xms;   # Limitor ln{object}
Readonly my $LIMIT11    =>  qr  { '\}\]    }xms;   # Limitor ln{object}


Readonly my $LIMIT2     =>  qr  { '\}\}\n
                                  \]\n
                                  \}      }xms;     # Limitor loctable
#Readonly my $LIMIT20    =>  qr  { '\}\}\n

Readonly my $LIMIT21    =>  qr  { '\},    }xms;     # Limitor totalhists
Readonly my $LIMIT22    =>  qr  { '\},    }xms;     # Limitor avgw
Readonly my $LIMIT23    =>  qr  { \}\}\n
                                  \]\n    }xms;     # Limitor data:[

Readonly my $UCC        =>  qr {  .*    }xms;       # Universal character class
Readonly my $CC11       =>  qr { [^\n]* }xms;       # Character class
Readonly my $CC21       =>  qr { [^\}]* }xms;       # Character class
Readonly my $CC22       =>  qr { [^\]]* }xms;       # Character class


#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S


sub     process_instances   {
        my  (   $blk_r
            ,   $inst_r     )   = @_;               # instance reference
        my $inst = [];                              # reference to instances
        my $n =  subroutine('name');                # identify sub by name
        if( debug($n))  {
            printf  "\n%5s%s()\n",'',$n;
            printf  "%10s%s %s\n",'','Size of Block', $#{$blk_r}+1;
            printf  "%10s%s %s\n",'','Size of Block', $#{$inst_r}+1;
        }#if debug
        if ( $#{$blk_r} == $#{$inst_r}  )   {
            my $range  = $#{$blk_r};
            my $col1   = maxwidth ( $blk_r  );
            my $col2   = maxwidth ( $inst_r );
			printf "%10s%*s | %*s\n",''
                   ,$col1,${$blk_r}	[0]				# header
                   ,$col2,${$inst_r}[0] 			# header
				   if(debug($n));
            for my $i ( 1 .. $range ) {				# Skip the header
                printf	"%10s%*s | %*s\n",''
						,$col1,${$blk_r}[$i]
                        ,$col2,${$inst_r}[$i]
						if(debug($n));
                my @tmp = split / /, ${$inst_r}[$i];
                foreach my $e  ( @tmp ) {
                    push ( @{$inst}, $e ) if ($e !~ m/[+-]/ );
                }#
            }# for all blocks of interest
        } else {
            my $msg = 
			sprintf ("\n%*s%s\n",5,'',"WARNING Coverage Specification incomplete");
            print BLINK BOLD RED $msg, RESET;
            printf "\nWarning :: Block and Instance data are not complete !!\n";
        }
        my $u_inst = unique ( $inst );
        printf "\n" if(debug($n));
        return $u_inst;
}#sub   process_instances


sub     get_uri     {                                   # Uniform Resource Indentifier
        my  (   $root
            ,   $html_r     )   = @_;
        my $n =  subroutine('name');                    # identify sub by name
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%10s%s %s\n",''
                    ,'Verification root ', $root;
        }#if debug
        my $voodoo = get_root ( $root, $html_r );       # Verification TB design hierachy
        return $voodoo;                                 # Hash reference of URI
}#sub   get_uri


sub     get_root    {
        my  (   $scope
            ,   $html_r     )   = @_;
        my $n =  subroutine('name');                    # identify sub by name
        my  $uri =   {};                                 
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%10s%s %s\n",''
                    ,'Size of index.html  ',$#{$html_r}+1;
            printf  "%10s%s /%s\n",''
                    ,'Verification root  ',$scope;
        }#
        my $ix = 0;
        foreach my $line    ( @{$html_r} ) {
            if ( $line =~ m/$scope/ ) {
                printf "%10s%s %s\n",'',$line, 'found';
                printf "%10s%s %s\n",'',${$html_r}[$ix-1], 'found';
                #push ();
            }# if scope found
            $ix++;
        }# scan the whole file
        return $uri;
}#sub   get_root


sub     get_references  {
        my  (   $inst_r
            ,   $html_r     )   = @_;
        my  $n =  subroutine('name');                   # identify sub by name
        my  $uri  = {};
        if( debug($n))  {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%10s%s %s\n",'','Size of index.html  ',$#{$html_r}+1;
            printf  "%10s%s %s\n",'','Number of instances ',$#{$inst_r}+1;
        }#
        my %found;
        my $ix  =   0;
        foreach my $line    ( @{$html_r} ) {            # O(n) n is large 10K+
            if ( (match($line, $inst_r)) ) {            # O(n) n is very small < 10 
                #push ( @{$href},${$html_r}[$ix-1] );    # look behind for href
                my $inst = get_instance($line, $inst_r);
                $found{$inst} = 1;
                ${$uri}{$inst}{href} = ${$html_r}[$ix-1];
            };
            $ix++;
        }# foreach
        foreach my $inst ( @{$inst_r}) {
            if ( $found{$inst} ) {
            } else {
                printf  "\n%5s%s() \n",'',$n;
                my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING $inst instance not found");
                #printf "\n%*s%s\n",5,'',colored ("WARNING $inst instance not found", RED);
                print BLINK BOLD RED $msg, RESET;
            }# Give WARNING
        }# Check completness
        printf "\n";
        return $uri;
}#sub   get_references


sub     get_attribute   {
        my  (   $href   )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        if( debug($n)) {
            printf "\n%5s%s() \n",'',$n;
            printf "%5s%s %s\n",''
                    ,'Type of input parameter '
                    ,ref $href;
        }# debug
        if  (( ref $href ) =~ m/HASH/ ) {
            foreach my $instance ( keys %{$href} ) {
                if( debug($n)) {
                    printf  "%10s%s = %s",''
                            , $instance
                            , ${$href}{$instance}{href};
                }# debug
                if ( ${$href}{$instance}{href} =~ /.*"(.*)">/ ) {
                    printf " %s\n", $1 if( debug($n));
                    ${$href}{$instance}{attribute} = $1;
                } else {
                    printf "\n" if( debug($n));
                }#if match
            }#for all
            return $href;
        } else {
            my $msg = sprintf ("%*s%s\n\n",5,'',"WARNING $n() NO Hash reference");
            print BLINK BOLD RED $msg, RESET;
        }# Warning
}#sub   get_attribute


sub     get_accesspath  {
        my  (   $att_r  
            ,   $apath   )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        printf  "\n%5s%s() \n",'',$n if( debug($n));
        if ( (ref $att_r) =~ m/HASH/ )  {
            foreach my $instance ( keys %{$att_r} ) {       # instance & attribute are correlate
                my  $attr = ${$att_r}{$instance}{attribute};
                if ( $attr =~ m/^(.*)[.]htm[?]f=(\d+)&s=(\d+)/ ) {
                    my ($path, $rec) = ( $1.$2.'.json', $3 );
                    my $fpath = $apath.$path;
                    ${$att_r}{$instance}{zfile} = $fpath;
                    #${$att_r}{$instance}{zrecord} =   $rec;
                    ${$att_r}{$instance}{znum}  = $rec;
                    if( debug($n)) {
                    printf "%9s%s %s",'',$1,$2;
                    printf "\t%s\trecord %s",  $path, $rec;
                    printf "\tfile exists\n",         if(  -e $fpath);
                    printf "\tfile doesn't exists\n", if(! -e $fpath);
                    }# debug
                }# extract attribute data
            }#for all attributes
            return $att_r;
        } else {
            my $msg = sprintf ("%*s%s\n\n",5,'',"WARNING $n() NO Hash reference");
            print BLINK BOLD RED $msg, RESET;
        }# Warning
}#sub   get_accesspath


sub     get_record  {
        my  (   $dp_r                               # datapath reference
            ,   $zscope     )   = @_;               # ref to list of instance hash
        my $n =  subroutine('name');                # identify sub by name
        if( debug($n)) {
            printf "\n%5s%s() \n",'',$n;
            printf "%5s%s %s reference\n",''
                    ,'Type of input parameter '
                    ,ref $dp_r;
        }# debug
        if ((ref $dp_r) =~ m/HASH/ ) {
            foreach my $inst (keys %{$dp_r}) {
                my $znum    = ${$dp_r}{$inst}{znum};
                my $zfile   = ${$dp_r}{$inst}{zfile};
                   $zscope  //= 'TOTAL';
                #if ( debug($n)) {
                    printf  "\n\n";
                    printf  "%1s%s %s\n",'','Instance',$inst;
                    printf  "%1s%s %s\n",'','Filename',$zfile;
                    printf  "%1s%s %s\n",'','zNumber ',$znum;
                    printf  "%1s%s %s\n",'','zScope  ',$zscope;
                #}# if debug
                my @json    = read_utf8 ($zfile);
                log_msg ($zfile,'logs/log_zrecords');   # Step-1
                log_msg ($zfile,'logs/log_spans');      # Step-2
                log_msg ($zfile,'logs/log_instances');  # Step-3.1
                log_msg ($zfile,'logs/log_loctable');   # Step-3.2
                log_msg ($zfile,'logs/log_rectable');   # Step-3.3
                log_msg ($zfile,'logs/log_loc_data');   # Step-4.1
                log_msg ($zfile,'logs/log_rec_data');   # Step-4.2
                log_msg ($zfile,'logs/log_loc_info');   # Step-5.1
                log_msg ($zfile,'logs/log_rec_info');   # Step-5.2
                log_msg ($zfile,'logs/log_instinfo');   # Step-5.3
                log_msg ($zfile,'logs/log_headers');    # Step-6.1
                log_msg ($zfile,'logs/log_hits');       # Step-6.2

                my $zrecord = get_zrecord($znum,@json); # [ @zRecord ]
                log_msg ($zrecord,'logs/log_zrecords');
                
                ${$dp_r}{$inst}{raw}{$zscope} = get_zdata  ($zscope,$zrecord);    # Return ref to zData
                #${$dp_r}{$inst}{raw}{headers} = get_headers($zrecord,'headers',$LIMITx);

                my $instances = get_span  ($zrecord  ,'instances','list'  );
                my $loctable  = get_span  ($zrecord  ,'loctable' ,'object');
                my $rectable  = get_span  ($zrecord  ,'rectable' ,'object');

                #log_msg('get_entry(loctable)','logs/log_headers');
                #my $header_1  = get_entry ($loctable ,'headers'  ,'list','logs/log_headers' );
                #log_msg('get_entry(rectable)','logs/log_headers');
                #my $header_2  = get_entry ($rectable ,'headers'  ,'list','logs/log_headers' );

                my $loc_data  = get_span  ($loctable ,'data'     ,'list','loc_data'  );
                my $rec_data  = get_span  ($rectable ,'data'     ,'list','rec_data'  );

                my $inst_ln   = get_values($instances,'ln'       ,'logs/log_instinfo');
                my $instinfo  = get_values($instances,'val'      ,'logs/log_instinfo');
                my $loc_info  = get_values($loc_data ,'val'      ,'logs/log_loc_info');
                my $rec_info  = get_values($rec_data ,'val'      ,'logs/log_rec_info');

                my $merged    = merge_data($inst_ln,$instinfo);
                ${$dp_r}{$inst}{raw}{instances}        = $merged;
                ${$dp_r}{$inst}{raw}{loctable}{raw}    = $loc_info;
                ${$dp_r}{$inst}{raw}{rectable}{raw}    = $rec_info;
 
                log_msg('get_entry()','logs/log_headers');
                my $headers   = get_entry ($zrecord  ,'headers'  ,'list','logs/log_headers');
                ${$dp_r}{$inst}{raw}{header} = $headers;      
                log_msg('','logs/log_headers');

                log_msg('loctable','logs/log_hits');
                my $hits1     = get_valuepair($loctable,'totalhits','logs/log_hits');
                if ($hits1) {
                    log_msg(grep_data($hits1,'val',','),'logs/log_hits');
                    my $hits11 = grep_data($hits1,'val',',');
                    ${$dp_r}{$inst}{raw}{loctable}{totalhits} = $hits11;
                }# if data included

                my $hits2     = get_valuepair($loctable,'avgw'     ,'logs/log_hits');
                if ($hits2) {
                    log_msg(grep_data($hits2,'val',','),'logs/log_hits');
                    my $hits21 = grep_data($hits2,'val',',');
                    ${$dp_r}{$inst}{raw}{loctable}{avgw}      = $hits21;
                }# if data included

                log_msg("\nrectable",'logs/log_hits');
                my $hits3     = get_valuepair($rectable,'totalhits','logs/log_hits');
                if ($hits3) {
                    log_msg(grep_data($hits3,'val',','),'logs/log_hits');
                    my $hits31 = grep_data($hits3,'val',',');
                    ${$dp_r}{$inst}{raw}{rectable}{totalhits} = $hits31;
                }# if data included

                my $hits4     = get_valuepair($rectable,'avgw'     ,'logs/log_hits');
                if ($hits4) {
                    log_msg(grep_data($hits4,'val',','),'logs/log_hits');
                    my $hits41 = grep_data($hits4,'val',',');
                    ${$dp_r}{$inst}{raw}{rectable}{avgw}      = $hits41;
                }# if data included
                log_msg("\n",'logs/log_hits');

                ### #if ( defined $instance ) {
                ### if ( $instance ne '') {
                ###     my $inst_obj = get_list ($instance,'{parent'  ,$CC11 ,$LIMIT10);
                ###     printf  "\n";
                ###     #${$dp_r}{$inst}{raw}{instances} = 
                ###     get_objlst($inst_obj,'ln',','); 
                ### }# conditional 
                
                #my $coverage = get_list      ($scopes  ,'covs'     ,$CC22 ,$LIMIT11);

                #my $totalhit = get_subsection($loctable,'totalhits',$CC21,$LIMIT21);
                #my $averagew = get_subsection($loctable,'avgw'     ,$CC21,$LIMIT22);
                #my $data     = get_subsection($loctable,'data'     ,$CC22,$LIMIT23);
                #${$dp_r}{$inst}{raw}{totalhit}= get_vpair ($totalhit,'val',',');
                #${$dp_r}{$inst}{raw}{averagew}= get_vpair ($averagew,'val',',');
                #${$dp_r}{$inst}{raw}{Toggles} = get_vpair ($data,'val',',');

            }# for all instances
            return $dp_r;                           # Return updated reference
        } else {
            my $msg = sprintf   ("%*s%s\n\n",5,''
                                ,"WARNING $n() NO Hash reference");
            print BLINK BOLD RED $msg, RESET;
        }# Warning
}#sub   get_record


# introductor & limiter are on same line, multiple lines
sub     get_headers    {
        my  (   $rec_r
            ,   $scope
            ,   $limiter    )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        if ( debug($n) ) {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%9s%s %s\n",''
                    ,'Size of record',$#{$rec_r};
        }# debug
        my  $header =   [];
        my  $begin  =   $FALSE;
        foreach my $l ( @{$rec_r} ) {
            $begin  = $TRUE  if ($l =~ m/$scope:/);
            if ( $begin ) {
                chomp $l;
                printf  "%9s%s\n",'',$l if(debug($n));
                push (@{$header},$l);
            }
            $begin  = $FALSE if ($l =~ m/$limiter/x);
        }
        if ( debug($n) ){
            my $s = $#{$header};
            printf  "%9s%s %s\n\n",''
                    ,'Size of Section',$s;
        }# debug
        return $header;
}#sub   get_headers


sub     get_span {
        my  (   $record_r                           # search field
            ,   $label                              # search string
            ,   $objtype                            # object, list, pair
            ,   $name_tag   )   = @_;               # opt differentiator
            $name_tag   //= $label;                 # default value
        my $n =  subroutine('name');                # identify sub by name
        my $span  = [];
        my $begin = $FALSE;
        my $L     = ($objtype =~ m/list/)?']':'}';  # Only list or object
        #my $logf  = 'logs/log_'.$label;
        my $logf  = 'logs/log_'.$name_tag;
        if ( debug($n) ) {
            printf "\n%5s%s( %s ) \n",'',$n, $label;
            printf "%9s%s %s\n",'','Reference type', ref $record_r;
            printf "%9s%s %s\n",'','Size of record', $#{$record_r} + 1;
            printf "%9s%s %s\n",'','Lable name    ', $label;
            printf "%9s%s %s\n",'','Obj - delimiter', $L;
        }# debug
        for my $ix (0 .. $#{$record_r}) {
            #log_msg ($$record_r[$ix], 'logs/log_spans');
            $begin = $TRUE  if ( $$record_r[$ix] =~ m/$label:/ );   
            #push ( @{$span},     $$record_r[$ix] )  if( $begin );
            if( $begin ) {
                log_msg ($$record_r[$ix], $logf);
                push ( @{$span}, $$record_r[$ix] )
            }
            $begin = $FALSE if ( $$record_r[$ix] =~ m/^$L$/);
        }# for all lines
        log_msg ('',$logf);
        return  $span;                              # Array ref
}#sub   get_span


# 2 dementional array of data

sub     get_values   {
        my  (   $for_r                              # frame of reference
            ,   $scope                              # search term
            ,   $log_trace  )   = @_;               # log file name
        my $n =  subroutine('name');                # identify sub by name
        my $sep = ',';                              # Separator
        my $dag = [];                               # Data Aggregation
        if ( debug($n)) {
            printf "\n%5s%s()\n",'',$n;
            printf "%9s%s\t%s\n",'','Scope ',$scope;
            printf "%9s%s\t%s\n",'','FoR size ',$#{$for_r}+1;
            printf "%9s%s\t%s\n",'','LogfileN ',$log_trace; 
        }# if debug
        my $lc;                                     # line count - ghost
        foreach my $line ( @{$for_r} ) {
            chomp ( $line );
            #log_msg($line,$log_trace);
            if ( $line =~ m/$scope/ ) {
                my $ps = grep_data($line,$scope,$sep);  # Packed string
                if ( debug($n)) {
                    printf  "%9s%2s %s :: %s %s\n"
                            ,'',++$lc,$ps,'Size of', length $ps;
                }
                log_msg($ps,$log_trace);
                push ( @{$dag}, $ps );
            }# if in scope
            #log_msg($ps,$log_trace);
            #push ( @{$dag}, $ps );
        }#foreach line
        return $dag;
}#sub   get_values


sub     grep_data {
        my  (   $line
            ,   $scope
            ,   $separator  )   = @_;
        my  $n = subroutine('name');                # identify sub by name
        my  @tmp;
        my  $lc = 0;                                # line count
        printf  "\n%5s%s() \n"  ,'',$n if( debug($n));
        $line   =~ s/},/}},/g;
        my @raw_data = split ( '},', $line );
        foreach my $raw ( @raw_data ) {
            if ($raw =~ m/$scope:'([^']*)'/ ) {
                if ( debug ($n)) {
                    printf  "%9s%s\n",'',$raw;
                    printf  "%9s%2s %s %s\n",'','val', $1;
                }# debug
                push (@tmp, $1);
            }# if match
        }#foreach
        my $data = join(',',@tmp);
        return $data;                               # return string
}#sub   grep_data


sub     get_entry {
        my  (   $record_r                           # search field
            ,   $label                              # search string
            ,   $objtype                            # object, list, pair
            ,   $logfile    )   = @_;               # opt differentiator
        my $n =  subroutine('name');                # identify sub by name
        my $span  = [];
        my $begin = $FALSE;
        my $L     = ($objtype =~ m/list/)?'],':'},';  # Only list or object
        if ( debug($n) ) {
            printf "\n%5s%s() \n",'',$n;
            printf "%9s%s %s\n",'','Reference type', ref $record_r;
            printf "%9s%s %s\n",'','Size of record', $#{$record_r} + 1;
            printf "%9s%s %s\n",'','Lable name    ', $label;
            printf "%9s%s %s\n",'','Obj - delimiter', $L;
        }# debug
        for my $ix (0 .. $#{$record_r}) {
            #log_msg ($$record_r[$ix], 'logs/log_spans');
            $begin = $TRUE  if ( $$record_r[$ix] =~ m/$label:/ );   
            #push ( @{$span},     $$record_r[$ix] )  if( $begin );
            if( $begin ) {
                log_msg ($$record_r[$ix], $logfile);
                push ( @{$span},     $$record_r[$ix] )
            }
            $begin = $FALSE if ( $$record_r[$ix] =~ m/$L/);
        }# for all lines
        #log_msg ('',$logfile);
        return  $span;                              # Array ref
}#sub   get_entry


sub     get_valuepair   {
        my  (   $for_r                              # frame of reference
            ,   $label                              # search string/marker
            ,   $logfile    )   = @_;               # logfile specifyer 
        my $n =  subroutine('name');                # identify sub by name
        if ( debug($n) ) {
            printf "\n%5s%s() \n",'',$n;
            printf "%9s%s %s\n",'','Lable name    ', $label;
            printf "%9s%s %s\n",'','Size of record', $#{$for_r} + 1;
        }# debug
        my @span;
        foreach my $line ( @{$for_r} ) {
            if ( $line =~ m{ ($label:
                              [\{]
                              [^\}]*
                              [\}]), }xms ) {
                push (@span,$1);
                log_msg($1,$logfile);
            }                                       # line match
        }# for all lines
        return join(',' ,@span);                    # packed string
}#sub   get_valuepair


#$dp_r,$inst,'instances',$inst_ln,$instinfo
sub     merge_data  {
        my  (   $line_head                          # instance name
            ,   $line_data      )   = @_;           # instance data
        my $merged  =   [];
        my $n =  subroutine('name');                # identify sub by name
        if ( debug($n) ) {
            printf "\n%5s%s() \n",'',$n;
            printf "%9s%s %s\n",'','Size of list  ', $#{$line_head} + 1;
            printf "%9s%s %s\n",'','Size of list  ', $#{$line_data} + 1;
        }# debug
        foreach my $ix  ( 0 .. $#{$line_head} ) {
            my  @tmp;
            push ( @tmp, $$line_head[$ix] );
            push ( @tmp, $$line_data[$ix] );
            push ( @{$merged}, join (',',@tmp) );
        }# for full list
        return $merged;                             # [ $packed Strings ] 
}#sub   merge_data

#----------------------------------------------------------------------------
#  D E P R E C I A T E D  -  S U B R O U T I N E S



# introductor & limiter are on different lines, return string
sub     get_section {
        my  (   $rec_r
            ,   $scope
            ,   $filler
            ,   $delimiter  )   =   @_;
        my $n =  subroutine('name');                # identify sub by name
        my $target;
        if ( debug($n) ) {
            printf  "\n%5s%s() \n",'',$n;
            printf  "%9s%s %s\n",''
                    ,'Size of record',$#{$rec_r};
            printf  "%9s%s %s\n",''
                    ,'Segment Scope ',$scope;
            printf  "%9s%s %s\n",''
                    ,'Delimiter     ',$delimiter
        }# debug
        my $msg = sprintf "%9s%s(%s) %s %s",'',$n, $scope  
                ,'Recognized delimiter ', $delimiter;
        #log_msg($msg,'logs/log_zsections');
        my $zrecord = join ('',@{$rec_r});          # multiline string
        #my @tmp     = split //, $delimiter;         # break into char
        #my $ss      = join ('\\',@tmp);             # escape all char
        #$ss = '\\'.$ss;

        if ( $zrecord =~ m{ ( $scope ) }xsm) {
            $msg = sprintf "%9s%s",'','   Scope   Match !!';
            log_msg($msg,'logs/log_zsections');
        } else {
            $msg = sprintf "%9s%s",'','No Scope   Match';
            log_msg($msg,'logs/log_zsections');
        }

        if ( $delimiter =~ m/}]},n]n/ ) {
            #$msg = sprintf "%9s%s(%s) %s %s",'',$n, $scope  
            #                ,'Testing    delimiter ', $delimiter;
            #log_msg($msg,'logs/log_zsections');
            #if ( $zrecord =~ m{ ( $ss ) }xsm) {
            if ( $zrecord =~ m{ ( $LIMIT1 ) }xsm) { # \}\]\},\n\]\n
            #if ( $zrecord =~ m{ ( \}\]\},\n\]\n ) }xsm) {
            #if ( $zrecord =~ m{ ( \}\]\},\n ) }xsm) {
            #if ( $zrecord =~ m{ ( \}\]\}, ) }xsm ) {
            $msg = sprintf "%9s%s\n",'','   Limiter Match !!:';               
            log_msg($msg,'logs/log_zsections');
            } else { #if detecting REGEX
            $msg = sprintf "%9s%s\n",'','No Limiter Match';                
            log_msg($msg,'logs/log_zsections');
            }# 
        }#if detect delimiter

     
        if ( $zrecord =~ m{ ( $delimiter) 
                          }xsm) {
            printf  "%9s%s\n",'','   Limiter Match !!:';
        } else {
            printf  "%9s%s\n",'','No Limiter Match';
            printf  "%9s%s\n",'',$delimiter;
        }
        if ( $zrecord =~ m{ ( \}\]\}, ) 
                          }xsm) {
            printf  "%9s%s\n",'','   LimiterMatch !! 2nd';
        } else {
            printf  "%9s%s\n",'','No Limiter Match 2nd';
            printf  "%9s%s\n",'', '}]},';
        }
        #if ( $zrecord =~ m{ ( $scope .* $limiter ) 
        #if ( $zrecord =~ m{ ( $scope $filler $delimiter ) 
        if ( $zrecord =~ m{ ( $scope $filler $LIMIT1 ) 
                         }xsm) {
            my $msg = sprintf "%9s%s(%s) %s\n",'',$n, $scope 
                            ,'   Match in heaven!!';
            log_msg($msg,'logs/log_zsections');
            $target = $1;
            log_msg($target,'logs/log_zsections');
            log_msg('','logs/log_zsections');
        } else {
            my $msg = sprintf "%9s%s(%s) %s\n",'',$n, $scope  
                            ,'No Match in heaven';
            log_msg($msg,'logs/log_zsections');
            printf  "%9s%s(%s) %s\n",'',$n, $scope  
                    ,'No Match in heaven';
        }
        return $target;                             # string/scalar
}#sub   get_section


sub     get_subsection  {
        my  (   $section
            ,   $scope
            ,   $filler
            ,   $limiter    )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        if ( debug($n) ) {
            printf  "\n%5s%s() \n",'',$n;
            #printf  "%9s%s %s\n",''                # messy output due to 
            #        ,'Section ',$section;          # nature of .json file
        }# debug
        #if ( $section =~ m{ ( $scope [^\}]*(?!$limiter) ) 
        if ( $section =~ m{ ( $scope 
                              $filler 
                              $limiter ) }xsm) {
            printf  "%9s%s %s\n",''
                    ,'Subsection ',$1;
            return $1;
        } else {
            printf  "%9s%s(%s) %s\n",'',$n, $section
                    ,'No Match in heaven';
        }
}#sub   get_subsection


sub     get_list    {
        my  (   $section
            ,   $scope                              # initiator
            ,   $filler                             # character class
            ,   $limiter    )   = @_;
        my $lc  = 0;
        my $lc1 = 0;
        my $lst = [];
        my $n   = subroutine('name');               # identify sub by name
        if ( debug($n) ) {
            printf  "\n%5s%s() \n",'',$n;
            #printf  "%9s%s %s\n",''                # messy output due to 
            #        ,'Section ',$section;          # nature of .json file
        }# debug
        
        while ( $section =~ m{ ( $scope 
                                 $filler 
                                 $limiter ) }xsmg) {
            printf "%9s%s %2s\n",'','Found ', ++$lc;
            my $obj = $1;
            #printf "%9s%s\n",'',$obj;              # Reduce cludder
            push ( @{$lst}, $obj);
        }#while
        unless ( $section =~ m{ ( $scope 
                                  $filler 
                                  $limiter ) }xsmg) {
            printf  "%9s%s\n",'','No Match in heaven';
        }
        return $lst;
}#sub   get_list


# covs: is a list of values of the scope 'ln' and should have been 
#       extracted as a list within the object, but no other lists
#       are included within the scope of the object, thus the
#       value pairs 'val' are unambigious for each object

sub     get_objlst      {
        my  (   $lst_r
            ,   $scope
            ,   $separator  )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        if ( debug($n) ) {
            printf  "\n%5s%s() \n",'',$n;
            #printf  "%9s%s %s\n",''                # messy output due to 
            #        ,'Section ',$section;          # nature of .json file
        }# debug
        my $cnt = 0;
        my $scope_v;                                # csv string
        my $tmp         = [];
        my $scp_data    = [];
        foreach my $obj ( @{$lst_r}) {              # $obj are strings
            $cnt++;
            if ( $cnt == 1 ) {
                printf "%9s %s\n", '', $obj;
            }
            printf "%9s%4s %s\n",'', $cnt, get_vpair($obj,$scope,',');
            push ( @{$tmp},get_vpair($obj,$scope,','));
            my $tmp_d   = get_vpair($obj,'val' ,','); 
            printf "%9s%4s %s\n",'','data', $tmp_d; 
            #push ( @{$scp_data} ,get_vpair($obj,'val' ,','));
        }# for each entry
        $scope_v = join(',' , @{$tmp});
        printf "%9s%s : %s\n",'','ln', $scope_v;
}#sub   get_objlst


sub     get_zrecord     {
        my  (   $znum
            ,   @json   )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        my $record  =   [];
        my $begin   =   $FALSE;
        if ( debug($n) ) {
            printf "\n%5s%s() \n",'',$n;
            printf "%9s%s%s\n",'','znumber ', $znum;
            printf "%9s%s %s\n",'','length of json',$#json;
        }#if debug
        for my $index   (0 .. $#json) {
            $begin  = $TRUE     if ( $json[$index] =~ m/z$znum/ );   
            push (@{$record}, $json[$index] ) if ($begin);
            $begin  = $FALSE    if ( $json[$index] =~ m/^},\n/);
        }# for all lines
        return $record;                             # Array ref
}#sub   get_zrecord


sub     get_zdata   {
        my  (   $scope
            ,   $zrecord_r  )   = @_;
        my $n =  subroutine('name');                # identify sub by name
        my $sep = ',';                              # Separator
        if ( debug($n)) {
            printf "\n%5s%s()\n",'' ,$n;
            printf "%9s%s\t%s\n",'' ,'Scope ',$scope;
            printf "%9s%s\t%s\n",'' ,'Record Length '
                                    ,$#{$zrecord_r};
        }# if debug
        foreach my $line ( @{$zrecord_r} ) {
            chomp ( $line );
            if ( $line =~ m/$scope/ ) {
                #printf  "%9s%s\n",'',$line if( debug($n));
                return slice_data  ( $sep , $line );
            }#if
        }#foreach line
}#sub   get_zdata


sub     slice_data  {
        my  (   $separator
            ,   $line       )   = @_;
        my  $n = subroutine('name');                # identify sub by name
        my  @tmp;
        printf  "\n%5s%s() \n"  ,'',$n if( debug($n));
        my @raw_data = split ( $separator, $line );
        foreach my $raw ( @raw_data ) {
            if ( debug ($n)) {
                printf  "%9s%s\n",'',$raw;
                printf  "%9s%s %s\n",'','val', $1 if ($raw =~ m/val:'([^']*)'/ );
            }# debug
            push (@tmp, $1) if ($raw =~ m/val:'([^']*)'/ );
        }#foreach
        my $data = join(',',@tmp);
        return $data;                               # return string
}#sub   slice_data


sub     get_vpair   {
        my  (   $searchfield
            ,   $param
            ,   $separator      )   = @_;
        my  $n = subroutine('name');                # identify sub by name
        my  @tmp;                                   # container for values
        printf  "\n%5s%s() \n"  ,'',$n if( debug($n));
        my @raw_data = split ( $separator, $searchfield );
        foreach my $raw ( @raw_data ) {
            if ($raw =~ m/$param:'([^']*)'/ ) {
                push (@tmp, $1);
                if ( debug ($n)) {
                    #printf  "%9s%s\n",'',$raw;     # deep input debug
                    printf  "%9s%s %s\n",'',$param, $1;
                }# debug
            }# match value pair
        }# for all pairs
        my $data = join(',',@tmp);
        return $data;                               # return string
}#sub   get_vpair

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


sub     unique  {
        my  (   $array_r    )   =   @_;
        my  %seen;
        my  $unique = [];
        foreach my $entry   ( @{$array_r} ) {
            push ( @{$unique}, $entry ) if ( !$seen{$entry}++ );
        }
        return $unique;
}#sub   unique


sub     match    {                                  # $string match @array
        my  (   $line
            ,   $inst_r )   = @_;
        my $found = 0;
        foreach my $instance    ( @{$inst_r} ) {
            next        if $line !~ m/$instance/ ; 
            $found++    if $line =~ m/$instance/ ;
        }# 
        return $found;
}#sub   match


sub     get_instance   {
        my  (   $line
            ,   $inst_r )   = @_;
        my $found = 0;
        my $return_inst = 'NOT FOUND';
        foreach my $instance    ( @{$inst_r} ) {
            next        if $line !~ m/$instance/ ;
            $found++    if $line =~ m/$instance/ ;
            $return_inst = $instance;
        }# 
        return $return_inst;
}#sub   get_instanace

#       multi line string -> multi line string
sub     _instances_cutter   {
        my  (   $n
            ,   $zrecord
            ,   $zscope
            ,   $zfiller
            ,   $zdelimiter )   = @_;
        my  @tmp    = split //, $zdelimiter;
        my  $ss     = join ('\\',@tmp);
        my $msg = sprintf "%9s%s(%s) %s %s\n",'',$n, $zscope  
                ,'Recognized delimiter ', $zdelimiter;
        log_msg($msg,'logs/log_zsections');
}#sub


sub     _unknown_delimiter  {
        my  (   $n
            ,   $scope
            ,   $delimiter  )   = @_;
        my $msg = sprintf "%9s%s(%s) %s %s\n",'',$n, $scope  
                ,'Unknown delimiter ', $delimiter;
        log_msg($msg,'logs/log_zsections');
}#sub

#----------------------------------------------------------------------------
#  End of module
1;
