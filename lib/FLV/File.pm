package FLV::File;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';
use FLV::Header;
use FLV::Body;

our $VERSION = '0.02';

=head1 NAME

FLV::File - Parse Flash Video files

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($filename)

=item $self->parse($filehandle)

Reads the specified file.  If the file does not exist or is an invalid
FLV stream, an exception will be thrown via croak().

There is no return value.

=cut

sub parse
{
   my $self = shift;
   my $input = shift;

   $self->{header}     = undef;
   $self->{body}       = undef;
   $self->{filename}   = undef;
   $self->{filehandle} = undef;
   $self->{pos}        = 0;

   eval
   {
      if (ref $input)
      {
         $self->{filehandle} = $input;
      }
      else
      {
         $self->{filename} = $input;
         open my $fh, '<', $self->{filename}
            or croak q{}.$OS_ERROR;
         binmode $fh;
         $self->{filehandle} = $fh;
      }
      $self->{header} = FLV::Header->new();
      $self->{header}->parse($self); # might throw exception
      $self->{body} = FLV::Body->new();
      $self->{body}->parse($self); # might throw exception
   };
   if ($EVAL_ERROR)
   {
      die 'Failed to read FLV file: '.$EVAL_ERROR;
   }
   $self->{filehandle} = undef; # implicitly close the filehandle
   $self->{pos} = 0;
   return;
}

=item $self->serialize($filehandle)

Serializes the in-memory FLV data.  If that representation is not
complete, this throws an exception via croak().  Returns a boolean
indicating whether writing to the file handle was successful.

=cut

sub serialize
{
   my $self = shift;
   my $filehandle = shift || croak 'Please specify a filehandle';

   if (!$self->{header})
   {
      die 'Missing FLV header';
   }
   if (!$self->{body})
   {
      die 'Missing FLV body';
   }
   return $self->{header}->serialize($filehandle)
       && $self->{body}->serialize($filehandle);
}

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $self = shift;

   my %info = (
      filename => $self->{filename},
      filesize => -s $self->{filename},
      $self->{body}->get_info(),
   );
   return %info;
}

=item $self->get_filename()

Returns the filename, if any.

=cut

sub get_filename
{
   my $self = shift;
   return $self->{filename};
}

=item $self->get_bytes($n)

Reads C<$n> bytes off the active filehandle and returns them as a
string.  Throws an exception if the filehandle is closed or hits EOF
before all the bytes can be read.

=cut

sub get_bytes
{
   my $self = shift;
   my $n = shift || 0;

   return q{} if ($n <= 0);

   my $fh = $self->{filehandle};
   if (!$fh)
   {
      die 'Internal error: attempt to read a closed filehandle';
   }

   my $buf;
   my $bytes = read $fh, $buf, $n;
   if ($bytes != $n)
   {
      die 'Unexpected end of file';
   }
   $self->{pos} += $bytes;
   return $buf;
}

=item $self->get_pos()

=item $self->get_pos($offset)

Returns a string representing the current position in the filehandle.
This is intended for use in debugging or exceptions.  An example of
use: indicate that an input value five bytes behind the read head is
erroneous.

    die 'Error parsing version number at byte '.$self->get_pos(-5);

=cut

sub get_pos
{
   my $self   = shift;
   my $offset = shift || 0;

   my $pos = $self->{pos} + $offset;
   return sprintf '%d (0x%x)', $pos, $pos;
}

=item $self->at_end()

Returns a boolean indicating if the FLV stream is exhausted.  Throws
an exception if the filehandle is closed.

=cut

sub at_end
{
   my $self = shift;

   my $fh = $self->{filehandle};
   if (!$fh)
   {
      die 'Internal error: attempt to read a closed filehandle';
   }
   return eof $fh;
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
