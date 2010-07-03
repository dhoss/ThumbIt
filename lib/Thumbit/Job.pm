
use MooseX::Declare;
use MooseX::Method::Signatures;
use POE;
use Imager;
use File::Basename;
use Thumbit::Schema;
use DateTime;
use DateTime::Format::MySQL;

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

    has 'schema' => (
        is => 'ro',
        required => 1,
        lazy_build => 1,
    );
    
    has 'dsn' => (
        is => 'ro',
        required => 1,
    );

    has 'user' => (
        is => 'ro',
        required => 1,
    );

    has 'password' => (
        is => 'ro',
        required => 1,
    );

    method _build_schema {
        my $schema = Thumbit::Schema->connect( $self->dsn, $self->user, $self->password );
        return $schema;
    }

     method init_job {
         warn "enqueueing step\n";
         $self->enqueue_step(
             [
                 sub {
                     $self->make_thumbs;
                 },
                
             ]
         );
     }

     method poll_queue {
         my $schema = $self->schema;
         warn "polling queue";
         return $schema->resultset('Queue')->all;
     }

     method make_thumbs  {
         my $image = $self->imager;
         my $schema = $self->schema;
         my @image_paths = $self->poll_queue;
         my $scaled;
         warn "writing images\n";
         ## attempt to read in the image
         for my $img ( @image_paths ) {
             print "Image path: " . $img->image_path;
             if ( $image->read( file => $img->image_path ) ) {
                 $scaled = $image->scale( scalefactor => $self->scalefactor );
                 
                 ## write our image to disk
                 binmode STDOUT;
                 $| = 1;
                 warn "Writing thumb out\n";
                 warn "Write dir: " . $self->writedir;
                 $scaled->write( file => $self->writedir . (fileparse($img->image_path))[0] )
                   or die $scaled->errstr;
                 warn "Wrote ". $scaled;
                    
                 ## update queue
                 my $dt = DateTime->now;
                 DateTime::Format::MySQL->format_datetime($dt);
                 $img->update({ status => 'done', finished => $dt });
             }
          }

    }

}
