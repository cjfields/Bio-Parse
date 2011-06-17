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

