package FLV::AMFWriter;

use warnings;
use strict;

use AMF::Perl::Util::Object;
use AMF::Perl::IO::OutputStream;
use base 'AMF::Perl::IO::Serializer';

our $VERSION = '0.11';

=for stopwords AMF Remoting

=head1 NAME

FLV::AMFReader - Wrapper for the AMF::Perl deserializer

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 METHODS

This is a subclass of AMF::Perl::IO::Deserializer.

That class is optimized for Flash Remoting communications.  We are
instead just interested in the protocol for the data payload of those
messages, since that's all that FLV carries.

So, this class is a hack.  We override the AMF::Perl::IO::Deserializer
constructor so that it doesn't start parsing immediately.  Also, we
pass it a string instead of an instantiated
AMF::Perl::IO::InputStream.

Also, as of this writing AMF::Perl was at v0.15, which lacked support
for hashes.  So, we hack that in.  Hopefully we did it in a
future-friendly way...

=over

=item $pkg->new($content)

Creates a minimal AMF::Perl::IO::Deserializer instance.

=cut

sub new
{
   my $pkg = shift;

   return $pkg->SUPER::new(AMF::Perl::IO::OutputStream->new());
}

=item $self->write_flv_meta(@data)

Returns a byte string of serialized data

=cut

sub write_flv_meta
{
   my $self = shift;
   my @data = @_;

   for my $d (@data)
   {
      $self->writeData($d);
   }
   return $self->{out}->flush();
}

=item $self->writeMixedArray()

Serializes a hashref.

This is a workaround for versions of AMF::Perl which did not handle
hashes (namely v0.15 and earlier).  This method is only installed if a
method of the same name does not exist in the superclass.

This should be removed when a newer release of AMF::Perl is available.

=item $self->writeData($datum)

This is a minimal override of writeData() in the superclass to add
support for mixed arrays (aka hashes).

As above, it is only installed if AMF::Perl::IO::Serializer lacks a
writeMixedArray() method.

=cut

if (! __PACKAGE__->can('writeMixedArray'))
{
   *writeMixedArray = sub
   {
      my ($self, $d) = @_;

      $self->{out}->writeByte(8);    # type code
      $self->{out}->writeLong(0);    # length, bogus value...
      $self->writeObject($d);
      return;
   };

   *writeData = sub
   {
      my ($self, $d, $type) = @_;

      if (!$type && (ref $d) && (ref $d) =~ m/HASH/xms)
      {
         $type = 'mixedarray';
      }

      if ($type && $type eq 'mixedarray')
      {
         $self->writeMixedArray($d);
      }
      else
      {
         $self->SUPER::writeData($d, $type);
      }
      return;
   };
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
