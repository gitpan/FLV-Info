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

our $VERSION = '0.01';

=for stopwords subtag

=head1 NAME

FLV::Tag - Flash video file data structure

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

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

   my ($type, $datasize1, $datasize2, $datasize3,
       $timestamp1, $timestamp2, $timestamp3, $reserved)
       = unpack 'CCCCCCCN', $content;

   $self->debug("tag type: $type, size: $datasize1+$datasize2+$datasize3, " .
                "time: $timestamp1/$timestamp2/$timestamp3, reserved: $reserved");

   my $datasize  = ($datasize1  * 256 + $datasize2)  * 256 + $datasize3;
   my $timestamp = ($timestamp1 * 256 + $timestamp2) * 256 + $timestamp3;

   if ($datasize < 11)
   {
      croak 'Tag size is too small at byte '.$file->get_pos(-10);
   }
   if ($reserved)
   {
      croak 'Reserved fields are non-zero at byte '.$file->get_pos(-4);
   }

   my $payload_class = $TAG_CLASSES{$type} 
      or croak 'Unknown tag type '.$type.' at byte '.$file->get_pos(-11);

   $self->{payload} = $payload_class->new();
   $self->{payload}->{start} = $timestamp;
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

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
