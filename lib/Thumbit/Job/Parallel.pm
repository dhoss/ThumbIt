use MooseX::Declare;
use Thumbit::Job;

class  Thumbit::Job::Parallel {

    with 'POEx::Role::SessionInstantiation';
    use aliased 'POEx::Role::Event';

    use POEx::Types(':all');
    use POEx::WorkerPool::Types(':all');
    use POEx::WorkerPool::WorkerEvents(':all');
    
    use POEx::WorkerPool;
    use Path::Class qw/dir/;

    has config => ( is => 'ro', required => 1, lazy => 1, default => sub { die "Config file required" } );
    has pool => ( is => 'ro', isa => DoesWorkerPool, lazy_build => 1 );
    method  _build_pool { POEx::WorkerPool->new() }

    after _start is Event {
        for (0..4) {
            my $alias = $self->pool->enqueue_job(Thumbit::Job->new_with_config( configfile => $self->config ));
            $self->poe->kernel->delay_set('poll_queue', 5);

            $self->post(
                $alias, 'subscribe',
                event_name => +PXWP_JOB_COMPLETE,
                event_handler => 'job_complete',
            );
        }
    }

    method poll_queue is Event {
       # poll queue for new jobs
       my $queue = $self->get_queue;
       return $queue; 
    }

    method get_queue {
        my @files;
        my $dir = dir('root', 'queue');
        my $handle = $dir->open;
        
        while ( my $file = $handle->read ) {
            push @files, $dir->file($file);
        }

        return \@files;
    }

    method job_complete (SessionID :$worker_id, Str :$job_id, Ref :$msg) is Event {
    
        print "Worker $worker_id finished job $job_id\n";

    }
}
