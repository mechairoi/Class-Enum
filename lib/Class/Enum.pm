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
            push @{$args{_defs} ||= []}, $v;
        } else {
            $args{$v} = shift @_;
        }
    }
    my %key_ctor = (
        _defs => \&_mk_definition,
        key   => \&_mk_constructor,
    );
    my $pkg_info = { pkg => $pkg };
    for my $key (qw(_defs key)) {
        if (defined $args{$key}) {
            Carp::croak "value of the '$key' parameter should be an arrayref"
                unless ref($args{$key}) eq 'ARRAY';
            $key_ctor{$key}->($pkg_info, $args{$key});
        }
    }
    _mk_constant($pkg_info, $args{const}) if $args{const};
    _mk_values($pkg_info) if $args{values};
    1;
}

sub _mk_definition {
    my ($pkg_info, $defs) = @_;
    $pkg_info->{values} = [ map {  bless $_, $pkg_info->{pkg} } @$defs ];
}

sub _mk_constructor {
    my ($pkg_info, $keys) = @_;
    for my $key (@$keys) {
        no strict 'refs';
        *{$pkg_info->{pkg} . '::from_' . $key} = __m_constructor($pkg_info, $key);
    }
}

sub _mk_values {
    my ($pkg_info) = @_;
    no strict 'refs';
    *{$pkg_info->{pkg} . '::values'} = __m_values($pkg_info);
}

sub _mk_constant {
    my ($pkg_info, $code) = @_;
    for my $v ( @{$pkg_info->{values} || []} ) {
        my $name = $pkg_info->{pkg} . '::' . do { local $_ = $v; $code->($v) };
        no strict 'refs';
        *{$name} = sub () { use strict 'refs'; $v };
    }
}

sub __m_constructor {
    my ($pkg_info, $k) = @_;
    for my $v ( @{$pkg_info->{values} || []} ) {
        Carp::croak "Duplicate entry @{[$v->{$k}]} for key '$k' at @{[$pkg_info->{pkg}]}"
              if $pkg_info->{'form_' . $k}->{$v->{$k}};
        $pkg_info->{'form_' . $k}->{$v->{$k}} = $v;
    }
    sub {
        my ($class, $name) = @_;
        defined $_[1] or Carp::croak 'missing arguments';
        $pkg_info->{'form_' . $k}->{$name}
            or Carp::croak "$class has no instance whose `$k` is `$name`";
    };
}

sub __m_values {
    my ($pkg_info) = @_;
    sub {
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
    const  => sub { uc $_->{name} },
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
  My::UserType->from_name('twitter')      # same
  UserType::TWITTER()                     # same

  @all_types = My::UserType->values;      # array of instances by defined order
  $all_types = My::UserType->values;      # arrayref of instances by defined order
  $all_types->[0]                         # reference equal to $twitter
  $all_types->[1]->{name};                # 'facebook';

=head1 DESCRIPTION

This modules generate classes whose number of instances are constant like enum.
One instance generated by constructors `from_xxx` and `values` is always same
reference with another, if those keys are equal.

=head1 AUTHOR

Tsujikawa Takaya

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=back

=cut
