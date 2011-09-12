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
        given ($line) {
            # sequence
            when (m{^\s*\d+\s([\w\s]+)$}ox) {
                my $seq = $1;
                $seq =~ s/\s+//g;
                $self->new_dataset(
                    {MODE    => 'SEQUENCE',
                     DATA   => $seq}
                    );
            }
            # annotation and feature key
            when (m{^(\s{0,5})([\w'-]+)\s+(.*)$}ox) {
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
                if ($self->current_dataset->{MODE} eq 'FEATURE') {
                    if (m{^/([^=]+)=?(.+)?}) {
                        $self->add_meta_data({$1 => $2});
                        $self->{_current_ft_label} = $1;
                    } else {
                        $self->append_data($self->{_current_ft_label}, $_);
                    }
                } else {
                    $self->append_data($_);
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

# a very simplistic API for working on, modifying, and switching out datasets
# do not rely on until stable!

sub new_dataset {
    my ($self, $ds) = @_;
    unshift @{$self->{datasets}}, $ds;
}

sub num_datasets {
    scalar(@{shift->{datasets}});
}

sub current_dataset { shift->{datasets}[0]; }

sub pop_dataset {
    my $self = shift;
    pop @{$self->{datasets}};
}

# TODO: append could be smarter and not add newlines, just sayin'
sub append_data {
    my ($self, @args) = @_;
    if (@args == 2) {
        $self->{datasets}[-1]{META}{$args[0]}[0] .= "\n$args[1]";
    } else {
        $self->{datasets}[-1]{DATA} .= "\n$args[0]";
    }
    1;
}

sub add_meta_data {
    my ($self, $meta) = @_;
    while (my ($key, $value) = each %$meta) {
        push @{$self->{datasets}[0]{META}{$key}}, $value;
    }
}

1;

__END__

MODES = ANNOTATION, FEATURE, SEQUENCE
