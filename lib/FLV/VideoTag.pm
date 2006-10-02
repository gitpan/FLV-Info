package FLV::VideoTag;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';

use FLV::Constants;

our $VERSION = '0.14';

=for stopwords codec

=head1 NAME

FLV::VideoTag - Flash video file data structure

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts an FLV video tag from the file
stream.  This method throws exceptions if the
stream is not a valid FLV v1.0 or v1.1 file.

There is no return value.

Note: this method needs more work to extract the codec specific data.

=cut

sub parse
{
   my $self     = shift;
   my $file     = shift;
   my $datasize = shift;

   my $flags = unpack 'C', $file->get_bytes(1);

   # The spec PDF is wrong -- type comes first, then codec
   my $type  = ($flags >> 4) & 0x0f;
   my $codec =  $flags       & 0x0f;

   if (!exists $VIDEO_CODEC_IDS{$codec})
   {
      die 'Unknown video codec ' . $codec . ' at byte ' . $file->get_pos(-1);
   }
   if (!exists $VIDEO_FRAME_TYPES{$type})
   {
      die 'Unknown video frame type at byte ' . $file->get_pos(-1);
   }

   $self->{codec} = $codec;
   $self->{type}  = $type;

   my $pos = $file->get_pos();

   $self->{data} = $file->get_bytes($datasize - 1);

   my $result
       = $self->{codec} == 2 ? $self->_parse_h263($pos)
       : $self->{codec} == 3 ? $self->_parse_screen_video($pos)
       : $self->{codec} == 4 ? $self->_parse_on2vp6($pos)
       : $self->{codec} == 5 ? $self->_parse_on2vp6_alpha($pos)
       : $self->{codec} == 6 ? $self->_parse_screen_video($pos)
       : die 'Unknown video type';

   return;
}

sub _parse_h263
{
   my $self = shift;
   my $pos  = shift;

   # Surely there's a better way than this....
   my $bits = unpack 'B67', $self->{data};
   my $sizecode = substr $bits, 30, 3;
   my @d = (
      (ord pack 'B8', substr $bits, 33, 8),
      (ord pack 'B8', substr $bits, 41, 8),
      (ord pack 'B8', substr $bits, 49, 8),
      (ord pack 'B8', substr $bits, 57, 8),
   );
   my ($width, $height, $offset)
       = $sizecode == '000' ? ($d[0], $d[1], 16)
       : $sizecode == '001' ? ($d[0] * 256 + $d[1], $d[2] * 256 + $d[3], 32)
       : $sizecode == '010' ? (352, 288, 0)
       : $sizecode == '011' ? (176, 144, 0)
       : $sizecode == '100' ? (128,  96, 0)
       : $sizecode == '101' ? (320, 240, 0)
       : $sizecode == '110' ? (160, 120, 0)
       : die 'Illegal value for H.263 size code at byte ' . $pos;

   $self->{width}  = $width;
   $self->{height} = $height;

   my $type = 1 + (substr $bits, 33+$offset, 1)*2 + substr $bits, 33+$offset+1, 1;
   if (!defined $self->{type})
   {
      $self->{type} = $type;
   }
   elsif ($type != $self->{type})
   {
      warn "Type mismatch: header says $VIDEO_FRAME_TYPES{$self->{type}}, " .
          "data says $VIDEO_FRAME_TYPES{$type}";
   }

   return;
}

sub _parse_screen_video
{
   my $self = shift;
   my $pos  = shift;

   # Extract 4 bytes, big-endian
   my ($width, $height) = unpack 'nn', $self->{data};

   # Only use the lower 12 bits of each
   $width  &= 0x3fff;
   $height &= 0x3fff;

   $self->{width}  = $width;
   $self->{height} = $height;

   $self->{type} ||= 1;

   return;
}

sub _parse_on2vp6
{
   my $self = shift;
   my $pos  = shift;

   if (!$self->{type})
   {
      # Bit 7 of the header (after 8 bits of offset) distinguishes keyframe from interframe
      my @bytes = unpack 'CC', $self->{data};
      $self->{type} = ($bytes[1] & 0x80) == 0 ? 1 : 2;
   }

   return;
}

sub _parse_on2vp6_alpha
{
   my $self = shift;
   my $pos  = shift;

   if (!$self->{type})
   {
      # Bit 7 of the header (after 32 bits of offset) distinguishes keyframe from interframe
      my @bytes = unpack 'CCCCC', $self->{data};
      $self->{type} = ($bytes[4] & 0x80) == 0 ? 1 : 2;
   }

   return;
}

=item $self->serialize()

Returns a byte string representation of the tag data.  Throws an
exception via croak() on error.

=cut

sub serialize
{
   my $self = shift;

   my $flags = pack 'C', ($self->{type} << 4) | $self->{codec};
   return $flags . $self->{data};
}

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $pkg = shift;

   return $pkg->_get_info('video', {
      type   => \%VIDEO_FRAME_TYPES,
      codec  => \%VIDEO_CODEC_IDS,
      width  => undef,
      height => undef,
   }, \@_);
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
