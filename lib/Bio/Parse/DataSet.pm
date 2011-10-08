package Bio::Parse::DataSet;

use Modern::Perl;
use Carp;

# TODO: allow write interface

sub new {
    my ($class, $ds) = @_;
    $class = ref($class) ? ref($class) : $class;
    Carp::croak("Not a hash reference; can't create dataset") unless ref $ds eq 'HASH';
    return bless $ds, $class;
}

sub start { $_[0]->{START} }
sub length { $_[0]->{LENGTH} }
sub data { $_[0]->{DATA} }

sub meta_names {
    my $self = shift;
    return keys(%{$self->{META}}) if exists($self->{META});
}

sub meta {
    my ($self, $meta_name) = @_;
    return $self->{META}{$meta_name} if exists $self->{META}{$meta_name};
    $self->{META} if exists $self->{META};
}

sub tag_names {
    return keys(%{$_[0]->{META}{TAG}}) if exists $_[0]->{META}{TAG};
}

sub tags {
    my ($self, $tag_name) = @_;
    return @{$self->{META}{TAG}{$tag_name}} if exists $self->{META}{TAG}{$tag_name};
    return $self->{META}{TAG} if exists $self->{META}{TAG};
}

sub tag {
    my ($self, $tag_name) = @_;
    return $self->{META}{TAG}{$tag_name}[0] if exists $self->{META}{TAG}{$tag_name};
}

1;
