
use MooseX::Declare;
use MooseX::Method::Signatures;
use POE;
use Imager;
use File::Find::Rule;
use Thumbit::Schema;

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
         use Data::Dumper;
         my @queue = $self->image_queue;
         warn "enqueueing step\n";
         warn "queue: " . Dumper @queue;
         $self->enqueue_step(
             [
                 sub {
                     $self->make_thumbs;
                 },
             ]
         );
     }

     method make_thumbs  {
         use Data::Dumper;
         my $image = $self->imager;
         my $schema = $self->schema;
         my @image_paths = $schema->resultset('Queue')->all;
         my $scaled;
         warn "writing images\n";
         ## attempt to read in the image
         for my $img_path ( @image_paths ) {
             warn "Image path: $img_path";
             if ( $image->read( file => $img_path ) ) {
                 $scaled = $image->scale( scalefactor => $self->scalefactor );
                 
                 ## write our image to disk
                 binmode STDOUT;
                 $| = 1;
                 warn "Writing thumb out\n";
                 warn "Write dir: " . $self->writedir;
                 $scaled->write( file => $img_path )
                   or die $scaled->errstr;
                 warn "Wrote ". $scaled;
             }
          }

    }

}
