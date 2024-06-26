#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;

my  %options        =   (   );                                      #   API storage
my  %description    =   (   'file|f=s'    =>  \$options{file} );    #   API 
GetOptions  (    %description   );
#my  @file   =   read_utf8   (   $options{file}     );
my  @file   =   get_data   (   $options{file}     );
analyze_log ( [ @file ] );
logfile_age ( [ @file ] );

#=====================================================
#   P R I V A T E - M E T H O D S

sub     days_old    {
        my ( $date  )   =   @_;
        my  $today  =   `date +%F`;
        chomp $today;
        printf "%*sToday %s\n",5,'',$today;
        return;
}#sub   days_old

sub     get_data    {
        my  ( $filename )   =   @_;
        if (   $filename eq ''   )   {
            printf  "%*susage --file|f=filename\n",5,'';
            printf  "%*sScript terminated\n",5,'';
            exit 1;
        } 
        if  ( -e $filename ) {
            printf  "%*sFile %s found\n",5,'', $filename;
        } else {
            printf  "%*sFile  %s NOT found!!\n"   ,5,'', $filename;
            printf  "%*sCheck filename and path\n",5,'', $filename;
            exit 2;
        }
        return  read_utf8( $filename );
}#sub   get_data

sub     read_utf8 {
        my    (   $f  )   =   @_;                       #   Full Filename
        open (my $fh,'<:encoding(UTF-8)',"$f")
        || die "     Cannot open file $f";              #   Part of the document
        my @text =  ();
        while ( my $line = <$fh> ) {                    #   Remove new lines
            chomp($line);
            push (@text, $line);
        }#while
        close (  $fh );
        return @text;                                   #   Return array buffer
}#sub   read_utf8

sub     analyze_log {
        my  (   $ArrRef )   =   @_;
        my  $error  =   0;                              #   init  error counter
        my  $warn   =   0;                              #   init  warn  counter
        my  $ln     =   1;                              #   init  line  number
        my  $ftm    =   '';                             #   first text  message
        foreach my $line ( @{$ArrRef} ) {
            my  @col    =   split(/,/, $line);
            #   NOTE my logfile has a header line, thus the first text message is in 2nd line 
            $ftm    =   $col[$#col] if ( $ln == 2);     #   capture first text message                    
            #printf  "%*s%s\n",5,'',$line;
            $warn++     if ( $line =~ m/WARNING/ && $ln > 1);
            $error++    if ( $line =~ m/ERROR/   && $ln > 1);
            $ln++;                                      #   Update line counter
        }#iterate file
        printf  "%*sNumber of warnings %s\n",5,'',$warn;
        printf  "%*sNumber of errors   %s\n",5,'',$error;
        printf  "%*sFirst text message:%s\n",5,'',$ftm;
        return;
}#sub   analyze_log

sub     logfile_age {
        my  (   $filename )   =   @_;
        my  $today  =   `date +%F`;
        #my  $logfile=   `date -r "$filename" +"%Y-%m-%d"`;         # fails
        my  $logfile=   `date -r logfile.log +"%Y-%m-%d"`;          # works
        #my  @args = ( "date","-r",$filename,"+%Y-%m-%d" );         # 
        #my  $logfile= system @args;                                # fails

        #my  $lcmd   =   "date -r ". $filename . " +%Y-%m-%d";
        #my  $logfile=   `$lcmd`;
        chomp $today;
        chomp $logfile;

        my  $cmd2   =   "date -d ". $today . " +%s";
        my  $cmd1   =   "date -d ". $logfile . " +%s";
        printf  "%*sCommand1 %s\n",5,'',$cmd1;
        printf  "%*sCommand2 %s\n",5,'',$cmd2;
        my  $tmp2   =   `$cmd2`;
        my  $tmp1   =   `$cmd1`;

        #my  $cmd3   =   "( " . $cmd2 . ") - (" . $cmd2 . " )"; 
        my  $age    =   ($tmp2 - $tmp1) / 86400;

        #y  $tmp1   =   system "date", "-d", $logfile, "+%Y-%m-%d";
        chomp   $tmp1;
        chomp   $tmp2;
        #chomp   $age;
        printf "%*sToday %s\n",5,'',$today;
        printf "%*sLfile %s\n",5,'',$logfile;
        #printf "%*s%s days old\n",5,'',$age;
        printf "%*sTemp2 %s\n",5,'',$tmp2;
        printf "%*sTemp1 %s\n",5,'',$tmp1;
        printf "%*sDays %s\n",5,'',$age;
        return;
}#sub   logfile_age
