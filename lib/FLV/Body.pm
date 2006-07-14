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

our $VERSION = '0.02';

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
      $tag->parse($file); # might throw exception
      push @tags, $tag->get_payload();
   }

   $self->{tags} = [sort {$a->{start} <=> $b->{start}} @tags];
   return;
}

=item $self->serialize($filehandle)

Serializes the in-memory FLV body.  If that representation is not
complete, this throws an exception via croak().  Returns a boolean
indicating whether writing to the file handle was successful.

=cut

sub serialize
{
   my $self = shift;
   my $filehandle = shift || croak 'Please specify a filehandle';

   return if (! print {$filehandle} pack 'V', 0);

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
      FLV::VideoTag->get_info(grep {$_->isa('FLV::VideoTag')} @{$self->{tags}}),
      FLV::AudioTag->get_info(grep {$_->isa('FLV::AudioTag')} @{$self->{tags}}),
      FLV::MetaTag->get_info(grep {$_->isa('FLV::MetaTag')} @{$self->{tags}}),
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

=item $self->count_video_frames()

Returns the number of video tags in the FLV stream.

=cut

sub count_video_frames
{
   my $self = shift;

   return scalar grep {$_->isa('FLV::VideoTag')} @{$self->{tags}};
}

=item $self->count_audio_packets()

Returns the number of audio tags in the FLV stream.

=cut

sub count_audio_packets
{
   my $self = shift;

   return scalar grep {$_->isa('FLV::AudioTag')} @{$self->{tags}};
}

=item $self->count_meta_tags()

Returns the number of meta tags in the FLV stream.

=cut

sub count_meta_tags
{
   my $self = shift;

   return scalar grep {$_->isa('FLV::MetaTag')} @{$self->{tags}};
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

# =item $self->end_time()
#
# Doesn't work yet.
#
# This is a prototypic implementation that tries to extrapolate the end time of the FLV from metadata about the last tags.
#
# =cut
#
# sub end_time
# {
#    my $self = shift;
#
#    my $tag = $self->{tags}->[-1]
#        or die 'No tags found';
#
#    my $duration;
#    if ($tag->isa('FLV::VideoTag'))
#    {
#       my $f = $self->video_frames();
#       $duration = $tag->{start}/($f-1);
#    }
#    else
#    {
#       # Doesn't work yet
#       $duration = $tag->get_duration();
#    }
#    return $tag->{start} + $duration;
# }

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
