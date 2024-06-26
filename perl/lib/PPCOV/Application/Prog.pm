package PPCOV::Application::Prog;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/PPCOV/Application/Prog.pm
#
# Refactored    03/08/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::Application::Prog::validate_setup() 
#                       return list of blocks/areas of interest
#
# Data model    [workbook]->@[sheet]->@name,[data]->@[col]->@cell
#                                          
#               
#----------------------------------------------------------------------------
#  I M P O R T S 
use strict;
use warnings;

use Readonly;
use POSIX						qw  (   strftime    );			# Format string
use Term::ANSIColor				qw  (   :constants  );          # available
#   print BLINK BOLD RED $msg, RESET;


use lib							qw  (   ../lib );               # Relative UserModulePath
use Dbg							qw  (   debug subroutine    );
use PPCOV::DataStructure::DS	qw  (   list_ref            );  # Data structure

#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.04");

use Exporter qw (import);                           # Import <import> method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended to use

our @EXPORT_OK  =   qw  (   validate_setup
							overwrite_setup
							get_writebackpath
							full_wbkpath
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # Create a category 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S

Readonly my $TRUE       =>  1;                      # Boolean like constant
Readonly my $FALSE      =>  0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S


sub		validate_setup	{
		my	(	$setup		)	= @_;
        my  $n = subroutine('name');                # identify sub by name
		if (debug($n))	{
            printf "\n%5s%s() \n",'',$n;
			list_ref ( $setup, 'config :'	);
		}# if debug
		my $ssp = test_path ( $setup, 'scratchspace', $n);	# scratchspace	=>	/sswork
		my $process	= test_entry( $setup, 'process'     , $n);	# add process	=>	gf22/
		my $project	= test_entry( $setup, 'project'		, $n);	# add project	=>	niuez1z1/
		my $user	= test_entry( $setup, 'user'        , $n);  # add user		=>	lfilor/
		my $workarea= test_entry( $setup, 'workarea'    , $n);  # add workarea	=>	wa1/
		my $aspect	= test_entry( $setup, 'aspect'      , $n);  # add aspect	=>	coverage/
		my $period	= test_entry( $setup, 'period'      , $n);  # add period	=>	weekly,nightly,special
		my $report	= test_entry( $setup, 'report'      , $n);	# add report	=>	cov_report_ww10/
		my $zarchiv	= test_entry( $setup, 'archive'     , $n);  # add archive	=>	pages/
		my $index	= test_entry( $setup, 'index'		, $n);  # add index		=>	legacy.html
		my $smry	= test_entry( $setup, 'summary'     , $n);	# add summary	=>	covsummary.html
		my $spec	= test_entry( $setup,'specification', $n);  # add Coverage specification .xlsx

				  test_owner( $user, $n );

		my $path= probepath ( "$ssp/$process"  ,$n );
		   $path= probepath ( "$path/$project" ,$n );
		   $path= probepath ( "$path/$user"    ,$n );
		   $path= probepath ( "$path/$workarea",$n );
		   $path= probepath ( "$path/$aspect"  ,$n );
		   $path= probepath ( "$path/$period"  ,$n );
		my $writeback= $path;							# default output path preserved & protected
		my $rpth= probepath ( "$path/$report"  ,$n );
		my $Zarchive = probepath ( "$rpth/$zarchiv" ,$n );

		my $Zspec	= probefile ( "$path/$spec",$n );	# fullpath specification.xlsx
		my $Zindex	= probefile ( "$rpth/$index",$n );	# fullpath coverage_report/index.html
		my $Zsummary= probefile ( "$rpth/$smry",$n );	# fullpath coverage_report/covsummary.html

		${$setup}{initial}{path}	=	$rpth;			# path zArchive 
		${$setup}{initial}{archiv}	=	$Zarchive;		# zArchive
		${$setup}{initial}{report}	=	$Zindex;		# zCoverage report index
		${$setup}{initial}{summary}	=	$Zsummary;		# zCoverage report summary
		${$setup}{initial}{covspec}	=	$Zspec;			# zSpecification   Self reference
		${$setup}{initial}{wrt_bck} =	$writeback;		# writeback path

		${$setup}{ovrwrit}{ovrwrite}=   $FALSE;
		${$setup}{ovrwrit}{report}	=	${$setup}{coverage};
		${$setup}{ovrwrit}{summary}	=	${$setup}{summary};
		${$setup}{ovrwrit}{covspec}	=	${$setup}{workbook};

		test_file ( $setup, 'workbook'    , $n );
		test_file ( $setup, 'ReportName'  , $n );
		test_path ( $setup, 'zArchive'	  , $n );
		test_date ( $setup, 'ReportDate'  , $n );
		test_entry( $setup, 'workbook'    , $n );
		test_entry( $setup, 'manager'     , $n );
		test_entry( $setup, 'author'      , $n );
		test_entry( $setup, 'title'       , $n );
		test_entry( $setup, 'subject'     , $n );
		printf  "\n%5s%s() ...done\n",''  , $n if (debug($n));
}#sub   validate_setup


sub		overwrite_setup	{
		my	(	$setup		)	= @_;
        my  $n = subroutine('name');                # identify sub by name
		if (debug($n))	{
            printf "\n%5s%s() \n",'',$n;
			list_ref ( $setup, 'config :'	);
		}#

		# NO OVERWRITE ENABLED on purpose			# This feature should be requested
		# This feature is making the control very complex - and is tabled
		# This would be the location to implement this feature

		foreach my $key ( keys ${$setup}{initial} ) {

			${$setup}{final}{$key}  = ${$setup}{initial}{$key};

		}#
		list_ref ( $setup, 'config :'	) if (debug($n));
		printf  "\n%5s%s() ...done\n",''  , $n if (debug($n));
}#sub	overwrite_setup


sub		get_writebackpath	{
		my	(	$setup	)	= @_;
		return ${$setup}{final}{wrt_bck};
}#sub	get_writebackpath


sub		full_wbkpath	{
		my	(	$setup
			,	$filename	)	= @_;
		return ${$setup}{final}{wrt_bck}.'/'.$filename;
}#sub	full_wbkpath


#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S
#

sub		test_owner	{
		my	(	$owner
			,	$name	)	=	@_;
		if	( debug($name))	{
			printf "%*s%*s = %s\n",5,'',10,'user',$owner;
			printf "%*s%*s = %s\n",5,'',10,'user',$ENV{USERNAME};
		}# if debug
		my $t	= ($owner eq $ENV{USERNAME})?$TRUE:$FALSE;
        my $msg = sprintf ("\n%*s%s\n\n",5,'',"WARNING Specification user $owner not matching !!");
        print BLINK BOLD RED $msg, RESET unless $t;
		exit unless $t; 
}#sub	test_owner


sub		probepath	{
		my	(	$path	
			,	$name	)	=	@_;
		if ( debug($name)) {
			printf "\n%*s%*s = %s\n",5,'',10 ,'Subpath ',$path;
		}# if debug
		my	$e = ( -d $path)? $TRUE : $FALSE;
        my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING Path $path not found !!");
        print BLINK BOLD RED $msg, RESET unless $e;
		if ( debug($name)) {
			$msg = sprintf ("%*s%s\n",5,'',"$path tested !!");
			print BLINK BOLD BLUE $msg, RESET if $e;
		}# if debug
		return $path;
}#sub	probepath


sub		probefile	{
		my	(	$fullpath	
			,	$name	)	=	@_;
		if ( debug($name)) {
			printf "\n%*s%*s = %s\n",5,'',10 ,'Fullpath ',$fullpath;
		}# if debug
        my	$e	= (-f $fullpath)? $TRUE : $FALSE;
        my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING File $fullpath not found !!");
        print BLINK BOLD RED $msg, RESET unless $e;
		if ( debug($name)) {
			$msg = sprintf ("%*s%s\n",5,'',"$fullpath tested !!");
			print BLINK BOLD BLUE $msg, RESET if $e;
		}# if debug
		return $fullpath
}#sub	probefile


sub		test_entry	{
		my	(	$hash
			,	$key
			,	$name	)	=	@_;
		if ( debug($name)) {
			printf "%*s%*s = %s\n",5,'',15,$key, ${$hash}{$key};
		}# if debug
		exit unless ( hashkey_exists ( $hash, $key, $name ) );
		exit unless ( hashkey_defined( $hash, $key, $name ) );
		return ${$hash}{$key};
}#sub	test_entry


sub		test_file	{
		my	(	$hash
			,	$key
			,	$name	)	=	@_;
		if ( debug($name)) {
			printf "\n";
			printf "%*s%*s = %s\n",5,'',10 ,$key, ${$hash}{$key};
		}# if debug
		exit unless ( hashkey_exists ( $hash, $key, $name ) );
		exit unless ( hashkey_defined( $hash, $key, $name ) );
		exit unless ( file_exists	 ( $hash, $key, $name ) );
}#sub	test_entry


sub		test_path	{
		my	(	$hash
			,	$key
			,	$name	)	=	@_;
		if ( debug($name)) {
			printf "\n";
			printf "%*s%*s = %s\n",5,'',10 ,$key, ${$hash}{$key};
		}# if debug
		exit unless ( hashkey_exists ( $hash, $key, $name ) );
		exit unless ( hashkey_defined( $hash, $key, $name ) );
		exit unless ( path_exists	 ( $hash, $key, $name ) );
		return ${$hash}{$key};
}#sub	test_path


sub		test_date	{
		my	(	$hash
			,	$key
			,	$name	)	=	@_;
		if ( debug($name)) {
			printf "\n";
			printf "%*s%*s = %s\n",5,'',10 ,$key, ${$hash}{$key};
		}
		exit unless ( hashkey_exists ( $hash, $key, $name ) );
		exit unless ( hashkey_defined( $hash, $key, $name ) );
		my ($Y,$M,$D) = split ('-',${$hash}{$key});
		my ($U,$V,$W) = split ('-', strftime '%Y-%m-%d', localtime);
		my $cur = 'TodaysDate';
		my $date= ${$hash}{$key};
		if ( debug($name)) {
			printf "%*s%*s = %s-%s-%s+\n",5,'',10,$key,$Y,$M,$D;
			printf "%*s%*s = %s-%s-%s-\n",5,'',10,$cur,$U,$V,$W;
		}#if debug
		
		my $t1	= ($Y > $U)? $FALSE : $TRUE;
		my $msg1= sprintf ("\n%*s%s\n\n",5,'',"WARNING YEAR    $Y is in the future");
		print BLINK BOLD RED $msg1, RESET unless $t1;
		exit  unless $t1;

		my $t2	= ($M > $V) ? $FALSE : $TRUE;
		my $msg2= sprintf ("\n%*s%s\n\n",5,'',"WARNING MONTH   $M is in the future");
		print BLINK BOLD RED $msg2, RESET unless $t2;
		exit  unless $t2;

		my $t3	= ($M eq $V && $D > $W)?$FALSE:$TRUE;
		my $msg3= sprintf ("\n%*s%s\n\n",5,'',"WARNING DAY     $D is in the future");
		print BLINK BOLD RED $msg3, RESET unless $t3;
		exit  unless $t3;

		my $t4	= ( $Y eq $U && $M eq $V && $D eq $W )?$TRUE:$FALSE;	
		my $msg4= sprintf ("\n%*s%s\n\n",5,'',"DEFAULT DATE    $date ");
		print BLINK BOLD GREEN $msg4, RESET if $t4;

		my $t5	=	(	( $Y==$U && $M==$V && $D <$W )
					 || ( $Y==$U && $M <$V)
					 || ( $Y <$U) ) ? $TRUE:$FALSE;	
		my $msg5= sprintf ("\n%*s%s\n\n",5,'',"BACKDATING DATE $date ");
		print BLINK BOLD BLUE $msg5, RESET if $t5;
}#sub	test_date
		

sub		hashkey_exists	{
		my	(	$hash
			,	$key
			,	$name	)	=	@_;
		my $e =	( exists ${$hash}{$key} )? $TRUE : $FALSE;
		my $m = sprintf ("\n%*s%s\n",5,'',"WARNING hashkey $key doesn't exists !!");
		printf BLINK BOLD RED $m, RESET unless $e;
		return $e;
}#sub	hashkey_exists


sub		hashkey_defined	{
		my	(	$hash
			,	$key
			,	$name	)	=	@_;
		my $e =	( defined ${$hash}{$key} )? $TRUE : $FALSE;
		my $m = sprintf ("\n%*s%s\n",5,'',"WARNING hashkey $key NOT defined !!");
		printf BLINK BOLD RED $m, RESET unless $e;
		return $e;
}#sub	hashkey_defined


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


sub		path_exists	{
		my	(	$hash
			,	$key
			,	$name	)	= @_;
		my	$d = ${$hash}{$key};
		if ( debug($name)) {
			my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING Directory $d not found !!");
			printf "%*s%s\n", 5,'',"Path $d";
			printf "%*s%s\n",10,'','exists'    if ( -e $d);
			printf "%*s%s\n",10,'','directory' if ( -d $d);
			printf "%*s%s\n",10,'','readable'  if ( -r $d);
			printf "%*s%s\n",10,'','writeable' if ( -w $d);
		}#if debug
		my	$e = ( -d $d)? $TRUE : $FALSE;
        my $msg = sprintf ("\n%*s%s\n",5,'',"WARNING Directory $d not found !!");
        print BLINK BOLD RED $msg, RESET unless $e;
		return $e;
}#sub	path_exists
		

#----------------------------------------------------------------------------
#  End of module
1;
