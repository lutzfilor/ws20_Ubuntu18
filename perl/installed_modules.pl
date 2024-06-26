#!/usr/bin/perl -w
#
###############################################################################
#
#   Author      Lutz Filor
#               408 807 6915
#
#   Synopsis    Testing Libraries
#               When coming to a new system, environment 
#               test what you expect,
#               test what you are used to
#               and find out where your loopholes are.
#
#   With corporate networks, controlled and you have no priviliges and you can't
#   download or install public domain software, this is a quick way to get on solid
#   footing.
#
#==============================================================================
my $list = [ qw(    strict warnings Error
                    Tk Tk::Dialog Tk::FileSelect Tk::HyperText
                    Browser::Open
                    Path::Tiny
                    Perl::Tidy
                    Test::Cmd Test::Cmd::Common
                    Test::More Test::Deep Test::Warn Test::Simple Test::Differences Test::LongString
                    Test::NoWarnings Test::Exception Test::Expect Test::Between Test::Class Test::Pod Test::Pod::Coverage
                    Test::Signature Test::Distribution Test::Kwalitee Test::Output Test::Output::Tie
                    Test::MockModule Test::MockObject Test::MockObject::Extends
                    Test::Harness Test::Harness::Assert Test::Harness::Straps Test::Harness::Iterator
                    Test::Builder Test::Builder::Tester Test::Builder::Tester::Color
                    Test::DatabaseRow Test::DatabaseRow::dbh Test::WWW::Mechanize Test::HTML::Tidy
                    Test::HTML::Lint
                    File::Copy
                    File::Path File::Spec::Functions
                    Module::Build Module::Build::TestReporter Module::Starter ExtUtils::MakeMaker Devel::Cover 
                    Data::Dumper Queue Queue::Word Fatal
                    Net::SSH::Perl Net::SMPT SVN::Client Email::Send Email::Send::SMPT MD5::Solve 
                    DBI URI LWP::Simple HTML::TokeParser::Simple HTTP::Recorder HTTP::Proxy
                    InsertWrapper IO::Scalar Imager IPC::Run
                    Class::DBI::Loader Class::DBI::Loader::Relationship 
                    Apache::File Apache::Test Apache::Constants Apache::TestUtil Apache::TestRequest 
                    Apache::TestRun Apache::TestMM Inline::C 
                    Spreadsheet::ParseXLSX Spreadsheet::ParseExcel Excel::Writer::XLSX Excel::CloneXLSX::Form
                    Spreadsheet::ParseXLSX::Decryptor

                    )];
my $resp = [];

foreach my $module (@{$list}) {                                                         # List of important modules   
    #my $r = `perldoc -lm "$module"`;                                                   # verbose output to the terminal
    my $r = `perldoc -lm "$module" 2> /dev/null`;                                       # silent  output no terminal output
    chomp $r;
    push( @{$resp}, $r );                                                               # capture system call response
}# for all modules


my $u = maxwidth($list);                                                                # format parameter
my $v = maxwidth($resp);                                                                # format parameter
printf "%*s%s\n",5,'',"=" x (7+$u+$v);
printf "%*s| %-*s | %*s |\n",5,'', $u,"ModuleName",$v,"Module Path";
printf "%*s%s\n",5,'',"=" x (7+$u+$v);
foreach my $id (0..$#{$list}){                                                          # unformated response
    my $n = ${$list}[$id];
    my $r = ${$resp}[$id];
    printf "%*s| %-*s | %*s |\n",5,'',$u,$n,$v,$r;
}# all results
printf "%*s%s\n",5,'',"=" x (7+$u+$v);
foreach my $id (0..$#{$list}){                                                          # unformated response
    my $n = ${$list}[$id];
    my $r = ${$resp}[$id];
    printf "%*s| %-*s | %*s |\n",5,'',$u,$n,$v,$r if ( $r ne "" );
}# all results
printf "%*s%s\n",5,'',"=" x (7+$u+$v);
printf "%*s%s\n\n",5,'','... perl module testing done';
#==============================================================================

sub     maxwidth    {
        my  (   $array_r    )   =   @_;
        my  $max    =   0;
        foreach my $entry  ( @{$array_r} ) {
            my $tmp =   length($entry);
            $max = ( $max > $tmp ) ? $max : $tmp;
        }#for all
        return $max;
}#sub   maxwidth

# End of Program
