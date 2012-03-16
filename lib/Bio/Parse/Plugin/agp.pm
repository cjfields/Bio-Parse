package Bio::Parse::Plugin::agp;

use 5.010;
use strict;
use warnings;
use base 'Bio::Parse';
use Text::CSV;
use Data::Dumper;

my %MODE_MAP = (
    'FEATURE'       => \&_agp_feature,
    'ANNOTATION'    => \&_agp_annotation,
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

sub _initialize {
    my $self = shift;
    $self->{csv} = Text::CSV->new({sep_char => "\t"});
    $self->{csv}->bind_columns(\@{$self->{cache}}{@COLUMNS});
    1;
}

sub next_hr {
    my $self = shift;
    my $fh = $self->fh;
    PARSER:
    while (<$fh>) {
        $self->{csv}->parse($_);
        if ($self->{cache}->{object} =~ /^\#+\s*([^\n]+)/) {
            return _agp_annotation({
                MODE    => 'ANNOTATION',
                DATA    => $1,
            });
        } else {
            return _agp_feature({
                MODE    => 'FEATURE',
                DATA    => $_,
                META    => $self->{cache}
            });
        }
    }
    return;
}

# transformers
sub _agp_annotation {
    my $data = shift;
    if ($data->{DATA} =~ /^([A-Z\s]+):\s*(.*)/) {
        $data->{META} = {
            NAME        => $1,
            VALUE       => $2
        };
    }
    $data;
}

sub _agp_feature {
    my $data = shift;
    $data;
}

1;

__END__
