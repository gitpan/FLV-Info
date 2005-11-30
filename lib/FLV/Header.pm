package FLV::Header;

use warnings;
use strict;
use Carp;

use base 'FLV::Base';

our $VERSION = '0.01';

=for stopwords FLVTool2

=head1 NAME

FLV::Header - Flash video file data structure

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts the FLV header from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.  The interpretation is a bit stricter than
other FLV parsers (for example FLVTool2).

There is no return value.

=cut

sub parse
{
   my $self = shift;
   my $file = shift;

   my $content = $file->get_bytes(9);
   if (9 > length $content)
   {
      croak 'Missing file header';
   }

   my ($signature, $version, $flags, $offset) = unpack 'A3CCN', $content;

   $self->debug("Signature: $signature, version: $version, ".
                "flags: $flags, offset: $offset");

   if (!$signature || $signature ne 'FLV')
   {
      croak 'Not an FLV file at byte '.$file->get_pos(-9);
   }
   if (!$version || $version != 1)
   {
      die 'Internal error: I only understand FLV version 1'
   }
   if (0 != ($flags & 0xfa))
   {
      croak 'Reserved header flags are non-zero at byte '.$file->get_pos(-5);
   }
   if ($offset != 9)
   {
      croak 'Unexpected value for body offset at byte '.$file->get_pos(-4);
   }

   $self->{has_audio} = $flags & 0x04 ? 1 : undef;
   $self->{has_video} = $flags & 0x01 ? 1 : undef;

   # Seek ahead in file
   if ($offset > 9)
   {
      $file->get_bytes($offset-9);
   }

   return;
}

=item $self->has_video()

Returns a boolean indicating if the FLV header predicts that video
data is enclosed in the stream.

This value is not consulted internally.

=cut

sub has_video
{
   my $self = shift;
   return $self->{has_video};
}

=item $self->has_audio()

Returns a boolean indicating if the FLV header predicts that audio
data is enclosed in the stream.

This value is not consulted internally.

=cut

sub has_audio
{
   my $self = shift;
   return $self->{has_audio};
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
