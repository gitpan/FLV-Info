package FLV::Constants;

use warnings;
use strict;
use base 'Exporter';

our $VERSION = '0.16';

our @EXPORT =    ## no critic(Modules::ProhibitAutomaticExportation)
    qw(
    %TAG_CLASSES
    %AUDIO_FORMATS
    %AUDIO_RATES
    %AUDIO_SIZES
    %AUDIO_TYPES
    %VIDEO_CODEC_IDS
    %VIDEO_FRAME_TYPES
);

our %TAG_CLASSES = (
   8  => 'FLV::AudioTag',
   9  => 'FLV::VideoTag',
   18 => 'FLV::MetaTag',
);

our %AUDIO_FORMATS = (
   0 => 'uncompressed',
   1 => 'ADPCM',
   2 => 'MP3',
   5 => 'Nellymoser 8kHz mono',
   6 => 'Nellymoser',
);
our %AUDIO_RATES = (
   0 => '5518 Hz',
   1 => '11025 Hz',
   2 => '22050 Hz',
   3 => '44100 Hz',
);
our %AUDIO_SIZES = (
   0 => '8 bit',
   1 => '16 bit',
);
our %AUDIO_TYPES = (
   0 => 'mono',
   1 => 'stereo',
);

our %VIDEO_CODEC_IDS = (
   2 => 'Sorenson H.263',
   3 => 'Screen video',
   4 => 'On2 VP6',
   5 => 'On2 VP6 + alpha',
   6 => 'Screen video v2',
);
our %VIDEO_FRAME_TYPES = (
   1 => 'keyframe',
   2 => 'interframe',
   3 => 'disposable interframe',
);

1;

__END__

=head1 NAME

FLV::Constants - Flash video data

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 EXPORTS

=over

=item %TAG_CLASSES

=item %AUDIO_FORMATS

=item %AUDIO_RATES

=item %AUDIO_SIZES

=item %AUDIO_TYPES

=item %VIDEO_CODEC_IDS

=item %VIDEO_FRAME_TYPES

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut

