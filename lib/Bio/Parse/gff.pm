package Bio::Parse::gff;

use 5.010;
use strict;
use warnings;
use Any::URI::Escape;
use base 'Bio::Parse';

# cached values
my $PREFIX; # to make bioperl-like args for instances, make this '-'
my $ATTRIBUTE_SPLIT; # GFF3 = "\t", GFF2 = ' ' TODO: needs validation per type

# TODO : implement URI encode/decode (switch to URI::Encode)
#my $URI_ENCODE = ';=%&,\t\n\r\x00-\x1f';

my $GFF_SPLIT;   # TODO : allow spaces instead of tabs? seems dangerous...

# TODO : implement GTF/GFF2-specific att parsing
my $ATTRIBUTE_CONVERT = \&uri_unescape;
my @GFF_COLUMNS;

sub _initialize {
    my ($self, %args) = @_;
    # cache locally for speed
    $self->SUPER::_initialize(%args);
    $PREFIX = $self->prefix;
    # features
    @GFF_COLUMNS = map {"$PREFIX$_"} qw(seq_id source primary_tag start end
                       score strand phase);
    $ATTRIBUTE_SPLIT = exists $args{attribute_split} ?
        qr/$args{attribute_split}/o :
        qr/=/o;
    $self->fh();
}

sub next_dataset {
    my $self = shift;
    my $fh = $self->{fh};
    my $dataset;
    my $len = 0;
    GFFLINE:
    while (my $line = <$fh>) {
        $len += CORE::length($line);
        chomp $line;
        given ($line) {
            when (/(?:\t[^\t]+){8}/)  {
                $self->{mode} = $dataset->{MODE} = 'FEATURE';
                my (%feat, %tags, $attstr);
                # validate here?
                (@feat{@GFF_COLUMNS}, $attstr) =
                    map {$_ ne '.' ? $_ : undef } split("\t",$line);

                for my $kv (split(/\s*;\s*/, $attstr)) {
                    my ($key, $rest) = split($ATTRIBUTE_SPLIT, $kv, 2);
                    $self->throw("Attributes not split correctly:\n$kv\n".
                                 "make sure attribute_split is set correctly ".
                                 "(currently $ATTRIBUTE_SPLIT)") if !defined($rest);
                    my @vals = map { $ATTRIBUTE_CONVERT->($_) } split(',',$rest);
                    $tags{$key} = \@vals;
                }
                $feat{"${PREFIX}tag"} = \%tags;
                $dataset->{META} = \%feat;
            }
            when (/^(\#{1,2})\s*(\S+)\s*([^\n]+)?$/) { # comments and directives
                if (length($1) == 1) {
                    # per GFF3 spec, this is a generic comment that can be
                    # ignored, nothing to use; higher-level parsers could
                    # probably do something with this, though so we pass it on
                    @{$dataset}{qw(MODE DATA META)} = ('COMMENT', $line, {comment => $line});
                } else {
                    $self->{mode} = 'DIRECTIVE';
                    @{$dataset}{qw(MODE META)} =
                        ('DIRECTIVE', $self->directive($2, $3));
                }
                $self->new_dataset($dataset);
            }
            when (/^>(.*)$/) {          # sequence
                chomp $line;
                @{$dataset}{qw(MODE DATA META)} =
                    ('SEQUENCE', $line, {'sequence-header' =>  $1});
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
    given ($directive) {
        when ('sequence-region') {
            @data{qw(type id start end)} =
                ('sequence-region', split(/\s+/, $rest));
        }
        when ('genome-build') {
            @data{qw(type source buildname)} = ($directive, split(/\s+/, $rest));
        }
        when ('#') {
            $data{type} = 'resolve-references';
        }
        when ('FASTA') {
            $data{type} = 'sequence';
        }
        default {
            @data{qw(type data)} = ($directive, $rest);
        }
    }
    \%data;
}

#sub gff3_convert {
#    my $val = $_[0];
#    $val =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ego;
#    $val;
#}

#sub gff2_parse_attributes {
#    my ( $attr_string ) = @_;
#
#    return {} if !defined $attr_string || $attr_string eq '.';
#
#    chomp $attr_string;
#
#    my %attrs;
#    for my $a ( split /;/, $attr_string ) {
#        next unless $a;
#        my ( $name, $values ) = split /\s/, $a, 2;
#        next unless defined $values;
#        # not unescaping here!
#        push @{$attrs{$name}}, split /,/, $values;
#    }
#    return \%attrs;
#}

1;

__END__

MODES = FEATURE, SEQUENCE, COMMENT, DIRECTIVE
