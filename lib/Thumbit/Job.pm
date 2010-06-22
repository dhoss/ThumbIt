
use MooseX::Declare;
use POE;
use Imager;
use File::Find::Rule;

class Thumbit::Job with POEx::WorkerPool::Role::Job {
    
    with 'MooseX::SimpleConfig';

    has 'imager' => (
        is         => 'ro',
        required   => 1,
        lazy_build => 1,
    );

    method _build_imager { return Imager->new; }

    has 'scalefactor' => (
        is       => 'ro',
        required => 1,
    );

    has 'writedir' => (
        is       => 'ro',
        required => 1,
    );

     has 'thumb_queue_dir' => (
        is       => 'ro',
        required => 1,
     );

     has 'image_queue' => (
        is         => 'ro',
        required   => 1,
        lazy_build => 1,
     );

     method _build_image_queue {
         my $dir = $self->thumb_queue_dir;
         my @files =
           File::Find::Rule->file()->name(qr/\.(png|jpg|tiff|gif)$/)
           ->in( $self->thumb_queue_dir );
         return @files;
     }

     method init_job {
         my @queue = $self->image_queue;

         $self->enqueue_step(
             [
                 sub {
                     $self->make_thumbs;
                 },
                 \@queue
             ]
         );
     }

     method make_thumbs {
         my $fh = shift;

         my $image = $self->imager;

         my $scaled;
        
         ## attempt to read in the image
         for my $img_fh ( @{$fh} ) {
             if ( $image->read( fh => $img_fh ) ) {
                 $scaled = $image->scale( scalefactor => $self->scalefactor );
                 
                 ## write our image to disk
                 binmode STDOUT;
                 $| = 1;
                 warn "Writing thumb out\n";
                 $scaled->write( file => $self->writedir )
                   or die $image->errstr;
             }
          }

    }

}
