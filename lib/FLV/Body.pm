package FLV::Body;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';

use FLV::Tag;
use FLV::VideoTag;
use FLV::AudioTag;
use FLV::MetaTag;

our $VERSION = '0.14';

=head1 NAME

FLV::Body - Flash video file data structure

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts the FLV body from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.

There is no return value.

=cut

sub parse
{
   my $self = shift;
   my $file = shift;

   my @tags;

TAGS:
   while (1)
   {
      my $lastsize = $file->get_bytes(4);

      if ($file->at_end())
      {
         last TAGS;
      }

      my $tag = FLV::Tag->new();
      $tag->parse($file);    # might throw exception
      push @tags, $tag->get_payload();
   }

   my %tagorder = (
      'FLV::MetaTag'  => 1,
      'FLV::AudioTag' => 2,
      'FLV::VideoTag' => 3,
   );
   $self->{tags} = [sort {$a->{start} <=> $b->{start} || ($tagorder{ref $a}||0) <=> ($tagorder{ref $b}||0)} @tags];
   return;
}

=item $self->serialize($filehandle)

Serializes the in-memory FLV body.  If that representation is not
complete, this throws an exception via croak().  Returns a boolean
indicating whether writing to the file handle was successful.

=cut

sub serialize
{
   my $self       = shift;
   my $filehandle = shift || croak 'Please specify a filehandle';

   return if (!print {$filehandle} pack 'V', 0);

   for my $tag (@{$self->{tags}})
   {
      my $size = FLV::Tag->serialize($tag, $filehandle);
      if (!$size)
      {
         return;
      }
      print {$filehandle} pack 'V', $size;
   }
   return 1;
}

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $self = shift;

   my %info = (
      duration    => $self->last_start_time(),
      FLV::VideoTag->get_info(grep { $_->isa('FLV::VideoTag') } @{$self->{tags}}),
      FLV::AudioTag->get_info(grep { $_->isa('FLV::AudioTag') } @{$self->{tags}}),
      FLV::MetaTag->get_info(grep { $_->isa('FLV::MetaTag') } @{$self->{tags}}),
   );

   return %info;
}

=item $self->get_tags()

Returns an array of tag instances.

=cut

sub get_tags
{
   my $self = shift;

   return @{$self->{tags}};
}

=item $self->get_video_frames()

Returns the video tags (FLV::VideoTag instances) in the FLV stream.

=cut

sub get_video_frames
{
   my $self = shift;

   return grep { $_->isa('FLV::VideoTag') } @{$self->{tags}};
}

=item $self->get_audio_packets()

Returns the audio tags (FLV::AudioTag instances) in the FLV stream.

=cut

sub get_audio_packets
{
   my $self = shift;

   return grep { $_->isa('FLV::AudioTag') } @{$self->{tags}};
}

=item $self->get_meta_tags()

Returns the meta tags (FLV::MetaTag instances) in the FLV stream.

=cut

sub get_meta_tags
{
   my $self = shift;

   return grep { $_->isa('FLV::MetaTag') } @{$self->{tags}};
}

=item $self->last_start_time()

Returns the start timestamp of the last tag, in milliseconds.

=cut

sub last_start_time
{
   my $self = shift;

   my $tag = $self->{tags}->[-1]
       or die 'No tags found';
   return $tag->{start};
}

=item $self->get_meta($key);

=item $self->set_meta($key, $value);

These are convenience functions for interacting with an C<onMetadata>
tag at time 0, which is a common convention in FLV files.  If the 0th
tag is not an L<FLV::MetaTag> instance, one is created and prepended
to the tag list.

See also C<get_value> and C<set_value> in L<FLV::MetaTag>.

=cut

sub get_meta
{
   my $self = shift;
   my $key  = shift;

   return if (!$self->{tags});
   my $meta = $self->{tags}->[0];
   return if (!eval { $meta->isa('FLV::MetaTag') });
   return $meta->get_value($key);
}

sub set_meta
{
   my $self  = shift;
   my $key   = shift;
   my $value = shift;

   my $meta;
   $self->{tags} ||= [];
   $meta = $self->{tags}->[0];
   if (!eval { $meta->isa('FLV::MetaTag') })
   {
      $meta = FLV::MetaTag->new();
      $meta->{start} = 0;
      unshift @{$self->{tags}}, $meta;
   }
   $meta->set_value($key => $value);
   return;
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
