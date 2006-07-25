package FLV::AudioTag;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);
use Readonly;

use base 'FLV::Base';

use FLV::Constants;

our $VERSION = '0.11';

=head1 NAME

FLV::AudioTag - Flash video file data structure

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts an FLV audio tag from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.

There is no return value.

Note: this method needs more work to extract the format-specific data.

=cut

sub parse
{
   my $self     = shift;
   my $file     = shift;
   my $datasize = shift;

   my $flags = unpack 'C', $file->get_bytes(1);

   my $format = (($flags >> 4) & 0x0f);
   my $rate   = (($flags >> 2) & 0x03);
   my $size   = (($flags >> 1) & 0x01);
   my $type   = ( $flags       & 0x01);

   if (!exists $AUDIO_FORMATS{$format})
   {
      die 'Unknown audio format ' . $format . ' at byte ' . $file->get_pos(-1);
   }

   $self->{format} = $format;
   $self->{rate}   = $rate;
   $self->{size}   = $size;
   $self->{type}   = $type;

   $self->{data} = $file->get_bytes($datasize - 1);

   return;
}

=item $self->serialize()

Returns a byte string representation of the tag data.  Throws an
exception via croak() on error.

=cut

sub serialize
{
   my $self = shift;

   my $flags = pack 'C', 
         ($self->{format} << 4)
       | ($self->{rate}   << 2)
       | ($self->{size}   << 1)
       |  $self->{type};
   return $flags . $self->{data};
}

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $pkg = shift;
   return $pkg->_get_info('audio', {format => \%AUDIO_FORMATS,
                                    rate   => \%AUDIO_RATES,
                                    size   => \%AUDIO_SIZES,
                                    type   => \%AUDIO_TYPES}, \@_);
}

# sub get_duration
# {
#    my $self = shift;
#
#    # Doesn't work yet
#
#    my $bytes = length $self->{data};
#    my $hz    = $self->{format} == 5 ? 8000
#              : $self->{rate} == 0   ? 5512
#              : $self->{rate} == 1   ? 11025
#              : $self->{rate} == 2   ? 22050
#              : $self->{rate} == 3   ? 44100
#              : croak;
# }

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
