use Test::Most tests => 11;
use Bio::Parse::DataSet;

my $ds = {
    'LENGTH' => 380,
    'START' => 31999,
    'META' => {
        'STRAND' => '+',
        'TAG' => {
            'ID' => [
                      'XM_625257.3'
                    ],
            'insd_transcript_id' => [
                                      'XM_625257.3'
                                    ],
            'note' => [
                        'Derived by automated computational analysis using gene prediction method: GNOMON. Supporting evidence includes similarity to: 224 ESTs'
                      ],
            'Parent' => [
                          'Group1:LOC551646'
                        ],
            'gbkey' => [
                         'mRNA'
                       ],
            'db_xref' => [
                           'GI:328776014',
                           'GeneID:551646',
                           'BEEBASE:GB10320'
                         ],
            'exon_number' => [
                               '5'
                             ],
            'product' => [
                           'hypothetical protein LOC551646'
                         ]
                 },
        'SCORE' => undef,
        'END' => '342784',
        'START' => '342466',
        'SEQ_ID' => 'Group1',
        'PRIMARY_TAG' => 'exon',
        'PHASE' => undef,
        'SOURCE' => 'RefSeq'
    },
  'DATA' => 'Group1	RefSeq	exon	342466	342784	.	+	.	ID=XM_625257.3;Parent=Group1:LOC551646;gbkey=mRNA;product=hypothetical protein LOC551646;note=Derived by automated computational analysis using gene prediction method: GNOMON. Supporting evidence includes similarity to: 224 ESTs;insd_transcript_id=XM_625257.3;db_xref=GI:328776014;db_xref=GeneID:551646;db_xref=BEEBASE:GB10320;exon_number=5',
  'MODE' => 'FEATURE'
};

ok(my $instance = Bio::Parse::Dataset->new($ds));

my @names = sort($instance->meta_names);

is(@names, 9);
is($names[0], 'END');
is($instance->meta('START'), 342466);

@names = sort($instance->tag_names);
is(@names, 8);
my @dbx = sort($instance->tags('db_xref'));
is(@dbx, 3);
is($dbx[0], 'BEEBASE:GB10320');
is($instance->tag('exon_number'), 5);
like($instance->data, qr/(?:\S+\t){8}/);

is($ds->start, 31999);
is($ds->length, 380);
