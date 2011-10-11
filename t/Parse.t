use Test::Most tests => 14;
use Bio::Parse;

my $parser;

# check basic exceptions
throws_ok {$parser = Bio::Parse->new()}
    qr/'fh' parameter not provided/, 'fails with no fh, format';

throws_ok {$parser = Bio::Parse->new(format => 'gff')}
    qr/'fh' parameter not provided/, 'fails with no fh';

throws_ok {$parser = Bio::Parse->new(format => 'gff',
                                       fh     => 'foo')}
    qr/'fh' parameter not provided/, 'fails with bad fh';

my $str = 'foobarbaz';

# test using fh based on string
open(my $fh, '<', \$str) || die $!;

lives_ok {$parser = Bio::Parse->new(format => 'gff',
                                    fh     => $fh)};

isa_ok($parser, 'Bio::Parse');
isa_ok($parser, 'Bio::Parse::gff');
is($parser->format, 'gff');
is($parser->variant, undef);

lives_ok {$parser = Bio::Parse->new(format => 'gff-v3',
                                    fh     => $fh)};
isa_ok($parser, 'Bio::Parse::gff');
is($parser->format, 'gff');
is($parser->variant, 'v3');

close $fh;

{
    sub Bio::Parse::gff::foo {
        my $self = shift;
        $self->method_not_implemented;
    }
    lives_ok {$parser = Bio::Parse->new(format => 'gff',
                                    fh     => $fh)};

    is($parser->foo, 'Bio::Parse::gff::foo is not implemented by Bio::Parse::gff');
}

unlink 'test.foo';

1;
