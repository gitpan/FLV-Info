#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Digest::MD5 qw(md5_hex);
use Test::More tests => 5 + 2 * 1; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::ToMP3');
}

my @samples = (
   {
      flvfile => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      outsize => 119118,
   },
   {
      flvfile => File::Spec->catfile('t', 'samples', 'flash8.flv'),
      outsize => 119118,
   },
);

my @cleanup;

{
   my $converter = FLV::ToMP3->new();
   eval { $converter->parse_flv('nosuchfile.flv'); };
   like($@, qr/No such file or directory/, 'ToMP3 parse non-existent file');

   eval { $converter->save(File::Spec->catfile('nosuchdir/file.mp3')); };
   like($@, qr/No audio data/, 'ToMP3 empty FLV');

   $converter->{flv}->set_meta(audiocodecid => 0); # hack
   eval { $converter->save(File::Spec->catfile('nosuchdir/file.mp3')); };
   like($@, qr/Audio format uncompressed not supported/, 'ToMP3 wrong audio format');

   $converter->{flv}->set_meta(audiocodecid => 2); # hack
   eval { $converter->save(File::Spec->catfile('nosuchdir/file.mp3')); };
   like($@, qr/No such file or directory/, 'ToMP3 impossible output filename');
}

for my $sample (@samples)
{
   my $converter = FLV::ToMP3->new();
   $converter->parse_flv($sample->{flvfile});
   # Write the MP3 back out as a temp file
   my ($fh, $tempmp3) = tempfile();
   push @cleanup, $tempmp3;
   close $fh;
   $converter->save($tempmp3);

   is(-s $tempmp3, $sample->{outsize}, 'save mp3 file');
}


END
{
   # Delete temp files
   unlink $_ for @cleanup;
}
