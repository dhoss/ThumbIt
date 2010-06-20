#!/usr/bin/env perl
use Thumbit::Job::Parallel;
use FindBin qw/$Bin/;

my $app = Thumbit::Job::Parallel->new(config => $Bin. '/../thumbit.conf');
POE::Kernel->run();
