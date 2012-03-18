use 5.010;
use Test::Most;
use Bio::Parse;
use File::Spec;
use Data::Dumper;

my %test_data = (
    'chr_from_contig_BAC.v1.1.agp'  => {
        ANNOTATION      => 8,
        FEATURE         => 144,
    },
    'chr_from_contig_BAC.v2.0.agp'  => {
        ANNOTATION      => 9,
        FEATURE         => 144,
    },
    'chr_from_contig_WGS.v1.1.agp' => {
        ANNOTATION      => 6,
        FEATURE         => 189,
    },
    'chr_from_contig_WGS.v2.0.agp' => {
        ANNOTATION      => 7,
        FEATURE         => 191,
    },
    'chr_from_scaffold_WGS.v1.1.agp' => {
        ANNOTATION      => 8,
        FEATURE         => 45,
    },
    'chr_from_scaffold_WGS.v2.0.agp' => {
        ANNOTATION      => 9,
        FEATURE         => 47,
    },
    'scaffold_from_contig_WGS.v1.1.agp' => {
        ANNOTATION      => 6,
        FEATURE         => 167,
    },
    'scaffold_from_contig_WGS.v2.0.agp' => {
        ANNOTATION      => 7,
        FEATURE         => 167,
    },
);

for my $file (sort keys %test_data) {
    my $expected = $test_data{$file};
    my $parser = Bio::Parse->new(format    => 'agp',
                                 file      => cat_file('agp', $file) );
    my %data;
    my $ct = 0;
    while (my $ds = $parser->next_hr) {
        push @{$data{$ds->{MODE}}}, $ds;
    }
    for my $type (sort keys %$expected) {
        is(@{$data{$type}}, $expected->{$type}, "$file $type");
    }
}

done_testing();

sub cat_file {
    File::Spec->catfile('t','data', @_);
}
