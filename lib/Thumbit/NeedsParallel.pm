use MooseX::Declare;
use Thumbit::Job;

class  Thumbit::NeedsParallel {

    with 'POEx::Role::SessionInstantiation';
    use aliased 'POEx::Role::Event';

    use POEx::Types(':all');
    use POEx::WorkerPool::Types(':all');
    use POEx::WorkerPool::WorkerEvents(':all');
    
    use POEx::WorkerPool;
    use Path::Class qw/dir/;
    use MIME::Types qw/by_suffix/;
    use File::Basename;
    use Data::Dumper;

    has config => ( is => 'ro', required => 1, lazy => 1, default => sub { die "Config file required" } );
    has pool => ( is => 'ro', isa => DoesWorkerPool, lazy_build => 1 );
    has dir => ( is => 'ro', required => 1, lazy_build => 1 );
    has thumber => ( is => 'ro', required => 1, lazy_build => 1 );

    method _build_thumber { 
        warn "building thumber:\n";
        warn "poll queue: " . Dumper $self->poll_queue;
        return Thumbit::Job->new_with_config(
            configfile  => $self->config,
            image_queue => $self->poll_queue,
        ); 
    }
    method _build_dir { dir('root', 'queue') } # NEEDS CONFIGURABILITY
    method _build_pool { POEx::WorkerPool->new }

    after _start is Event {
        for (0..4) {
            warn "Enqueueing job: " . Dumper $self->thumber;
            my $alias = $self->pool->enqueue_job(
                Thumbit::Job->new()
            );
            $self->poe->kernel->delay_set('poll_and_create', 5);

            $self->post(
                $alias, 'subscribe',
                event_name => +PXWP_JOB_COMPLETE,
                event_handler => 'job_complete',
            );
        }
    }

    ## HERE WE NEED TO BUILD OUR JOB A LITTLE BETTER
    ## 1. read in images
    ## 2. process thumbnails
    ## 3. write thumbnails out to thumbnail dir
    ## 4. remove processed images from queue directory

    method poll_queue is Event {
        my @files;
        my $dir = $self->dir;
        my $handle = $dir->open;
        my $type;
        warn "Finding files\n";        
        while ( my $file = $handle->read ) {
            warn "dealing with file $file\n";
            $type = (by_suffix(basename($file)))[0];
            warn "$file is mime type $type\n";
            if ( $type =~ /^image.+$/ ) {
                warn "pushing file $file\n";
                push @files, $dir->file($file);
            }
        }

        return \@files;
    }

    method poll_and_create is Event {
        my $files = $self->poll_queue;
        my $thumb = $self->thumber;
        warn "making thumbs\n";
        warn "queue: " . Dumper $files;
        $thumb->make_thumbs($files);
    }


    method job_complete (SessionID :$worker_id, Str :$job_id, Ref :$msg) is Event {
    
        print "Worker $worker_id finished job $job_id\n";

    }
}
