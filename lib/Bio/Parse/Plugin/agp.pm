package Bio::Parse::Plugin::agp;

use 5.010;
use strict;
use warnings;
use base 'Bio::Parse';
use Text::CSV;
use Data::Dumper;

my %MODE_MAP = (
    'FEATURE'       => \&_agp_feature,
    'ANNOTATION'    => \&_agp_comment,
);

my @COLUMNS = qw(object
    object_beg
    object_end
    part_number
    component_type
    component_id
    component_type/gap_length
    component_beg/gap_type
    component_end/linkage
    orientation/linkage_evidence);

sub next_hr {
    my $self = shift;
    my $fh = $self->fh;
    PARSER:
    while (<$fh>) {
        my $data;
        if (/^\#+\s*([^\n]+)/) {
            $data = {
                MODE    => 'ANNOTATION',
                DATA    => $1,
            };
        } else {
            chomp;
            my %meta;
            @meta{@COLUMNS} = split(/\t/);
            $data = {
                MODE    => 'FEATURE',
                DATA    => $_,
                META    => \%meta
            };
        }
        $self->_new_dataset($data);
    }
    if ($self->_num_datasets()) {
        return $self->_pop_dataset();
    }
    return;
}

1;

__END__
