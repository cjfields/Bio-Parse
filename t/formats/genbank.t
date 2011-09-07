use 5.010;
use Test::Most;
use Bio::Parse;
use File::Spec;

my $parser = Bio::Parse->new(format    => 'genbank',
                             file      => test_data('genbank','AB077698.gb') );

while (my $ds = $parser->_next_dataset) {
    diag($ds);
}

sub test_data {
    File::Spec->catfile('t','data',@_);
}


