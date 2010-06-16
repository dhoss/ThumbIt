#!/usr/bin/env perl
use Thumbit::Job::Parallel;

my $app = Thumbit::Job::Parallel->new(config => 'thumbit.conf');
POE::Kernel->run();
