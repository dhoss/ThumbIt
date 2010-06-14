package Thumbit::Job;

use POE;
use Moose;
use namespace::autoclean;
with 'POEx::WorkerPool::Role::Job';

sub init_job {
    my $self = shift;

    $self->enqueue_step(
        [
            sub { # do stuff 
            },
            [qw/ #args
             /
            ]
        ]
}

1;
