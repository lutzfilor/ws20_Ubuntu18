#!/tools/sw/perl/bin/perl -w

# main entry
if ($#ARGV != 2) {
    usage();
}

$filename = $ARGV[0];
$key_value = $ARGV[1];
$access_data = $ARGV[2];

open (FILE, "<$filename") || die "can not open input $filename";
@LINES = <FILE>;

my %AHB_hash;

my %command = (
    nonseq_seq_time => undef,
    hready_time => undef,
    cmd_type => undef,
    addr => undef,
    len => undef,
    burst_type => undef,
    burst_size => undef,
    hport => undef,
    next_cmd_ptr => undef,
    pre_cmd_ptr => undef,
    data_ptr => undef,
);

my %data = (
    data_nonseq_seq_time => undef,
    data_hready_time => undef,
    data_type => undef,
    data_addr => undef,
    beat_num => undef,
    data_value => undef,
    respone => undef,
    next_data_ptr => undef,
    pre_data_ptr => undef,
);


for ($i = 0; $i < $. ; $i++)
{
    $LINES[$i] =~ s/\|                //;
    $LINES[$i] =~ s/ ns//;
    $LINES[$i] =~ s/ ns//;
}

for ($i = 0; $i < $.; $i++)
{

    my %data;

    @line = split (/\|/, $LINES[$i]);

    if (index($line[2], "NONSEQ") != -1)
    {
        my %command;
        $command{nonseq_seq_time} = $line[0];
        $command{hready_time} = $line[1];
        $command{cmd_type} = $line[2];
        $command{addr} = $line[3];
        $command{len} = $line[5];
        $command{burst_type} = $line[8];
        $command{burst_size} = $line[9];
        $command{hport} = $line[10];

        my $command_addr = \%command;

        $command{pre_cmd_ptr} = $$addr_of_pre_command_addr;
        $command{pre_cmd_ptr}{next_cmd_ptr} = $command_addr;

        $addr_of_pre_command_addr = \$command_addr;

        $AHB_hash{$line[0]} = $command_addr;
    }

    if ((index($line[2], "DATA") != -1) | (index($line[2], "BUSY") != -1))
    {

        $data{data_nonseq_seq_time} = $line[0];
        $data{data_hready_time} = $line[1];
        $data{data_type} = $line[2];
        $data{data_addr} = $line[3];
        $data{beat_num} = $line[4];
        $data{data_value} = $line[6];
        $data{respone} = $line[7];

        my $data_address = \%data;

        if (index($data{beat_num}, "1/") != -1)
        {
            $$$addr_of_pre_command_addr{data_ptr} = $data_address;
            $data{pre_data_ptr} = 'undef';
        } 
        else 
        {
            if (((index($$$addr_of_pre_data_addr{data_type}, "WR-DATA") != -1) & ((index($data{data_type},"WR-DATA") != -1) | (index($data{data_type},"WR-BUSY") != -1))) |
                ((index($$$addr_of_pre_data_addr{data_type}, "RD-DATA") != -1) & ((index($data{data_type},"RD-DATA") != -1) | (index($data{data_type},"RD-BUSY") != -1))))
            {
                $data{pre_data_ptr} = $$addr_of_pre_data_addr;
                $data{pre_data_ptr}{next_data_ptr} = $data_address;
            }
        }

        $addr_of_pre_data_addr = \$data_address;

    }
}

#### for test dump
if (($access_data == 0) | ($access_data eq 'nonseq_assert_time'))
{
    print "$AHB_hash{$key_value}{nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_nonseq_seq_time}\n";
}

if (($access_data == 1) | ($access_data eq 'hready_assert_time'))
{
    print "$AHB_hash{$key_value}{hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_hready_time}\n";
}

if (($access_data == 2) | ($access_data eq 'dir_phase'))
{
    print "$AHB_hash{$key_value}{cmd_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_type}\n";
}

if (($access_data == 3) | ($access_data eq 'address'))
{
    print "$AHB_hash{$key_value}{addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_addr}\n";
}

if (($access_data == 4) | ($access_data eq 'beat_num'))
{
    print "$AHB_hash{$key_value}{data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{beat_num}\n";
}

if (($access_data == 5) | ($access_data eq 'burst_len'))
{
    print "$AHB_hash{$key_value}{len}\n";
}

if (($access_data == 6) | ($access_data eq 'data'))
{
    print "$AHB_hash{$key_value}{data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{data_value}\n";
}

if (($access_data == 7) | ($access_data eq 'respond'))
{
    print "$AHB_hash{$key_value}{data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
    print "$AHB_hash{$key_value}{data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{next_data_ptr}{respone}\n";
}

if (($access_data == 8) | ($access_data eq 'burst_type'))
{
    print "$AHB_hash{$key_value}{burst_type}\n";
}

if (($access_data == 9) | ($access_data eq 'burst_size'))
{
    print "$AHB_hash{$key_value}{burst_size}\n";
}

if (($access_data == 10) | ($access_data eq 'hport'))
{
    print "$AHB_hash{$key_value}{hport}\n";
}

if (($access_data == 11) | ($access_data eq 'next_command'))
{
    print "$AHB_hash{$key_value}{next_cmd_ptr}{nonseq_seq_time}\n";
}

if (($access_data == 12) | ($access_data eq 'prev_command'))
{
    print "$AHB_hash{$key_value}{pre_cmd_ptr}{nonseq_seq_time}\n";
}

foreach my $basename (keys %AHB_hash)
{
    #print "$AHB_hash{$basename}{pre_cmd_ptr}{data_ptr}{data_nonseq_seq_time}\n";
    #print "$AHB_hash{$basename}{next_cmd_ptr}{nonseq_seq_time}\n";
    #print "$AHB_hash{$basename}{data_ptr}{data_nonseq_seq_time}\n";
    #print "$AHB_hash{$basename}{nonseq_seq_time}\n";
}

close( FILE );

sub usage() {
    printf "\n";
    printf " Usage : <command>             <tracker_trace.file>  <start_time> <trace>\n";
    printf "          parse_ahb_tracker.pl  log_file_name         key_value    access_data [0..12] range\n";
    printf "\n";
    printf " Trace : Tracker-field select by            column# or string<Name>   \n";
    printf " ---------------------------------------------------------------------\n";
    printf "         Nonseq/Seq assert Time          :        0 || nonseq_assert_time\n";
    printf "         HREADY     assert Time          :        1 || hready_assert_time\n";
    printf "         DIR PHASE                       :        2 || dir_phase\n";
    printf "         ADDRESS                         :        3 || address\n";
    printf "         BEAT NUM                        :        4 || beat_num\n";
    printf "         LEN                             :        5 || burst_len\n";
    printf "         DATA                            :        6 || data\n";
    printf "         RESPONSE                        :        7 || response\n";
    printf "         BURST Type                      :        8 || burst_type\n";
    printf "         BURST Size                      :        9 || burst_size\n";
    printf "         HPORT                           :       10 || hport\n";
    printf "         Next     command                :       11 || next_command\n";
    printf "         Previous command                :       12 || prev_command\n";
    printf "\n";
    #print "Usage:parse_ahb_tracker.pl log_file_name key_value access_data[1:12] (refer below for number of access_data)\n";;
    #print "                     Nonseq/Seq assert Time                : 0 or nonseq_assert_time\n";
    #print "                     HREADY assert Time                : 1 or hready_assert_time\n";
    #print "                     DIR PHASE                    : 2 or dir_phase\n";
    #print "                     ADDRESS                        : 3 or address\n";
    #print "                     BEAT NUM                    : 4 or beat_num\n";
    #print "                     LEN                        : 5 or burst_len\n";
    #print "                     DATA                        : 6 or data\n";
    #print "                     RESPOND                        : 7 or respond\n";
    #print "                     BURST Type                    : 8 or burst_type\n";
    #print "                     BURST Size                    : 9 or burst_size\n";
    #print "                     HPORT                        : 10 or hport\n";
    #print "                     Next command Nonseq/Seq assert Time        : 11 or next_command\n";
    #print "                     Previous command Nonseq/Seq assert Time        : 12 or prev_command\n";
    exit 0;
}#sub usage
