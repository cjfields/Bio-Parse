use Test::Most;
use Bio::Parse;
use File::Spec;

my $parser = Bio::Parse->new(format    => 'genbank',
                             file      => test_data('genbank','') );


sub test_data {
    File::Spec->catfile('t','data',@_);
}
