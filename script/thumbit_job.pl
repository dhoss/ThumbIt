#!/usr/bin/env perl
use Thumbit::NeedsParallel;
use FindBin qw/$Bin/;

my $app = Thumbit::NeedsParallel->new(config => $Bin. '/../thumbit.conf');
POE::Kernel->run();
