package PPCOV::DataStructure::DS;
#----------------------------------------------------------------------------
# P A C K A G E - H E A D E R
#
# File          lib/PPCOV/DS.pm
#
# Created       02/08/2019          
# Author        Lutz Filor
# 
# Synopsys      PPCOV::DS::list_ref()
#				PPCOV::DataStructure::DS::list_ref()
#                       input   reference to data structure
#                       output  STDOUT terminal
#                       return
#
#----------------------------------------------------------------------------
#  I M P O R T S 

use strict;
use warnings;

use Readonly;
use Switch;                                         # Installed 11/28/2018

use lib                     qw  (   ~/ws/perl/lib       );               # Relative UserModulePath
use Dbg                     qw  /   debug subroutine    /;
use File::IO::UTF8::UTF8    qw  /   read_utf8   
                                    write_utf8  /;

#----------------------------------------------------------------------------
#  I N T E R F A C E

use version; our $VERSION =version->declare("v1.01.08");

use Exporter qw (import);                           # Import <import>method  
use parent 'Exporter';                              # parent replaces base

our @EXPORT     =   qw  (    
                        );#implicite export         # NOT recommended 

our @EXPORT_OK  =   qw  (   list_ref
                        );#explicite export         # RECOMMENDED method

our %EXPORT_TAGS=       ( ALL => [ @EXPORT_OK ],    # 
                        );

#----------------------------------------------------------------------------
#  C O N S T A N T S
Readonly my $TRUE           =>     1;               # Create boolean like constant
Readonly my $FALSE          =>     0;

#----------------------------------------------------------------------------
#  S U B R O U T I N S  -  P U B L I C  M E T H O D E S

sub     list_ref    {
        my  (   $ur_ref								# unknown reference
            ,   $fp			)   =   @_;				# format parameter	{ }
		${$fp}{name}	//= 'unknown';
		${$fp}{level}	//=	0;						# hierachy level
		${$fp}{indent}	//= 5;						# initial indentation
		${$fp}{pedding}	//= '';						# indentation pattern
		${$fp}{width}	//= length ${$fp}{name};	#
		${$fp}{reform}	//= $FALSE;
		${$fp}{reform}	=~	s/ON/$TRUE/;			# Reformat \n => ' '
		my $name		= ${$fp}{name};	
        my $n = subroutine('name');                 # identify sub by name
        my $l = ${$fp}{level};                      # hierachy level
        my $i = ${$fp}{indent};                     # indentation
		my $p = ${$fp}{pedding};
        my $w = ${$fp}{width};
        printf "\n";                                # vertical spacer
        if( debug($n))  {
            printf  "\n";
            printf  "%*s%s() \n",$i,'',$n;
            printf  "%*s%s %s\n",$i,''
                    ,'Reference type :'
                    ,ref $ur_ref;
			printf  "%*s%s %s\n",$i,$p,'Reformating    :',
					(${$fp}{reform})? 'ON ':'OFF';
        }# if debug
        switch ( ref $ur_ref ) {
            #case 'ARRAY'   { _iterate_array_o($ur_ref,$name,$i,$l,$w,$n); }
            case 'ARRAY'    { _iterate_array($ur_ref,$fp); }
            case 'CODE'     { _unknown_warn ($ur_ref,$n);                }
            case 'FORMAT'   { _unknown_warn ($ur_ref,$n);                }
            case 'GLOB'     { _unknown_warn ($ur_ref,$n);                }
            #case 'HASH'    { _iterate_hash_o ($ur_ref,$name,$i,$l,$w,$n); }
            case 'HASH'     { _iterate_hash ($ur_ref,$fp); }
            case 'IO'       { _unknown_warn ($ur_ref,$n);                }
            case 'LVALUE'   { _unknown_warn ($ur_ref,$n);                }
            case 'REF'      { _unknown_warn ($ur_ref,$n);                }
            case 'SCALAR'   { _unknown_warn ($ur_ref,$n);                }
            case 'VSTRING'  { _unknown_warn ($ur_ref,$n);                }
            #else           { _printf_scalar_o($ur_ref,$name,$i,$l,$w,$n); }
            else            { _printf_scalar($ur_ref,$fp); }
        }#switch
}#sub   list_ref

#----------------------------------------------------------------------------
#  P R I V A T E  M E T H O D S

sub     maxwidth    {
        my  (   $array_r    )   =   @_;
        my  $max    =   0;
        foreach my $entry  ( @{$array_r} ) {
            my $tmp =   length($entry);
            $max = ( $max > $tmp ) ? $max : $tmp;
            #printf "%9s%*s\t%s\n",'',$max,$entry,$tmp;
        }#for all
        #printf "%9s%*s\t%s\n",'',$max,'max',$max;
        return $max;
}#sub   maxwidth


sub     _iterate_hash_o {
        my  (   $ref                                # reference address
            ,   $name                               # reference name/key
            ,   $indent                             # indentation
            ,   $level                              # structure hierachy
            ,   $width                              # width of  hierachy
            ,   $n      )   =   @_;                 # function  call
        my $i   = $indent;                          # indentation
        my $l   = ++$level;
        my $r   = ref $ref;
        my @e   = keys %{$ref};                     # entries, number of
        printf  "%*s%*s = %s( %s ) %s\n"
                ,$i,'',$width,$name,$r
                ,$#e+1,'entries';
        my $w   = maxwidth ( [keys %{$ref}] );      # width of keywords
        $i  =   $i + $width + 3;
        foreach my $key ( keys %{$ref}) {
            my  $r  =   ${$ref}{$key};              # reference
            switch  ( ref $r ) {
                case 'ARRAY'    { _iterate_array_o	($r,$key,$i,$l,$w,$n); }
                case 'CODE'     { _unknown_warn		($r,$n);            }
                case 'FORMAT'   { _unknown_warn		($r,$n);            }
                case 'GLOB'     { _peeking_glob_o	($r,$key,$i,$l,$w,$n); }
                case 'HASH'     { _iterate_hash_o	($r,$key,$i,$l,$w,$n); }
                case 'IO'       { _unknown_warn		($r,$n);            }
                case 'LVALUE'   { _unknown_warn		($r,$n);            }
                case 'REF'      { _unknown_warn		($r,$n);            }
                case 'SCALAR'   { _unknown_warn		($r,$n);            }
                case 'VSTRING'  { _unknown_warn		($r,$n);            }
                else            { _printf_scalar_o	($r,$key,$i,$l,$w,$n); }
            }#switch
        }# foreach entry in hash
}#sub   _iterate_hash_o


sub     _iterate_hash   {
        my  (   $ref                                # reference address
			,	$f		)	=	@_;					# format parameter
        my $name= ${$f}{name};						# name/key
        my $l   = ${$f}{level}+1;
        my $i   = ${$f}{indent};                    # indentation
		my $p	= ${$f}{pedding};
		my $wi  = ${$f}{width};
		my $c   = ${$f}{caller};
        my $r   = ref $ref;							# type of reference
        my @e   = keys %{$ref};                     # entries, number of
        printf  "%*s%*s = %s( %s ) %s\n"
                ,$i,$p,$wi,$name,$r
                ,$#e+1,'entries';
        my $w   = maxwidth ( [keys %{$ref}] );      # width of keywords
        $i  =   $i + $wi + 3;
        foreach my $key ( keys %{$ref}) {
            my  $r  =   ${$ref}{$key};              # reference
			my	$fp	=	{	name	=>	$key,		# format parameter
							level	=>	$l,
							indent	=>	$i,
							pedding =>	$p,
							width	=>	$w,
							caller  =>  $c,
							reform	=>	${$f}{reform},
						};
            switch  ( ref $r ) {
                case 'ARRAY'    { _iterate_array($r,$fp); }
                case 'CODE'     { _unknown_warn ($r,$c);  }
                case 'FORMAT'   { _unknown_warn ($r,$c);  }
                case 'GLOB'     { _peeking_glob ($r,$fp); }
                case 'HASH'     { _iterate_hash ($r,$fp); }
                case 'IO'       { _unknown_warn ($r,$c);  }
                case 'LVALUE'   { _unknown_warn ($r,$c);  }
                case 'REF'      { _unknown_warn ($r,$c);  }
                case 'SCALAR'   { _unknown_warn ($r,$c);  }
                case 'VSTRING'  { _unknown_warn ($r,$c);  }
                else            { _printf_scalar($r,$fp); }
            }#switch
        }# foreach entry in hash
}#sub    _iterate_hash2 


sub     _iterate_array_o  {
        my  (   $ref                                # reference address
            ,   $name                               # reference name/key
            ,   $indent                             # indentation
            ,   $level                              # structure hierachy
            ,   $width                              # width of  hierachy
            ,   $subn   )   =   @_;                 # function  call
        my $n = subroutine('name');                 # identify sub by name
        printf  "%5s%s()\n",'',$n if ( debug ($n));
        my $i   = $indent;
        my $l   = $level++;
        my $r   = ref $ref;
        my $s   = $#{$ref}+1;                       # size of array
        my $w   = length $s;                        # Number of places
        printf  "%*s%*s = %s( %s ) %s\n"
                ,$i,'',$width,$name,$r,$s,'elements';
        my $c   = 0;								# cell, index
        $i  =   $i + $width + 3;
        foreach my $entry ( @{$ref} ) {
            my  $r  =   $entry;                     # reference
            $c++;
            #printf "%5s%*s %s\n",'',$w,$c, $entry;
            switch  ( ref $r ) {
                case 'ARRAY'    { _iterate_array($r,$c,$i,$l,$w,$subn); }
                case 'CODE'     { _unknown_warn ($r,$n);                }
                case 'FORMAT'   { _unknown_warn ($r,$n);                }
                case 'GLOB'     { _unknown_warn ($r,$n);                }
                case 'HASH'     { _iterate_hash ($r,$c,$i,$l,$w,$subn); }
                case 'IO'       { _unknown_warn ($r,$n);                }
                case 'LVALUE'   { _unknown_warn ($r,$n);                }
                case 'REF'      { _unknown_warn ($r,$n);                }
                case 'SCALAR'   { _unknown_warn ($r,$c);                }
                case 'VSTRING'  { _unknown_warn ($r,$n);                }
                else            { _printf_scalar($r,$name,$i,$l,$w,$subn); }
            }#switch
        }# for each entry
}#sub   _iterate_array_o


sub     _iterate_array  {
        my  (   $ref                                # reference address
			,	$fp		)	=	@_;					# format parameter
        my $k   = ${$fp}{name};						# name/key
        my $i   = ${$fp}{indent};                   # indentation
        my $l   = ${$fp}{level}+1;
		my $p	= ${$fp}{pedding};
		my $wi  = ${$fp}{width};					# reservation for key
		my $c   = ${$fp}{caller};					# subroutine name of list_ref()
        my $r   = ref $ref;
        my $s   = $#{$ref}+1;                       # size of array
        my $w   = length $s;                        # Number of places
        my $n = subroutine('name');                 # identify sub by name
        printf  "%5s%s()\n",'',$n if ( debug ($n));
        printf  "%*s%*s = %s( %s ) %s\n"
                ,$i,'',$wi,$k,$r,$s,'elements';
        my $ix   = 0;								#
        $i  =   $i + $wi + 3;
        foreach my $entry ( @{$ref} ) {
            my  $r  =   $entry;                     # reference
            $ix++;
			my	$f	=	{	name	=>	$ix,		# format parameter
							level	=>	$l,
							indent	=>	$i,
							pedding =>	$p,
							width	=>	$w,
							caller  =>  $c,
							reform	=>	${$fp}{reform},
						};            
			#printf "%5s%*s %s\n",'',$w,$c, $entry;
            switch  ( ref $r ) {
                case 'ARRAY'    { _iterate_array($r,$f); }
                case 'CODE'     { _unknown_warn ($r,$n); }
                case 'FORMAT'   { _unknown_warn ($r,$n); }
                case 'GLOB'     { _unknown_warn ($r,$n); }
                case 'HASH'     { _iterate_hash ($r,$f); }
                case 'IO'       { _unknown_warn ($r,$n); }
                case 'LVALUE'   { _unknown_warn ($r,$n); }
                case 'REF'      { _unknown_warn ($r,$n); }
                case 'SCALAR'   { _unknown_warn ($r,$c); }
                case 'VSTRING'  { _unknown_warn ($r,$n); }
                else            { _printf_scalar($r,$f); }
            }#switch
        }# for each entry
}#sub   _iterate_array


sub     _printf_scalar_o  {
        my  (   $value                              # reference address
            ,   $key                                # reference name/key
            ,   $indent                             # indentation
            ,   $level                              # structure hierachy
            ,   $width  )   =   @_;                 # width of  hierachy
        my $n = subroutine('name');                 # identify sub by name
        printf  STDERR "%5s%s( %s )\n",'',$n,$key, if ( debug($n));
        my $i   = $indent;                          # indentation
        my $w   = $width;							# 
        my $k   = $key;
        my $v   = $value;                         	# reference is scalar
		if ( defined $v ) {
			printf STDERR "%*s%*s = %s\n",$i,'',$w,$k,$v;
		} else {
			printf STDERR "%*s%*s = %s\n",$i,'',$w,$k,'undef';
		}
}#sub   _printf_scalar_o


sub     _printf_scalar  {
        my  (   $value                              # reference address
			,	$fp		)	=	@_;					# format parameter
        my $i   = ${$fp}{indent};                   # indentation
        my $p   = ${$fp}{pedding};		
        my $w   = ${$fp}{width};					# 
        my $k   = ${$fp}{name};						# key is the name vpair
        my $v   = $value;                         	# reference is scalar
        my $n = subroutine('name');                 # identify sub by name
		if ( debug($n)) {
	        printf  STDERR "%*s%s( %s )\n",$i,$p,$n,$k;
			printf  STDERR "%*s%s %s\n"   ,$i,$p
					,'Reformating    :',
					(${$fp}{reform})? 'ON ':'OFF';
		}# if debug
		if ( defined $v ) {
			$v =~ s/\n/ / if ${$fp}{reform};		# reformat \n => ' '
			printf STDERR "%*s%*s = %s\n",$i,$p,$w,$k,$v;
			#printf STDERR "\t%s\n", $
		} else {
			printf STDERR "%*s%*s = %s\n",$i,$p,$w,$k,'undef';
		}
}#sub   _printf_scalar


sub		_peeking_glob_o	{
        my  (   $ref                                # reference address
            ,   $key                                # reference name/key
            ,   $indent                             # indentation
            ,   $level                              # structure hierachy
            ,   $width                              # width of  hierachy
            ,   $n      )   =   @_;                 # function  call
        #my $n = subroutine('name');                # identify sub by name
        printf  "%5s%s( %s )\n",'',$n,$key, if ( debug($n));
}#sub	_peeking_glob


sub		_peeking_glob	{
        my  (   $ref                                # reference address
			,	$fp		)	=	@_;					# format parameter
        my $i   = ${$fp}{indent};                   # indentation
        my $p   = ${$fp}{pedding};		
        my $k   = ${$fp}{name};						# name/key
        my $n	= subroutine('name');               # identify sub by name
		if ( debug($n)) {
			printf  "%*s%s( %s )\n",$i,$p,$n,$k;	# Reference is a GLOB
		}# if debug
}#sub	_peeking_glob


sub     _unknown_warn   {
        my  (   $ref  
            ,   $n      )   =   @_;                 # name of subroutin 
        my $type=   ref $ref;
        my $msg = 'Unknown reference in '.$n.'() '.$type;
        printf "%5s%s\n",'',$msg;
        printf "\n";
}#sub   _unknown_warn

#----------------------------------------------------------------------------
#  End of module
1;
