package Bio::Parse;

# ABSTRACT: Somewhat low-level biological file format parser

use 5.012; # get nice 5.12 features like ..., may revert to 5.10 at some point
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
        my %param;
        if (scalar(@args) == 2 || scalar(@args) % 2) {
            # simplest form
            @param{qw(fh format)} = @args[0..1]
        } else {
            %param = @args;
            @param{ map { lc $_ } keys %param } = values %param; # lowercase keys

            # required params
            if(!blessed($param{fh}) || !$param{fh}->isa('IO::Handle')) {
                Carp::croak "'fh' parameter not provided or invalid, must provide IO::Handle-based filehandle";
            }
            $param{format} || Carp::croak "No 'format' provided; format guessing not implemented"
        }
        $param{format} = "\L$param{format}";	# normalize capitalization to lower case
        if ($param{format} =~ /-/) {
            ($param{format}, my $variant) = split('-', $param{format}, 2);
            push @args, (variant => $variant);
        }
        return unless( $class->_load_format_module($param{format}) );
        return "Bio::Parse::$param{format}"->new(@args);
    }
}

# immutable
sub fh {
    my $self = shift;
    $self->{fh};
}

# immutable
sub format {
    my $self = shift;
    $self->{format};
}

# immutable
sub variant {
    my $self = shift;
    $self->{variant};
}

# grab next chunk of data from fh (implement in actual parser!)
sub next_dataset {
    ...
}

# utility methods for parsers

# simplified pushback using IO::UnRead
sub pushback {
    my ($self, $value) = @_;
    unread $self->fh, $value if defined($value);
}

# simple base exceptions
sub throw {
    Carp::croak shift;
}

sub warn {
    Carp::carp shift;
}

sub confess {
    Carp::confess shift;
}

# lifted from Bio::SeqIO, but using Module::Load
sub _load_format_module {
	my ($self, $format) = @_;
	my $module = "Bio::Parse::" . $format;
	my $ok;

	eval {
		$ok = load $module;
	};
	if ( $@ ) {
		confess <<END;
$self: $format cannot be found
Exception $@
For more information about the SeqIO system please see the SeqIO docs.
This includes ways of checking for formats at compile time, not run time
END
		;
	}
	return $ok;
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
