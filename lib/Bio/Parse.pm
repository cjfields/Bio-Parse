package Bio::Parse;

# ABSTRACT: Somewhat low-level biological file format parser

use 5.012; # get nice 5.12 features like yada, may revert to 5.10 at some point
use strict;
use warnings;
use IO::Unread;  # pushback buffering, stack-based
use Bio::Parse::DataSet;
use Scalar::Util qw(blessed);
use Carp ();
use Class::Load;

our $CACHE_SIZE = 1;

# lifted from Bio::SeqIO for our own nefarious purposes
sub new {
    my ($caller,@args) = @_;
    my $class = ref($caller) || $caller;
    if( $class =~ /Bio::Parse::\S+/ ) {
        my ($self) = bless {@args}, $class;
        $self->_initialize(@args);
        return $self;
    } else {
        my %param = @args;
        @param{ map { s/^-//; lc } keys %param } = values %param;
        my $fh = $param{fh};
        # required params
        unless ( $param{file} ||
                ( ref $fh && ( ref($fh) ~~ 'GLOB' ) )
             || ( blessed $fh && ( $fh->isa('IO::Handle')
                                || $fh->isa('IO::String') ) )
             ) {
            Carp::croak "'fh' parameter not provided or invalid, must ".
            "provide a filehandle or IO::Handle-based filehandle, got ".ref($param{fh});
        }

        if (!defined($param{format})) {
            Carp::croak "No 'format' provided; format guessing not implemented"
        }
        $param{format} = "\L$param{format}";    # normalize capitalization to lower case
        if ($param{format} =~ /-/) {
            ($param{format}, $param{variant}) = split('-', $param{format}, 2);
        }

        my $module = "Bio::Parse::$param{format}";
        $class->_load_format_module($module);
        return $module->new(%param);
    }
}

sub _initialize {
    # noop, subclasses override as needed...
}

sub fh {
    my $self = shift;
    # we could probably include a convenience for using PerlIO layers here
    # (normalizing line endings, etc.)

    if (!exists $self->{fh} && exists $self->{file}) {
        open(my $fh, '<', $self->{file}) || die "Unknown file: $!";
        $self->{fh} = $fh;
    }
    $self->{fh};
}

sub file {
    my $self = shift;
    $self->{fh};
}

sub format {
    my $self = shift;
    $self->{format};
}

sub variant {
    my $self = shift;
    $self->{variant};
}

sub meta_map {
    my $self = shift;
    $self->{meta_map};
}

# grab next chunk of data from fh (implement in actual parser!)
sub next_dataset {...}

# method to wrap data structure in a queryable object
sub next_instance {
    my $self = shift;
    my $ds = $self->next_dataset;
    defined $ds ? return Bio::Parse::DataSet->new($ds) : return;
}

# utility methods for parsers

# simplified pushback using IO::UnRead
sub pushback {
    my ($self, $value) = @_;
    unread $self->fh, $value if defined($value);
}

# simple base exceptions, just uses Carp
sub throw {
    my $self = shift;
    Carp::croak shift;
}

sub warn {
    my $self = shift;
    Carp::carp shift;
}

sub confess {
    my $self = shift;
    Carp::confess shift;
}

sub method_not_implemented {
    my $self = shift;
    (caller(1))[3]." is not implemented by ".ref($self)
}

<<<<<<< Updated upstream
# a very simplistic API for working on, modifying, and switching out datasets
# do not rely on until stable!  Not required of base modules...
=======
# A very simplistic API for working on, modifying, and switching out datasets.
# This may switch to a stack-based method to deal with more complex formats. Do
# not rely on until stable!
>>>>>>> Stashed changes

sub new_dataset {
    my ($self, $ds) = @_;
    unshift @{$self->{datasets}}, $ds;
}

sub num_datasets {
    scalar(@{shift->{datasets}});
}

sub current_dataset { shift->{datasets}[0]; }

sub current_mode { shift->{datasets}[0]{MODE}; }

sub pop_dataset {
    my $self = shift;
    pop @{$self->{datasets}};
}

# TODO: append could be smarter and not add newlines, just sayin'
sub append_data {
    my ($self, @args) = @_;
    if (@args == 2) {
        $self->{datasets}[0]{META}{$args[0]}[0] .= "\n$args[1]";
    } else {
        $self->{datasets}[0]{DATA} .= "\n$args[0]";
    }
    1;
}

sub add_meta_data {
    my ($self, $meta) = @_;
    while (my ($key, $value) = each %$meta) {
        push @{$self->{datasets}[0]{META}{$key}}, $value;
    }
}

# lifted from Bio::SeqIO, but using Module::Load
sub _load_format_module {
    my ($ci, $module) = @_;

    eval { Class::Load::load_class($module); 1 } ;
    if ( $@ ) {
        $ci->throw(<<END);
$ci: $module cannot be found
Exception $@
For more information about the Bio::Parse system please see the Bio::Parse docs.
END
        ;
    }
    1;
}

1;

__END__

=head1 NAME

Bio::Parse - Generic parsing of common bioinformatics formats.

=head1 VERSION

This documentation refers to Bio::Parse version 0.01.

=head1 SYNOPSIS

   use Bio::Parse;
   my $in = Bio::Parse->new(format  => 'genbank', file  => $file);

   # retrieve low-level hash reference-based data from input stream
   while (my $hr = $in->next_hr) {
       # data type
       my $mode = $ds->{MODE};

       # captured data (see docs for explanation)
       my $primary_data = $ds->{META};
       my $tags = $ds->{META}{TAGS};

       # raw unparsed data
       my $raw = $ds->{DATA};

       # start and length of data
       my $start = $ds->{START};
       my $start = $ds->{LENGTH};
   }

   # alternatively, retrieve slightly higher level queryable decorator for above
   # hash reference

   while (my $ds = $in->next_dataset) {
       # data type
       my $mode = $ds->mode;

       # captured data (see docs for explanation)
       my $primary_data = $ds->meta;
       # names of any META tags
       my @meta_names = $ds->meta_names;
       my $tags = $ds->tags;

       # raw unparsed data
       my $raw = $ds->data;

       # start and length of data
       my $start = $ds->start;
       my $start = $ds->length;
   }

=head1 DESCRIPTION

Currently, perl-based parsers for common bioinformatics data are hard-coded to a
specific API or to use a particular object system (BioPerl, Bio::Phylo, etc).
Unfortunately, this has led to a number of redundancies for various parsers,
with the some formats (GFF3, NeXML, etc) being re-implemented several times to
accomplish varying end-tasks, such as generation of queryable instances,
persistence of data, indexing of files, generation of structure data such as
JSON, format validation, and so forth. Furthermore, parser optimizations
(such as alternative implementations or using XS-based parsers) are impractical.

Bio::Parse is a collection of low-level parsers for common bioinformatics
formats that attempts to solve this to a degree by decoupling parsing from any
object systems that may be used to represent the data for downstream analyses.
As most data in bioinformatics applications represent one or more common types
(sequences, alignments, features, annotation, phylogenetic information,
structures, etc), these parsers attempt to be slightly smarter with the data
parsed by clustering related data instead of passing simple events, though
events are supported by default.

As an example, GenBank format is composed of three basic sections: annotations,
features, and raw sequence data. Annotations have a general name: LOCUS,
ACCESSION, etc. associated with simple text information. Features are defined in
a specific document and thus have a fairly rigid structure of location
information (a location string) and simple tag-value pairs. Formatted sequence
data can be parsed to retrieve only raw sequence.

Data from a GenBank file are returned as a stream of tagged data. Files are
handled as well as file handles:

   use Bio::Parse;

   # use 'fh' for filehandles
   my $in = Bio::Parse->new(format  => 'genbank', file  => $file);

Data is returned either as a structured hash reference:

   while (my $hr = $in->next_hr) {
       ...
   }

or as a blessed decorator object around the hash reference
(L<Bio::Parse::DataSet>):

   while (my $hr = $in->next_dataset) {
       ...
   }

Data structures have a fairly simple defined set of data.  An example of GenBank
annotation:

    {
   'MODE'   => 'ANNOTATION',
   'DATA'   => 'ACCESSION   D10483 J01597 J01683 J01706 K01298 K01990'
   'META' => {
        'KEY'   => 'ACCESSION',
        'VALUE' => 'D10483 J01597 J01683 J01706 K01298 K01990'
        }
   'TAGS'  => {
        'accession' => ['D10483','J01597','J01683','J01706','K01298','K01990']
    },
   'START'  => 139,
   'LENGTH' => 128
   }

=over 3

=item * MODE

A simple string specifying the type of data.  Required.

=item * DATA

The raw unparsed data. Required, but can be undef. The MODE and DATA would
correspond roughly to an XML tag and data.

=item * META

A defined set of key-value pairs based on the mode, where the values are simple
scalar values. This could correspond to XML elements for tags.

For an annotation, this might be something as simple as:

   'MODE'   => 'ANNOTATION',
   'META' => {
        'KEY'   => 'ACCESSION',
        'VALUE' => 'D10483 J01597 J01683 J01706 K01298 K01990'
        }

This differs from the raw data in that the data may be processed to remove new
lines.

May be empty, depending on the MODE and the parse level (TODO: NYI).

=item * TAGS

A defined set of key-value pairs based on both the mode and data in the META
set. For instance, in the example above, the raw string of space-separated
accessions can be further processed to an array of accessions:

   'TAGS'  => {
        'accession' => ['D10483','J01597','J01683','J01706','K01298','K01990']
    },

Values B<MUST> be an array, but tags are somewhat free-form. If more complex
relations are required (hierarchal data), it is highly suggested that one break
the data up into simpler values or return it unmodified for downstream handlers
to deal with accordingly.

May be empty, depending on the MODE and the parse level (TODO: NYI).

As might be guessed (and somewhat like XML), TAGS and META data can be somewhat
interchangeable.

=item * START

The place in the stream where the data begins. Not required but highly
recommended (can be used for indexers)

=item * LENGTH

Length of the B<raw data> in the stream. Not required but highly recommended
(can be used for indexers)

=head1 SUBROUTINES/METHODS

<TODO>

=head1 CONFIGURATION AND ENVIRONMENT

<TODO>

=head1 DEPENDENCIES

The basic implementations contained in this distribution aim to be very
low-level and require few dependencies. At the moment Bio::Parse requires a
minimum of perl 5.12.0, though we could feasibly use older versions (patches
welcome!). We use L<Class::Load> for run-time loading of the various format
plugin modules, L<Any::URI::Escape> for GFF3-based symbol handling, and

=head1 INCOMPATIBILITIES

<TODO>

=head1 BUGS AND LIMITATIONS

=head2 TODO

=over 3

=item * DataSet decorator is immutable, needs simple getter/setters

Unlike the hash-reference structure, the Bio::Parse:: DataSet is currently
immutable.

=item * META tags are hard-coded

Need a simple framework for defining/mapping META names for hash references
in cases where one may want an alternative naming structure (e.g. for passing
the data as '-'-prefixed named arguments to a BioPerl class, for instance).

=item * Implement stack-based structure?

Already something remedial in place for this, but the interface is very simple,
is private, and doesn't currently allow getting/setting data for intermediate
values on the stack, nor looking up data on the stack by position.

=back

User feedback is an integral part of the evolution of this and other Biome and
BioPerl modules. Send your comments and suggestions preferably to one of the
BioPerl mailing lists. Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

Patches are always welcome.

=head2 Reporting Bugs

Bug reports should be reported to the GitHub Issues bug tracking system:

  http://github.com/cjfields/Bio-Parse/issues

=head1 SEE ALSO

L<BioPerl>, L<Bio::Phylo>

=head1 (DISCLAIMER OF) WARRANTY

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 ACKNOWLEDGEMENTS

Most of this work is based on parsers written for the BioPerl suite of modules
(of which I am a core developer).  I would like to acknowledge all contributors
to the BioPerl project for their code and help.

=head1 AUTHOR

Chris Fields  C<< <cjfields at bioperl dot org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011 Chris Fields (cjfields at bioperl dot org). All rights reserved.

followed by whatever licence you wish to release it under.
For Perl code that is often just:

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Pre-POD ramblings:

Initial goal: parse data into specific data structures that are somewhat in
relation to common Bio* classes, but aren't forcing one into using BioPerl or
other object systems. Data is passed as a stream of simple data structures with
as little nesting as possible and with very little to no coercing of data (that
is left up to any downstream data handlers).  This will decouple parsing of data
from specific object creation.

There is some initial work along these lines within BioPerl itself, namely
Bio::SeqIO::gbdriver/swisshandler/emblhandler/fastq and Bio::AlignIO::stockholm,
but they all have specific somewhat hacky elements due to forcing them into the
BioPerl class system. Because I am experimenting with a Moose-based system, it
seemed like a good time to work on decoupling the parsing and object creation
aspects in BioPerl, make the parsing perhaps a little less reliant on the
overall BioPerl class structure. And, sometimes I really just want to get
through data very quickly.

Data structures will be derived from those. For instance, data structures for
sequence formats will revolve around the sequence, sequence features, and report
annotation. A lot of prior art exists in this field, much of which define very
specific data types for describing pieces of biological information. I
anticipate drawing from such sources like Chado, GusDB, the Bio* classes, and so
on to derive these structures.

NOTAGOAL:

  * Making this a validation tool.  This will handle very low-level
    parsing of data at a very generic level, nothing more.
  * Having the tools write output (may change, but it will be very simple). This
    is a *parser*, not a *writer*
  * Forcing this into one class system or another (this will remain independent
    of BioPerl)
  * Adding excessive dependencies beyond what is described.  This doesn't mean
    that something like an XML-based system will not be allowed, but I would
    like for those to be distributed independently of these modules. Note, this
    also allows one to write up other means of parsing (such as C-based parsers)
    independently.

SIMPLE DATA FORMAT

# data relevant
MODE = the data type being passed (as well as it can be defined)
DATA = the raw data string for this mode (minus any mode-relative information)
META = a data structure (generally a hash reference) containing possibly
relevant information.  Redundant combined with the data above, but easier to
digest :)

# for those interested in indexing a file for whatever reason (this is NYI):
START = start of the data chunk in the data stream
LENGTH = length of the data chunk

# Should we have different levels of a parse (e.g. if we are only interested
in indexing on a per-record basis, maybe just parse at the top-level? That might
be possible...
