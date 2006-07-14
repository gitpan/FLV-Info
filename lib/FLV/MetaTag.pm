package FLV::MetaTag;

use warnings;
use strict;
use Carp;
use English qw(-no_match_vars);
use Readonly;

use base 'FLV::Base';

use FLV::AMFReader;
use FLV::AMFWriter;
use FLV::Constants;

our $VERSION = '0.02';

=for stopwords FLVTool2 AMF

=head1 NAME

FLV::MetaTag - Flash video file data structure

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DESCRIPTION

As best I can tell, FLV meta tags are a pair of AMF data: one is the
event name and one is the payload.  I learned that from looking at
sample FLV files and reading the FLVTool2 code.

I've seen no specification for the meta tag, so this is all empirical
for me, unlike the other tags.

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts an FLV meta tag from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.

There is no return value.

The majority of the work is done by FLV::AMFReader.

=cut

sub parse
{
   my $self = shift;
   my $file = shift;
   my $datasize = shift;

   my $content = $file->get_bytes($datasize);

   #print STDERR "\n", map({sprintf '%02x', $_} unpack 'C*', $content), "\n";

   my @data = FLV::AMFReader->new($content)->read_flv_meta();

   #use File::Slurp;
   #write_file 'meta.txt', $content;
   #use Data::Dumper;
   #write_file 'meta.dump', Dumper(\@data);

   $self->{data} = \@data;

   return;
}

=item $self->serialize()

Returns a byte string representation of the tag data.  Throws an
exception via croak() on error.

=cut

sub serialize
{
   my $self = shift;

   my $content = FLV::AMFWriter->new()->write_flv_meta(@{$self->{data}});
   #print STDERR "\n", map({sprintf '%02x', $_} unpack 'C*', $content), "\n";
   return $content;
}

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $pkg = shift;
   my %info = $pkg->_get_info('meta', {}, \@_);
   if (@_ == 1)
   {
      my $data = $_[0]->{data}->[1];
      if ($data)
      {
         for my $key (keys %{$data})
         {
            my $value = $data->{$key};
            if (!defined $value)
            {
               $value = q{};
            }
            $value =~ s/ \A \s+    //xms;
            $value =~ s/    \s+ \z //xms;
            $info{'meta_'.$key} = $value;
         }
      }
   }
   return %info;
}

1;

__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
