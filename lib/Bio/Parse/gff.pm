package Bio::Parse::gff;

use 5.010;
use strict;
use warnings;
use base 'Bio::Parse';

use Bio::GFF3::LowLevel ();

sub _initialize {
    # noop for now
}

sub next_dataset {
    my $self = shift;
    $self->confess("ima parsing GFF3.  mamma mia");
    my $fh = $self->fh;
    while (<$fh>) {
        my $data;
        when (/\t/) {
            $data = Bio::GFF3::LowLevel::gff3_parse_feature($_);
        }
        when (/^\#/) {

        }
        default {}
    }
}

sub gff2_parse_attributes {
    my ( $attr_string ) = @_;

    return {} if !defined $attr_string || $attr_string eq '.';

    chomp $attr_string;

    my %attrs;
    for my $a ( split /;/, $attr_string ) {
        next unless $a;
        my ( $name, $values ) = split /\s/, $a, 2;
        next unless defined $values;
        # not unescaping here!
        push @{$attrs{$name}}, split /,/, $values;
    }
    return \%attrs;
}

1;
