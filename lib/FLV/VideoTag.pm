package FLV::VideoTag;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);
use Readonly;

use base 'FLV::Base';

use FLV::Constants;

our $VERSION = '0.01';

=for stopwords codec

=head1 NAME

FLV::VideoTag - Flash video file data structure

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

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
   my $self = shift;
   my $file = shift;
   my $datasize = shift;

   my $flags = unpack 'C', $file->get_bytes(1);

   # The spec PDF is wrong -- type comes first, then codec
   my $type  = ($flags >> 4) & 0x0f;
   my $codec =  $flags       & 0x0f;

   if (!exists $VIDEO_CODEC_IDS{$codec})
   {
      croak 'Unknown video codec '.$codec.' at byte '.$file->get_pos(-1);
   }
   if (!exists $VIDEO_FRAME_TYPES{$type})
   {
      croak 'Unknown video frame type at byte '.$file->get_pos(-1);
   }

   $self->{codec} = $codec;
   $self->{type}  = $type;

   my $pos = $file->get_pos();

   $self->{data} = $file->get_bytes($datasize-1);

   if ($self->{codec} == 2)
   {
      $self->_parse_h263($pos);
   }
   elsif ($self->{codec} == 3)
   {
      $self->_parse_screen_video($pos);
   }
   elsif ($self->{codec} == 4)
   {
      $self->_parse_on2vp6($pos);
   }

   return;
}

sub _parse_h263
{
   my $self = shift;
   my $pos = shift;

   # Surely there's a better way than this....
   my $bits = unpack 'B65', $self->{data};
   my $sizecode = substr $bits, 30, 3;
   my @d = ((ord pack 'B8', substr $bits, 33, 8),
            (ord pack 'B8', substr $bits, 41, 8),
            (ord pack 'B8', substr $bits, 49, 8),
            (ord pack 'B8', substr $bits, 57, 8));
   my ($width, $height, $offset) =
       $sizecode == '000' ? ($d[0], $d[1], 16)
     : $sizecode == '001' ? ($d[0]*256+$d[1], $d[2]*256+$d[3], 32)
     : $sizecode == '010' ? (352, 288, 0)
     : $sizecode == '011' ? (176, 144, 0)
     : $sizecode == '100' ? (128,  96, 0)
     : $sizecode == '101' ? (320, 240, 0)
     : $sizecode == '110' ? (160, 120, 0)
     : croak 'Illegal value for H.263 size code at byte '.$pos;

   $self->{width}  = $width;
   $self->{height} = $height;

   return;
}

sub _parse_screen_video
{
   my $self = shift;
   my $pos = shift;

   # Extract 4 bytes, big-endian
   my ($width, $height) = unpack 'nn', $self->{data};
   # Only use the lower 12 bits of each
   $width &= 0x3fff;
   $height &= 0x3fff;

   $self->{width}  = $width;
   $self->{height} = $height;
           
   return;
}

sub _parse_on2vp6
{
   my $self = shift;
   my $pos = shift;

   return;
}

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $pkg = shift;

   return $pkg->_get_info('video', {type   => \%VIDEO_FRAME_TYPES,
                                    codec  => \%VIDEO_CODEC_IDS,
                                    width  => undef,
                                    height => undef}, \@_);
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
