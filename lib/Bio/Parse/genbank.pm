package Bio::Parse::genbank;

use 5.010;
use strict;
use warnings;
use base 'Bio::Parse';
use Data::Dumper;

#sub _initialize {
#    my ($self, %args) = @_;
#    # cache locally for speed
#    $self->SUPER::_initialize(%args);
#}

sub _next_dataset {
    my $self = shift;
    my $fh = $self->fh;
    PARSER:
    while (defined(my $line = <$fh>)) {
        next if $line =~ m{^\s*$};
        chomp;
        my ($key);
        given ($line) {
            when (index($line, '//') == 0) {
                $self->{state}{MODE} = 'RECORD_END';
                $self->{state}{DATA} = $line;
            }
            # sequence
            when (m{^\s*\d+\s([\w\s]+)$}ox) {
                $self->{state}{MODE} = 'SEQUENCE';
                $self->{state}{DATA} = $1;
            }
            # annotation and feature key
            when (m{^(\s{0,5})(\w+)\s+(.*)$}ox) {
                $self->{state}{MODE} = length($1) < 5 ? 'ANNOTATION' : 'FEATURE';
                ($key, $self->{state}{DATA}) = ($2, $3);
            }
            # feature tags
            #when (m{^(\s{5,})(\w+)\s+(.*)$}ox) {
            #    $self->{mode} = length($1) < 5 ? 'ANNOTATION' : 'FEATURE';
            #    ($key, $self->{current_data}) = ($2, $3);
            #}
            # append to prior data
            default {
                $line =~ s/^\s+//;
            }
            # if there is prior data set, and we need to reset state, prep data
            # and return
        }
    }
    0;
    #    if ($ann && $ann eq 'ORIGIN') {
    #        SEQ:
    #        while (defined($line)) {
    #            last SEQ if index($line,'//') == 0;
    #            $seqdata->{DATA} .= uc $line;
    #            $line = $self->_readline;
    #        }
    #        $seqdata->{DATA} =~ tr{0-9 \n}{}d;
    #    }
    #    $endrec = 1 if (index($line,'//')==0);
    #
    #    if ($line =~ m{^(\s{0,5})(\w+)\s+(.*)$}ox || $endrec) {
    #        ($ann, $data) = ($2, $3);
    #        unless ($seenlocus) {
    #            $self->throw("No LOCUS found.  Not GenBank in my book!")
    #                if ($ann ne 'LOCUS');
    #            $seenlocus = 1;
    #        }
    #        # use the spacer to determine the annotation type
    #        my $len = length($1 || '');
    #
    #        $annkey  = ($len == 0 || $len > 4)   ? 'DATA'  : $ann;
    #
    #        # Push off the previously cached data to the handler
    #        # whenever a new primary annotation or seqfeature is found
    #        # Note use of $endrec for catching end of record
    #        if (($annkey eq 'DATA') && $seqdata) {
    #            chomp $seqdata->{DATA};
    #            # postprocessing for some data
    #            if ($seqdata->{NAME} eq 'FEATURES') {
    #                $self->_process_features($seqdata)
    #            }
    #
    #            # using handlers directly, slightly faster
    #            #my $method = (exists $handlers->{ $seqdata->{NAME} }) ?
    #            #        ($handlers->{$seqdata->{NAME}}) :
    #            #    (exists $handlers->{'_DEFAULT_'}) ?
    #            #        ($handlers->{'_DEFAULT_'}) :
    #            #    undef;
    #            #($method) ? ($hobj->$method($seqdata) ) :
    #            #        $self->debug("No handler defined for ",$seqdata->{NAME},"\n");
    #
    #            # using handler methods in the Handler object, more centralized
    #            #$self->debug(Dumper($seqdata));
    #            $hobj->data_handler($seqdata);
    #
    #            # bail here on //
    #            last PARSER if $endrec;
    #            # reset for next round
    #            $seqdata = undef;
    #        }
    #
    #        $seqdata->{NAME} =  ($len == 0) ? $ann :   # primary ann
    #                            ($len > 4 ) ? 'FEATURES': # sf feature key
    #                            $seqdata->{NAME};      # all rest are sec. ann
    #        if ($seqdata->{NAME} eq 'FEATURES') {
    #            $seqdata->{FEATURE_KEY} = $ann;
    #        }
    #        # throw back to top if seq is found to avoid regex
    #        next PARSER if $ann eq 'ORIGIN';
    #
    #    } else {
    #        ($data = $line) =~ s{^\s+}{};
    #        chomp $data;
    #    }
    #    my $delim = ($seqdata && $seqdata->{NAME} eq 'FEATURES') ? "\n" : ' ';
    #    $seqdata->{$annkey} .= ($seqdata->{$annkey}) ? $delim.$data : $data;
    #}
    #return $hobj->build_sequence;
}

1;

__END__

MODES = ANNOTATION, FEATURE, SEQUENCE
