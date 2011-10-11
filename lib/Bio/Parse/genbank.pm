package Bio::Parse::genbank;

use 5.010;
use strict;
use warnings;
use base 'Bio::Parse';
use Data::Dumper;

# may hard-code this, uncertain yet...
$Bio::Parse::CACHE_SIZE = 2;

sub next_dataset {
    my $self = shift;
    my $fh = $self->fh;
    PARSER:
    while (defined(my $line = <$fh>)) {
        next if $line =~ m{^\s*$};
        chomp $line;
        # There is a better way to do this, since we know order we could check
        # for each section, optimize it later...

        given ($line) {
            # sequence
            when (m{^\s{0,10}\d+\s([\w\s]+)$}ox) {
                my $seq = $1;
                $seq =~ s/\s+//g;
                #if ($self->current_mode eq 'SEQUENCE') {
                #    $self->append_data($seq);
                #    next PARSER;
                #} else {
                    $self->new_dataset(
                        {MODE    => 'SEQUENCE',
                         DATA   => $seq}
                    );
                #}
            }
            # annotation and feature key
            when (m{^(\s{0,5})([\w'-]+)\s*([^\n]*)$}ox) {
                if (length($1) < 5) {
                    $self->new_dataset({
                            MODE    => 'ANNOTATION',
                            DATA    => $3,
                            META    => {
                                key => [$2]
                                }
                        });
                } else {
                    $self->new_dataset(
                        {
                            MODE    => 'FEATURE',
                            DATA    => $3,
                            META    => {
                                primary_tag => [$2],
                                location_string => [$3]
                            }
                        }
                        );
                    $self->{_current_ft_label} = 'location_string';
                }
            }
            when (index($_, '//') == 0) {
                $self->new_dataset(
                    {
                        MODE    => 'RECORD_END',
                        DATA    => $_
                    }
                    );
            }
            default {
                s/^\s+//;
                if ($self->current_mode eq 'FEATURE') {
                    if (m{^/([^=]+)=?(.+)?}) {
                        $self->add_meta_data({$1 => $2});
                        $self->{_current_ft_label} = $1;
                    } else {
                        $self->append_data($self->{_current_ft_label}, $_);
                        next PARSER;
                    }
                } else {
                    $self->append_data($_);
                    next PARSER;
                }
            }
        }
        if ($self->num_datasets() > $Bio::Parse::CACHE_SIZE ) {
            return $self->pop_dataset();
        }
    }
    if ($self->num_datasets()) {
        return $self->pop_dataset();
    }
    return;
}

1;

__END__

