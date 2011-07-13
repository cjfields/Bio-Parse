package Bio::Parse::gff;

use 5.010;
use strict;
use warnings;
use base 'Bio::Parse';

my $PREFIX;
my $URI_ENCODE = ';=%&,\t\n\r\x00-\x1f';
#my $GFF_SPLIT = "\t";
my $ATTRIBUTE_SPLIT = '=';
my $ATTRIBUTE_CONVERT = \&gff3_convert;
my @GFF_COLUMNS;

sub _initialize {
    my ($self, @args) = @_;
    # cache locally for speed
    $self->SUPER::_initialize(@args);
    $PREFIX = $self->prefix;
    # features
    @GFF_COLUMNS = map {"$PREFIX$_"} qw(seq_id source primary_tag start end
                       score strand phase);
}

sub next_dataset {
    my $self = shift;
    my $fh = $self->{fh};
    my $dataset;
    my $len = 0;
    GFFLINE:
    while (my $line = <$fh>) {
        $len += CORE::length($line);
        given ($line) {
            when (/(?:\t[^\t]+){8}/)  {
                chomp $line;
                $self->{mode} = $dataset->{MODE} = 'feature';
                my (%feat, %tags, $attstr);
                # validate here?
                (@feat{@GFF_COLUMNS}, $attstr) =
                    map {$_ ne '.' ? $_ : undef } split("\t",$line);

                for my $kv (split(/\s*;\s*/, $attstr)) {
                    my ($key, $rest) = split("$ATTRIBUTE_SPLIT", $kv, 2);
                    $self->throw("Attributes not split correctly, $attstr; ".
                                 "make sure format is correct") if !defined($rest);
                    my @vals = map { $ATTRIBUTE_CONVERT->($_) } split(',',$rest);
                    $tags{$key} = \@vals;
                }
                $feat{"${PREFIX}tag"} = \%tags;
                $dataset->{DATA} = \%feat;
            }
            when (/^\s*$/) {  next GFFLINE  } # blank lines
            when (/^(\#{1,2})\s*(\S+)\s*([^\n]+)?$/) { # comments and directives
                if (length($1) == 1) {
                    chomp $line;
                    @{$dataset}{qw(MODE DATA)} = ('comment', {DATA => $line});
                } else {
                    $self->{mode} = 'directive';
                    @{$dataset}{qw(MODE DATA)} =
                        ('directive', $self->directive($2, $3));
                }
            }
            when (/^>/) {          # sequence
                chomp $line;
                @{$dataset}{qw(MODE DATA)} =
                    ('sequence', {'sequence-header' =>  $line});
                $self->{mode} = 'sequence';
            }
            default {
                if ($self->{mode} eq 'sequence') {
                    chomp $line;
                    @{$dataset}{qw(MODE DATA)} =
                        ('sequence', {sequence => $line});
                } else {
                    # anything else should be sequence, but there should be some
                    # kind of directive to change the mode or a typical FASTA
                    # header should be found; if not, die
                    $self->throw("Unknown line: $line, parser was in mode ".
                                 $self->{mode});
                }
            }
        }
        if ($dataset) {
            @$dataset{qw(START LENGTH)} = ($self->{stream_start}, $len);
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

sub gff3_convert {
    my $val = $_[0];
    $val =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ego;
    $val;
}

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


