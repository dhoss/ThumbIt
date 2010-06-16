package Thumbit::Job;


use Moose;
use POE;
use Imager;
use File::Find::Rule;
use namespace::autoclean;

with 'POEx::WorkerPool::Role::Job', 'MooseX::SimpleConfig';

has 'imager' => (
   is => 'ro',
   required => 1,
   lazy_build => 1,
);

sub _build_imager {
    my $self = shift;
    return Imager->new;
}

has 'scalefactor' => (
   is => 'ro',
   required => 1,
);

has 'writedir' => (
    is => 'ro',
    required => 1,
);

has 'thumb_queue_dir' => (
    is => 'ro',
    required => 1,
);

has 'image_queue' => (
    is => 'ro',
    required => 1,
    lazy_build => 1,
);

sub _build_image_queue {
    my $self = shift;
    my $dir = $self->thumb_queue_dir;
    my @files = File::Find::Rule->file()
                                ->name( qr/\.(png|jpg|tiff|gif)$/ )
                                ->in( $self->thumb_queue_dir );
    return @files;
}

sub init_job {
    my $self = shift;
    my @queue = $self->image_queue;

    $self->enqueue_step(
        [
            sub { 
                $self->make_thumbs
            },
            \@queue]
        ]
}

sub make_thumbs {
    my ($self, $fh) = @_;
    
    my $image = $self->imager;
   
    my $scaled;
    ## attempt to read in the image
    for my $img_fh ( @{ $fh } ) {
        if ( $image->read( fh => $img_fh ) {
            $scaled = $image->scale(  scalefactor => $self->scalefactor );

            ## write our image to disk
            binmode STDOUT;
            $| = 1;

            $scaled->write( file => $self->writedir )
                or die $image->errstr;
        }
    }

}

__PACKAGE__->meta->make_immutable;
1;
