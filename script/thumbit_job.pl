#!/usr/bin/env perl
use Thumbit::Job::Parallel;

my $app = Thumbit::Job::Parallel->new_with_config(configfile => 'thumbit.conf');
POE::Kernel->run();
