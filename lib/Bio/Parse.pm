package Bio::Parse;

# ABSTRACT: Somewhat low-level biological file format parser

use 5.012; # get nice 5.12 features like yada, may revert to 5.10 at some point
use strict;
use warnings;
use IO::Unread;  # pushback buffering, stack-based
use Scalar::Util qw(blessed);
use Carp ();
use Module::Load;

# lifted from Bio::SeqIO for our own nefarious purposes
sub new {
    my ($caller,@args) = @_;
    my $class = ref($caller) || $caller;
    if( $class =~ /Bio::Parse::(\S+)/ ) {
        my ($self) = bless {@args}, $class;
        $self->_initialize(@args);
        return $self;
    } else {
        my %param = @args;
        @param{ map { s/-//; lc } keys %param } = values %param;
        my $fh = $param{fh};
        # required params
        unless ( ( ref $fh && ( ref($fh) ~~ 'GLOB' ) )
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
        Carp::croak "Unknown module Bio::Parse::$param{format}"
            unless( $class->_load_format_module($param{format}) );
        return "Bio::Parse::$param{format}"->new(%param);
    }
}

sub _initialize {
    # noop for now
}

sub fh {
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

# for keys that may be passed on as parameters down the way
# default: ''
sub prefix {
    my $self = shift;
    $self->{prefix} || '';
}

# grab next chunk of data from fh (implement in actual parser!)
sub next_dataset {...}

# utility methods for parsers

# simplified pushback using IO::UnRead
sub pushback {
    my ($self, $value) = @_;
    unread $self->fh, $value if defined($value);
}

# simple base exceptions
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

# lifted from Bio::SeqIO, but using Module::Load
sub _load_format_module {
    my ($self, $format) = @_;
    my $module = "Bio::Parse::" . $format;
    my $ok;

    eval {
        load $module;
        1;
    };
    if ( $@ ) {
        confess <<END;
$self: $format cannot be found
Exception $@
For more information about the Bio::Parse system please see the Bio::Parse docs.
END
        ;
    } else {
        1
    }
}

1;

__END__

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
DATA = a data structure (generally a hash reference) containing the data chunk
parsed

# for those interested in indexing a file for whatever reason:
START = start of the data chunk in the data stream
LENGTH = length of the data chunk

# Should we have different levels of a parse (e.g. if we are only interested
in indexing on a per-record basis, maybe just parse at the top-level? That might
be possible...
