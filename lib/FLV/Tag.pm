package FLV::Tag;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';

use FLV::Constants;
use FLV::AudioTag;
use FLV::VideoTag;
use FLV::MetaTag;

our $VERSION = '0.16';

=for stopwords subtag

=head1 NAME

FLV::Tag - Flash video file data structure

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts an FLV tag from the file
stream.  This method then multiplexes that tag into one of the
subtypes: video, audio or meta.  This method throws exceptions if the
stream is not a valid FLV v1.0 or v1.1 file.

At the end, this method stores the subtag instance, which can be
retrieved with get_payload().

There is no return value.

=cut

sub parse
{
   my $self = shift;
   my $file = shift;

   my $content = $file->get_bytes(11);
   
   my ($type, @datasize, @timestamp, $reserved);
   ($type, $datasize[0], $datasize[1], $datasize[2],
    $timestamp[1], $timestamp[2], $timestamp[3], $timestamp[0])
       = unpack 'CCCCCCCC', $content;

   my $datasize  = ($datasize[0]  * 256 + $datasize[1])  * 256 + $datasize[2];
   my $timestamp
       = (($timestamp[0] * 256 + $timestamp[1]) * 256 + $timestamp[2]) * 256 + $timestamp[3];

   if ($timestamp > 4_000_000_000 || $timestamp < 0)
   {
      warn "Funny timestamp: @timestamp -> $timestamp\n";
   }

   if ($datasize < 11)
   {
      die 'Tag size is too small ('.$datasize.') at byte ' . $file->get_pos(-10);
   }

   my $payload_class = $TAG_CLASSES{$type} 
      or die 'Unknown tag type ' . $type . ' at byte ' . $file->get_pos(-11);

   $self->{payload} = $payload_class->new();
   $self->{payload}->{start} = $timestamp; # millisec
   $self->{payload}->parse($file, $datasize); # might throw exception

   return;
}

=item $self->get_payload()

Returns the subtag instance found by parse().  This will be instance
of FLV::VideoTag, FLV::AudioTag or FLV::MetaTag.

=cut

sub get_payload
{
   my $self = shift;
   return $self->{payload};
}

=item $pkg->serialize($tag, $filehandle)

=item $self->serialize($tag, $filehandle)

Serializes the specified video, audio or meta tag.  If that
representation is not complete, this throws an exception via croak().
Returns a boolean indicating whether writing to the file handle was
successful.

=cut

sub serialize
{
   my $pkg_or_self = shift;
   my $tag         = shift || croak 'Please specify a tag';
   my $filehandle  = shift || croak 'Please specify a filehandle';

   my $tag_type = {reverse %TAG_CLASSES}->{ref $tag} || die 'Unknown tag class ' . ref $tag;
   
   my @timestamp = (
      $tag->{start} >> 24 & 0xff,
      $tag->{start} >> 16 & 0xff,
      $tag->{start} >> 8 & 0xff,
      $tag->{start} & 0xff,
   );
   my $data     = $tag->serialize();
   my $datasize = length $data;
   my @datasize = (
      $datasize >> 16 & 0xff,
      $datasize >> 8 & 0xff,
      $datasize & 0xff,
   );

   my $header = pack 'CCCCCCCCCCC', $tag_type, @datasize, @timestamp[1..3], $timestamp[0], 0, 0, 0;
   return if (!print {$filehandle} $header);
   return if (!print {$filehandle} $data);
   return 11 + $datasize;
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
