package Bio::Parse::Dataset;

use Modern::Perl;
use Carp;

sub new {
    my ($class, $ds) = @_;
    $class = ref($class) ? ref($class) : $class;
    Carp::croak("Not a hash reference; can't create dataset") unless ref $ds eq 'HASH';
    return bless $ds, $class;
}

sub start { $_[0]->{START} }

sub length { $_[0]->{LENGTH} }

sub meta_names {
    my $self = shift;
    return keys(%{$self->{META}}) if exists($self->{META});
}

sub meta {
    my ($self, $meta_name) = @_;
    return $self->{META}{$meta_name} if exists $self->{META}{$meta_name};
    $self->{META} if exists $self->{META};
}

sub data { $_[0]->{DATA} }

sub tag_names {
    return keys(%{$_[0]->{META}{tag}}) if exists $_[0]->{META}{tag};
}

sub tags {
    my ($self, $tag_name) = @_;
    return @{$self->{META}{tag}{$tag_name}} if exists $self->{META}{tag}{$tag_name};
    return $self->{META}{tag} if exists $self->{META}{tag};
}

sub tag {
    my ($self, $tag_name) = @_;
    return $self->{META}{tag}{$tag_name}[0] if exists $self->{META}{tag}{$tag_name};
}

1;
