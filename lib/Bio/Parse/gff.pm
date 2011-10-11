package Bio::Parse::gff;

use 5.010;
use strict;
use warnings;
use base 'Bio::Parse';

use Bio::Parse::DataSet;
use Any::URI::Escape;

my %META_MAP = (
    'primary_tag'   => '-primary_tag',
    'seq_id'        => '-seq_id',
    'source'        => '-source',
    'start'         => '-start',
    'end'           => '-end',
    'score'         => '-score',
    'strand'        => '-strand',
    'phase'         => '-phase',
    'tags'          => '-tags'
);

my $ATTRIBUTE_SPLIT; # GFF3 = "\t", GFF2 = ' ' TODO: needs validation per type

my $GFF_SPLIT;   # TODO : allow spaces instead of tabs? seems dangerous...

# TODO : implement GTF/GFF2-specific att parsing
my $ATTRIBUTE_CONVERT = \&uri_unescape;
my @GFF_COLUMNS;


# TODO: genericize?  Push what we can to Bio::Parse (base)
sub _initialize {
    my ($self, %args) = @_;
    # cache locally for speed
    $self->SUPER::_initialize(%args);
    # features
    @GFF_COLUMNS = qw(SEQ_ID SOURCE PRIMARY_TAG START END SCORE STRAND PHASE);
    $ATTRIBUTE_SPLIT = exists $args{attribute_split} ?
        qr/$args{attribute_split}/o :
        qr/=/o;
    $self->fh();
    #$self->{meta_map} = \%META_MAP;
}

sub next_hr {
    my $self = shift;
    my $fh = $self->fh;
    #my $meta_map = $self->meta_map;
    my $dataset;
    my $len = 0;

    # TODO: this parser doesn't use the Bio::Parse helper methods for building
    # data structures b/c each line is a single item of information. This may
    # change for consistency, but have to see what the perf. hit is
    GFFLINE:
    while (my $line = <$fh>) {
        $len += CORE::length($line);
        chomp $line;
        given ($line) {
            # TODO: note this regex hard-codes "\t"
            when (/(?:\t[^\t]+){8}/)  {
                $self->{mode} = $dataset->{MODE} = 'FEATURE';
                my (%feat, %tags, $attstr);

                # TODO: hard-coded "\t"
                #(@feat{@{$meta_map}{@GFF_COLUMNS}}, $attstr) =
                (@feat{@GFF_COLUMNS}, $attstr) =
                    map {$_ ne '.' ? $_ : undef } split("\t",$line);

                for my $kv (split(/\s*;\s*/, $attstr)) {
                    my ($key, $rest) = split($ATTRIBUTE_SPLIT, $kv, 2);
                    # TODO: not sure this check is valid, commenting out
                    #$self->throw("Attributes not split correctly:\n$kv\n".
                    #             "make sure attribute_split is set correctly ".
                    #             "(currently $ATTRIBUTE_SPLIT)") if !defined($rest);
                    my @vals = map { $ATTRIBUTE_CONVERT->($_) } split(',',$rest);
                    push @{$tags{$key}},@vals;
                }
                #$feat{$meta_map->{TAG}} = \%tags;
                $feat{TAG} = \%tags;
                $dataset->{META} = \%feat;
            }
            when (/^(\#{1,2})\s*(\S+)\s*([^\n]+)?$/) { # comments and directives
                if (length($1) == 1) {
                    # per GFF3 spec, this is a generic comment that can be
                    # ignored, nothing to use; higher-level parsers could
                    # probably do something with this, though so we pass it on
                    @{$dataset}{qw(MODE DATA META)} = ('COMMENT', $line, {COMMENT => $line});
                } else {
                    $self->{mode} = 'DIRECTIVE';
                    @{$dataset}{qw(MODE META)} =
                        ('DIRECTIVE', $self->directive($2, $3));
                }
            }
            when (/^>(.*)$/) {          # sequence
                chomp $line;
                @{$dataset}{qw(MODE DATA META)} =
                    ('SEQUENCE', $line, {'FASTA-HEADER' =>  $1});
            }
            default {
                if ($self->current_mode eq 'SEQUENCE') {
                    chomp $line;
                    @{$dataset}{qw(MODE DATA)} =
                        ('SEQUENCE', $line);
                } else {
                    # anything else should be sequence, but there should be some
                    # kind of directive to change the mode or a typical FASTA
                    # header should be found; if not, die
                    $self->throw("Unknown line: $line, parser was in mode ".
                                 $self->current_mode);
                }
            }
        }
        if ($dataset) {
            @$dataset{qw(DATA START LENGTH)} = ($line, $self->{stream_start}, $len);
            $self->{stream_start} += $len;
            return $dataset;
        }
        return;
    }
}

sub directive {
    my ($self, $directive, $rest) = @_;
    $rest ||= '';
    my %data;
    # TODO: allow mapping
    given ($directive) {
        when ('sequence-region') {
            @data{qw(directive id start end)} =
                ('sequence-region', split(/\s+/, $rest));
        }
        when ('genome-build') {
            @data{qw(directive source buildname)} = ($directive, split(/\s+/, $rest));
        }
        when ('#') {
            $data{directive} = 'resolve-references';
        }
        when ('FASTA') {
            $data{directive} = 'sequence';
        }
        default {
            @data{qw(directive data)} = ($directive, $rest);
        }
    }
    \%data;
}

1;

__END__

MODES = FEATURE, SEQUENCE, COMMENT, DIRECTIVE
