#!/usr/bin/env perl
use Thumbit;

my $app = Thumbit->new_with_config(configfile => 'thumbit.conf');
POE::Kernel->run();
