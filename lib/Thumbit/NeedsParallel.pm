use MooseX::Declare;
use Thumbit::Job;
use Try::Tiny;
class  Thumbit::NeedsParallel {

    with 'POEx::Role::SessionInstantiation';
    use aliased 'POEx::Role::Event';

    use POEx::Types(':all');
    use POEx::WorkerPool::Types(':all');
    use POEx::WorkerPool::WorkerEvents(':all');
    
    use POEx::WorkerPool;
    use Data::Dumper;

    has config => ( is => 'ro', required => 1, lazy => 1, default => sub { die "Config file required" } );
    has pool => ( is => 'ro', isa => DoesWorkerPool, lazy_build => 1 );
    
    method _build_pool { POEx::WorkerPool->new }

    after _start is Event {
        for (0..4) {
            warn "Spooling up";
            my $alias => $self->run_job;
            warn "after alias";
            $self->poe->kernel->delay_set(
               'run_job',
               5
            );
            warn "after delay_set";
            $self->post(
                $alias, 'subscribe',
                event_name => +PXWP_JOB_COMPLETE,
                event_handler => 'job_complete',
            );
        }
        warn "after post";
    }

    method run_job is Event {
        my $alias;
        my $job = Thumbit::Job->new_with_config(configfile => $self->config);
        $alias = $self->pool->enqueue_job($job) or die "Can't enqueue job";;
        print "Job enqueued\n";
        return $alias;
    }

    method job_complete (SessionID :$worker_id, Str :$job_id, Ref :$msg) is Event {
    
        print "Worker $worker_id finished job $job_id\n";

    }
}
