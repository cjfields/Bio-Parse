use Test::Most tests => 11;
use Bio::Parse::DataSet;

my $ds = {
    'LENGTH' => 380,
    'START' => 31999,
    'META' => {
        'source' => 'RefSeq',
        'seq_id' => 'Group1',
        'score' => undef,
        'primary_tag' => 'exon',
        'end' => '342784',
        'phase' => undef,
        'strand' => '+',
        'tag' => {
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
        'start' => '342466'
              },
    'DATA' => 'Group1	RefSeq	exon	342466	342784	.	+	.	ID=XM_625257.3;Parent=Group1:LOC551646;gbkey=mRNA;product=hypothetical protein LOC551646;note=Derived by automated computational analysis using gene prediction method: GNOMON. Supporting evidence includes similarity to: 224 ESTs;insd_transcript_id=XM_625257.3;db_xref=GI:328776014;db_xref=GeneID:551646;db_xref=BEEBASE:GB10320;exon_number=5',
    'MODE' => 'FEATURE'
  };

ok(my $instance = Bio::Parse::Dataset->new($ds));

my @names = sort($instance->meta_names);

is(@names, 9);
is($names[0], 'end');
is($instance->meta('start'), 342466);

@names = sort($instance->tag_names);
is(@names, 8);
my @dbx = sort($instance->tags('db_xref'));
is(@dbx, 3);
is($dbx[0], 'BEEBASE:GB10320');
is($instance->tag('exon_number'), 5);
like($instance->data, qr/(?:\S+\t){8}/);

is($ds->start, 31999);
is($ds->length, 380);

