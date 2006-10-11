package FLV::Info;

use warnings;
use strict;
use List::Util qw(max);
use Data::Dumper;

use FLV::File;

our $VERSION = '0.16';

=for stopwords FLVTool2 interframes keyframes

=head1 NAME

FLV::Info - Extract metadata from Macromedia Flash Video files

=head1 SYNOPSIS

    use FLV::Info;
    my $reader = FLV::Info->new();
    $reader->parse('video.flv');
    my %info = $reader->get_info();
    print "$info{video_count} video frames\n";
    print $reader->report();

=head1 DESCRIPTION

This module reads Macromedia Flash Video (FLV) files and reports metadata about
those files.

=head1 LEGAL

This work is based primarily on the file specification provided by
Macromedia.  Use of that specification is governed by terms indicated
at the licensing URL specified below.

L<http://download.macromedia.com/pub/flash/flash_file_format_specification.pdf>

L<http://www.macromedia.com/licensing/developer/>

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 QUALITY

We care about code quality.  The FLV-Info distribution complies with
the following quality metrics:

=over

=item * Perl::Critic v0.18 passes

=item * Devel::Cover test coverage over 90%

=item * Pod::Coverage at 100%

=item * Test::Spelling passes

=item * Test::Portability::Files passes

=back

=head1 METHODS

=over

=item $pkg->new()

Creates a new instance.

=cut

sub new
{
   my $pkg = shift;

   my $self = bless {
      file => undef,
      info => undef,
   }, $pkg;

   return $self;
}

=item $self->parse($filename)

=item $self->parse($filehandle)

Reads the specified file.  If the file does not exist or is an invalid
FLV stream, an exception will be thrown via croak().

There is no return value.

=cut

sub parse
{
   my $self     = shift;
   my $filename = shift;

   $self->{info} = undef;
   $self->{file} = FLV::File->new();
   $self->{file}->parse($filename);   # might throw exception
   return;
}

=item $self->get_info()

Returns a hash with all FLV metadata.  Any fields that are multivalued
are concatenated with a slash (C</>) with the most common values
specified first.  For example, a common case is the C<video_type>
which is often C<interframe/keyframe> since interframes are more
common than keyframes.  A less common case could be C<audio_type> of
C<mono/stereo> if the FLV was mostly one-channel but had some packets
of two-channel audio.

=cut

sub get_info
{
   my $self = shift;

   if (!$self->{info})
   {
      my %info;
      if ($self->{file})
      {
         %info = $self->{file}->get_info();
      }
      $self->{info} = \%info;
   }
   return %{$self->{info}};
}

=item $self->report()

Returns a summary of all FLV metadata as a string.  This is a
human-readable version of the data returned by get_info().

=cut

sub report
{
   my $self = shift;

   my %info = $self->get_info();

   # l = label
   # k = key
   # u = unit (should make sense to pluralize by appending an 's')
   # r = key match regex
   # p = prefix
   # f = filter subroutine
   my @outputs = (
      {l => 'File name', k => 'filename',                   },
      {l => 'File size', k => 'filesize',    u => 'byte',   },
      {l => 'Duration',  k => 'duration',    u => 'second',
       f => sub {return 'about '.($_[0]/1000);},            },  # convert millisec to sec
      {l => 'Video',     k => 'video_count', u => 'frame',  },
      {r => qr/\A video_/xms, p => q{  },                   },
      {l => 'Audio',     k => 'audio_count', u => 'packet', },
      {r => qr/\A audio_/xms, p => q{  },                   },
      {l => 'Meta',      k => 'meta_count',  u => 'event',  },
      {r => qr/\A meta_/xms,  p => q{  },                   },
   );

   # Flag keys to ignore in regex matches
   my %seen = map { $_->{k} ? ($_->{k} => 1) : () } @outputs;

   # Apply regex matches
   for my $i (reverse 0 .. $#outputs)
   {
      my $output = $outputs[$i];
      if ($output->{r})
      {
         my @r;
         for my $key (grep { $_ =~ $output->{r} } sort keys %info)
         {
            next if ($seen{$key});
            (my $label = $key) =~ s/$output->{r}//xms;
            push @r, {l => $output->{p}.$label, k => $key};
         }
         splice @outputs, $i, 1, @r;
      }
   }

   # Get the length of the longest label so we can pad the rest
   my $max_label_length = max map { length $_->{l} } @outputs;

   # Accumulate output string here
   my $out = q{};
   for my $output (@outputs)
   {
      my $value = $info{$output->{k}};
      next if (!$value);

      # Apply filter if any
      if ($output->{f})
      {
         $value = $output->{f}->($value);
      }

      # Append unit(s) if any
      if ($output->{u})
      {
         $value .= q{ } . $output->{u} . ($value eq '1' ? q{} : 's');
      }
      elsif (ref $value)
      {
         # Make multiline output for a complex data structure
         my $d = Data::Dumper->new([$value], ['VAR']);
         (my $label = $output->{l}) =~ s/\S+/  >>>/xms;
         my $varprefix = '$VAR = '; ##no critic(RequireInterpolationOfMetachars)
         # "+2" is for 2 spaces in normal output
         my $padding = q{ } x ($max_label_length +2 - length $label.$varprefix);
         $d->Pad($label . $padding);
         $value = $d->Dump();
         $value =~ s/\A\s*>>>\s*\Q$varprefix\E//xms;
         $value =~ s/;\s+\z//xms;
      }

      my $label   = $output->{l};
      my $padding = q{ } x ($max_label_length - length $label);

      $out .= "$label $padding $value\n";
   }

   return $out;
}

=item $self->get_file()

Returns the FLV::File instance.  This will be C<undef> until you call parse().

=cut

sub get_file
{
   my $self = shift;
   return $self->{file};
}

1;

__END__

=back

=head1 SEE ALSO

=over

=item FLVTool2

This is a rather nice Ruby implementation that can read and write FLV
files.  This code helped me figure out that the FLV documentation was
wrong for the order of attributes in video tags.  It also helped me
understand the meta tags.

L<http://inlet-media.de/flvtool2>

=item AMF::Perl

This is a Perl implementation of the L<http://www.amfphp.org/> project
to create an open source representation of the Flash remote
communication protocol.  This module leverages a small part of AMF::Perl to parse FLV
meta tags.

=back

=head1 COMPATIBILITY

This module should work with FLV v1.0 and FLV v1.1 files.  All other
versions will certainly fail.

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
