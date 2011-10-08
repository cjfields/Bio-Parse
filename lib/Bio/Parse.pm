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

# a very simplistic API for working on, modifying, and switching out datasets
# do not rely on until stable!  Not required of base modules...

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
