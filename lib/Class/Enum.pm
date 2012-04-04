package Class::Enum;
use strict;
use warnings;
use Carp ();

sub import {
    shift;
    my $pkg = caller(0);
    my %args;
    while (my $v = shift @_) {
        if (ref $v) {
            push @{$args{defs} ||= []}, $v;
        } else {
            $args{$v} = shift @_;
        }
    }
    my %key_ctor = (
        defs  => \&_mk_values,
        key   => \&_mk_keys,
    );
    my $pkg_info = { pkg => $pkg };
    for my $key (qw(defs key)) {
        if (defined $args{$key}) {
            Carp::croak "value of the '$key' parameter should be an arrayref"
                unless ref($args{$key}) eq 'ARRAY';
            $key_ctor{$key}->($pkg_info, $args{$key});
        }
    }
    _mk_values_sub($pkg_info) if $args{values};
    1;
}

sub _mk_values {
    my ($pkg_info, $defs) = @_;
    $pkg_info->{values} = [ map {  bless $_, $pkg_info->{pkg} } @$defs ];
}

sub _mk_keys {
    my ($pkg_info, $ns) = @_;
    for my $n (@$ns) {
        no strict 'refs';
        *{$pkg_info->{pkg} . '::from_' . $n} = __m_key($pkg_info, $n);
    }
}

sub _mk_values_sub {
    my ($pkg_info) = @_;
    no strict 'refs';
    *{$pkg_info->{pkg} . '::values'} = __m_values($pkg_info);
}

sub _mk_constants {
    my ($pkg_info, $n) = @_;
    for my $v ( @{$pkg_info->{values} || []} ) {
        no strict 'refs';
        *{$pkg_info->{pkg} . '::' . $v->{$n} } = sub () { $v };
    }
}

sub __m_key {
    my ($pkg_info, $n) = @_;
    for my $v ( @{$pkg_info->{values} || []} ) {
        Carp::croak "Duplicate entry @{[$v->{$n}]} for key '$n' at @{[$pkg_info->{pkg}]}"
              if $pkg_info->{'form_' . $n}->{$v->{$n}};
        $pkg_info->{'form_' . $n}->{$v->{$n}} = $v;
    }
    sub { $pkg_info->{'form_' . $n}->{defined $_[1] ? $_[1] : ''}; };
}

sub __m_values {
    my ($pkg_info) = @_;
    sub () {
        wantarray ? @{$pkg_info->{values} || []} : $pkg_info->{values};
    },
}

1;

__END__

=head1 NAME

Class::Enum - Automated enum-like class generation

=head1 SYNOPSIS

  package My::UserType;
  use Class::Enum (
    key    => [ qw( id name ) ],
    values => 1,
    {
       id   => 1,
       name => 'twitter',
    },
    {
       id   => 0,
       name => 'facebook',
    }
  );

  my $twitter = My::UserType->from_id(1); # +{ id => 1, name => 'twitter' }
  My::UserType->from_name('twitter')      # reference equal to $twitter

  @all_types = My::UserType->values;      # array of instances by defined order
  $all_types = My::UserType->values;      # arrayref of instances by defined order
  $all_types->[0]                         # reference equal to $twitter
  $all_types->[1]->{name};                # 'facebook';

=head1 DESCRIPTION

This modules generate classes whose number of instances are constant like enum.
One instance generated by constructors `from_xxx` and `values` is always same
reference with another, if those keyes are equal.

=head1 AUTHOR

Tsujikawa Takaya

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=back

=cut

