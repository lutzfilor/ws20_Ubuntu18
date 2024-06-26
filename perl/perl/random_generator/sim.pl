#!/tools/sw/perl/bin/perl -w
my $VERSION = "1.01.01";

use strict;
use warnings;
use Getopt::Long;

sub simulate;

my %defines;
my %opts    =   (  #from                =>   optional,                      # Optional Command line options -- No default settings
                   #until               =>   optional,                      # Optional Command line options -- No default settings
                    iterations          =>   100,                           # Default iterations
                    csv_default         =>  'random.csv',                   # Default logname
                );                                                          # Command Line Options 

GetOptions      (   'help|h|?'          =>  \&help,                         # Usage Information
                    'simulate|sim|s'    =>  \&simulate(),                   #           Run simulation
                    'man'               =>  \&manual,
                    'debug'             =>  \$opts{debug},                  # Turn      ON LOGGING
                    'info'              =>  \$opts{info},                   # Report    trace file information => window (Open, Close)
                    'iteration|i=i'     =>  \$opts{iterations},             # Overwrite default iteration number
                );                                                          # Command Line Processor
sub   help {
      printf "\n";
      printf " ... script usage :: %s\n", $VERSION;
      printf "\n";
      printf "     <%s>  --help                  -- Get this information\n",$0;
      printf "               --file=<file_name>      -- Determine input fileinfo \n";
     #printf "                  --trace=<file_name>     --from=<time> --until=<time>\n";
     #printf "\n";
     #printf "                  --trace_dir=<pathname>\n";
     #printf "                  --trace_dir=<pathname>  --from=<time> --until=<time>\n";
      printf "\n";
      printf "     NOTE           Don't terminate <pathname> with an </> at the end!!\n";
      printf "\n";
     #printf "     Optional     --Redirecting output\n";
     #printf "     <%s>   --trace_dir=<pathname>  --from= --until= --o=reports ...\n",$0;
     #printf "\n";
      printf "     Debugging\n";
      printf "     <%s>   [options] [parameter] | & tee ./log.out\n",$0;
      printf "\n";
      exit 0;
}#sub help

sub   manual{
}#sub 

sub   simulate{
      my $logfile = $opts{csv_default};
      open(my $logh, ">$logfile")|| die " Can not create log $logfile";             # Are the bus transfers accounted for ? Mendatory
    
      for (my $i=$opts{iterations};$i;$i--) {
            my $val = rand();
            printf       "%14.12f\n", $val;
            printf $logh "%14.12f\n", $val;
            my $a=$val;
            printf       "%s\n", $a;
            for (my $p=1;$p<=24;$p++){
                #$a      = ($a<<2+$a)<<1;
                $a      *= 10;
                #printf       "%s\n", $a;
                my $i   = int($a);
                printf "%*s%2s :: %2s :: %14.12f :: %s\n",5,'',$p,$i,$a,$a;
                $a -= $i;
            }#for
      }#for
      close( $logh );
}#sub


