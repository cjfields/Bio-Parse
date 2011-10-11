use 5.010;
use Test::Most;
use Bio::Parse;
use File::Spec;
use Data::Dumper;

my %test_data = (
    'AB077698.gb'         => {
        ANNOTATION      => 22,
        FEATURE         => 11,
        SEQUENCE        => 46,
        RECORD_END      => 1,
        },
    'AF165282.gb'         => {
        ANNOTATION      => 20,
        FEATURE         => 5,
        SEQUENCE        => 4,
        RECORD_END      => 1,
        },
    'AF305198.gb'         => {
        ANNOTATION      => 17,
        FEATURE         => 3,
        SEQUENCE        => 30,
        RECORD_END      => 1,
        },
    'BAB68554.gb'         => {
        ANNOTATION      => 19,
        FEATURE         => 3,
        SEQUENCE        => 3,
        RECORD_END      => 1,
        },
    'BC000007.gb'         => {
        ANNOTATION      => 21,
        FEATURE         => 6,
        SEQUENCE        => 17,
        RECORD_END      => 1,
        },
    'BK000016-tpa.gb'     => {
        ANNOTATION      => 21,
        FEATURE         => 2,
        SEQUENCE        => 20,
        RECORD_END      => 1,
        },
    'D10483.gb'           => {
        ANNOTATION      => 333,  # TODO: check!
        FEATURE         => 188,  # TODO: check!
        SEQUENCE        => 1857,
        RECORD_END      => 1,
    },
    'D12555.gb'           => {
        ANNOTATION      => 17,
        FEATURE         => 4,
        SEQUENCE        => 2,
        RECORD_END      => 1,
    },
    'DQ018368.gb'         => {
        ANNOTATION      => 17,
        FEATURE         => 4,
        SEQUENCE        => 9,
        RECORD_END      => 1,
    },
    'Mcjanrna_rdbII.gb'   => {  # RDP example
        ANNOTATION      => 9,
        FEATURE         => 0,
        SEQUENCE        => 25,
        RECORD_END      => 1,
    },
    'NC_006346.gb'        => {
        ANNOTATION      => 24,
        FEATURE         => 4,
        SEQUENCE        => 8,
        RECORD_END      => 1,
    },
    'NC_006511-short.gb'  => {
        ANNOTATION      => 24,
        FEATURE         => 5,
        SEQUENCE        => 14,
        RECORD_END      => 1,
    },
    'NC_008536.gb'        => {
        ANNOTATION      => 25,
        FEATURE         => 7,
        SEQUENCE        => 34,
        RECORD_END      => 1,
    },
    'NT_021877.gb'        => {  # bad output example, may not be supported
        ANNOTATION      => 14,
        FEATURE         => 5,
        SEQUENCE        => 167,
        RECORD_END      => 1,
    },
    'O_sat.gb'            => { # WGS example
        ANNOTATION      => 25,
        FEATURE         => 1,
        SEQUENCE        => 0,
        RECORD_END      => 1,
    },
    'P39765.gb'           => {  # GenPept
        ANNOTATION      => 64,
        FEATURE         => 34,
        SEQUENCE        => 4,
        RECORD_END      => 1,
    },
    'U71225.gb'           => {
        ANNOTATION      => 17,
        FEATURE         => 4,
        SEQUENCE        => 20,
        RECORD_END      => 1,
    },
    'bug2982.gb'          => {
        ANNOTATION      => 14,
        FEATURE         => 5,
        SEQUENCE        => 0,
        RECORD_END      => 1,
    },
    'mini-AE001405.gb'    => {
        ANNOTATION      => 24,
        FEATURE         => 4,
        SEQUENCE        => 3,
        RECORD_END      => 1,
    },

    # TODO: Ensembl output, prob. should be updated to more recent example
    'revcomp_mrna.gb'     => {
        ANNOTATION      => 13,
        FEATURE         => 159,
        SEQUENCE        => 834,
        RECORD_END      => 1,
    },
    'roa1.gb'             => {  # two records
        ANNOTATION      => 35,
        FEATURE         => 4,
        SEQUENCE        => 4,
        RECORD_END      => 2,
    },
    'test.gb'             => { # five records
        ANNOTATION      => 90,  # TODO: check!
        FEATURE         => 39,   # TODO: check!
        SEQUENCE        => 81,   # TODO: check!
        RECORD_END      => 5,
    },
    'test.genbank.gb'     => { # five records, no seq, last with no end marker
        ANNOTATION      => 86,
        FEATURE         => 39,
        SEQUENCE        => 0,
        RECORD_END      => 4,
    },
    'testfuzzy.gb'        => { # bad formatting example, may not be supported
        ANNOTATION      => 22,
        FEATURE         => 21,
        SEQUENCE        => 6,
        RECORD_END      => 1,
    },
);

for my $file (sort keys %test_data) {
    my $expected = $test_data{$file};
    my $parser = Bio::Parse->new(format    => 'genbank',
                                 file      => cat_file('genbank', $file) );
    my %data;
    my $ct = 0;
    while (my $ds = $parser->next_hr) {
        push @{$data{$ds->{MODE}}}, $ds;
    }
    for my $type (sort keys %$expected) {
        next if $type eq 'SAMPLE';
        is(@{$data{$type}}, $expected->{$type}, "$file $type");
        # TODO: need deeper testing of data here

    }
}

done_testing();

sub cat_file {
    File::Spec->catfile('t','data', @_);
}
