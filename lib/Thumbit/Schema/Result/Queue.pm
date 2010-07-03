package Thumbit::Schema::Result::Queue;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ Timestamp /);
__PACKAGE__->table('queue_items');

__PACKAGE__->add_columns(

    'queueid',
    {
        data_type => 'int',
        is_auto_increment => 1,
    },

    'created',
    {
        data_type => 'datetime',
        set_on_create => 1,
    },

    'updated',
    {
        data_type => 'datetime',
        set_on_update => 1,
    },

    'finished',
    {
        data_type => 'datetime',
    },

    'image_path',
    {
        data_type => 'varchar',
        size => '255',
    },

    'status',
    {
        data_type => 'varchar',
        size => 255,
    }
);

__PACKAGE__->set_primary_key('queueid');

1;
