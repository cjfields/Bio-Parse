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

my %COLUMNS = (
    'gap' => [
        qw( id start end part_number component_type gap_length   gap_type
        linkage linkage_evidence
        )],
    'seq'   => [
        qw( id start end part_number component_type component_id component_start
        component_end strand)
    ]
);

sub _initialize {
    my $self = shift;
    $self->{csv} = Text::CSV->new({sep_char => "\t"});
    $self->{csv}->bind_columns(\@{$self->{cache}}[0..8]);
    1;
}

sub next_hr {
    my $self = shift;
    my $fh = $self->fh;
    PARSER:
    while (<$fh>) {
        $self->{csv}->parse($_);
        if ($self->{cache}->[0] =~ /^\#+\s*([^\n]*)/) {
            return _agp_annotation({
                MODE    => 'ANNOTATION',
                DATA    => $1,
            });
        }
        my $meta;
        if ($self->{cache}->[4] eq 'N' || $self->{cache}->[4] eq 'U') {
            @{$meta}{@{$COLUMNS{gap}}} = @{$self->{cache}};
        } else {
            @{$meta}{@{$COLUMNS{seq}}} = @{$self->{cache}};
        }
        return {
            MODE    => 'FEATURE',
            DATA    => $_,
            META    => $meta
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
