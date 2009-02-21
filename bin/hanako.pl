#!/usr/bin/perl -w

use 5.010000;
use strict;
use warnings;
use lib './lib';
use WWW::Hanako;
use Carp;
use Getopt::Std;
use Data::Dumper;

my %opt;
getopts('td', \%opt);

my $area = shift || 3;
my $mst = shift || 51300200;
my $today=$opt{t} || 0;
my $debug=$opt{d} || 0;

my $hanako = WWW::Hanako->new(area=>$area, mst=>$mst, debug=>$debug);

if($today){
    my @list = $hanako->today();
    for(@list){
        print "$_->{hour} $_->{pollen}\n";
    }
}else{
    my $now = $hanako->now();
    print "$now->{hour} $now->{pollen}\n";
}
