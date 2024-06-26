package Logging::Record;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/Logging/Record.pm
#
# Created       02/13/2019  v1.01.01 Add log_msg()		-- strings, append
#									 Add discard_logs() -- remove log files
#				03/05/2019	v1.01.02 Add silent option
#									 Add debug feature
#				05/08/2019  v1.01.03 Refactor File::IO::UTF8::UTF8
#
# Author        Lutz Filor
# 
# Synopsys      Logging::Record::log_msg()
#                   input   message, 
#                   return  list of design instances
#               Logging::Record::discard_logs()
#					input	list of logfile names
#
# NOTE          Maintain Logging::Changes log to document this module            
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Switch;                                                                         # Installed 11/28/2018
use Readonly;
use Term::ANSIColor             qw  (   :constants  );                              # available
#   print BLINK BOLD RED $msg, RESET;

use lib							qw  (   /mnt/ussjf-home/lfilor/ws/perl/lib );       # Add Include path to @INC
use Dbg                         qw  (   debug subroutine    );
use File::IO::UTF8::UTF8        qw  (   read_utf8   );

#use lib             qw  (   ../lib );               # Relative UserModulePath      05/08/2019
#use UTF8            qw  (   read_utf8   );
#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.03");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  ( log_msg
						  log_lmsg
						  discard_logs
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S
Readonly my $TRUE           =>     1;               # Create boolean like constant
Readonly my $FALSE          =>     0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S


sub		discard_logs	{
		my	(	$silent
			,	@list		)	= @_;
			$silent			//=	0;

        my $n =  subroutine('name');                # identify the subroutine by name
		foreach	my $log	( @list )	{
			printf "%5s%s %s\n",'','>Erase ',$log unless $silent;
			if ( -e $log ) {
				my $cmd = 'rm -f '."$log";		
				`$cmd`; 
				#unlink ( $log );
			} else {
				if( debug($n)) {
					printf "%5s%s %s\n",'',$log,'file not found !!';
				}# if debug
			}# if not exist
		}# for 
}#sub	discard_logs


sub		log_msg		{
	    my	(	$reference
			,	$logfile	)	= @_;
			
		open(my $fh,'>>:encoding(UTF-8)',$logfile);
        switch  ( ref $reference ) {
            case 'ARRAY'    { _array	($fh, $reference); }
            case 'CODE'     { _unknown	($fh, $reference); }
            case 'FORMAT'   { _unknown 	($fh, $reference); }
            case 'GLOB'     { _unknown 	($fh, $reference); }
            case 'HASH'     { _unknown	($fh, $reference); }
            case 'IO'       { _unknown	($fh, $reference); }
            case 'LVALUE'   { _unknown	($fh, $reference); }
            case 'REF'      { _unknown 	($fh, $reference); }
            case 'SCALAR'   { _unknown 	($fh,$$reference); }
            case 'VSTRING'  { _unknown 	($fh, $reference); }
			else            { _scalar	($fh, $reference); }
        }#switch
		
		close ( $fh );
}#sub	log_msg


#		long strings, from .json, .XML, .xlsx files create problems
#		when tried to be written to a log file as the logfile could
#		become unreadable, and cluddered

sub		log_lmsg	{
		my	(	$reference
			,	$logfile	)	= @_;
		open(my $fh,'>>:encoding(UTF-8)',$logfile);
        switch  ( ref $reference ) {
            case 'ARRAY'    { _unknown		($fh, $reference); }                                                                                             																									
			case 'HASH'		{ _unknown		($fh, $reference); }
			else			{ _long_scalar	($fh, $reference); }
		}#switch
		close ( $fh );
}#sub	log_lmsg


sub		_scalar	{
		my	(	$fh
			,	$message	)	= @_;
		printf	$fh	"%s\n", $message;
}#sub	_scalar


sub		_long_scalar {
		my	(	$fh
			,	$msg						# message
			,	$i							# indent
			,	$l			)	= @_;		# text length
		$i	//=	 9;
		$l	//=	80;
		my	$TEM = "A$l*";					# TEMPLATE
		my	@tmp = unpack ( $TEM, $msg);
		foreach my $line ( @tmp ) {
			printf $fh "%*s%s\n",$i,'',$line;
		}#for all chunks
}#sub	_long_scalar


sub		_array	{
		my	(	$fh
			,	$a_ref		)	= @_;
		foreach my $line ( @{$a_ref} ) {
		   chomp $line;
      	   printf $fh "%s\n",$line;
      	}#
}#sub   _array

sub		_unknown	{
		my	(	$fh
			,	$reference	)	= @_;
		my $type= ref $reference;
		if ( undef $type){ 
			$type	=	'SCALAR_not_REFERENCE';
		}
		my $msg = sprintf ("\n%*s%s\n",5,''
						  ,"WARNING $type reference not implemented");
		#print $fh BLINK BOLD RED $msg, RESET;
		printf $fh	"%s", $msg;
}#sub	_unknown

## sub   write_array_to_file {
##       my    (   $a_ref                                                    # tmp arry buffer
##             ,   $file_name
##             ,   $opts_ref       )   = @_;
##                 $opts_ref       //= \%opts;
##                 $file_name      //= 'tmp.txt';
##       my $i = ${$opts_ref}{indent};
##       my $p = ${$opts_ref}{indent_pattern};                               # ${$opts_ref}{padding_pattern}
##       my $n = subroutine('name');
##       printf "%*s%s()\n",$i,$p,$n if( debug($n));
##       printf "%*s%s : %s\n", $i,$p, 'TestSequenceName', $file_name;
##       open(my $fh,'>:encoding(UTF-8)',$file_name);
##       foreach my $line ( @{$a_ref} ) {
##          printf $fh "%s\n",$line;
##       }#
##       close( $fh );
## }#sub write_arry
#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

#----------------------------------------------------------------------------
#  End of module
1;
