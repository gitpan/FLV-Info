#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Test::More tests => 4 + 1 * 7; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::Info');
   use_ok('FLV::FromSWF');
}

# TODO: rebuild the SWF file, because it was encoded at 22 kHz vs 11 kHz for the flv!!

my @samples = (
   {
      swffile => File::Spec->catfile('t', 'samples', 'flash6.swf'),
      flvfile => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      comparemeta => [qw(framerate audiocodecid videocodecid width height)],
   },
);

my @cleanup;

{
   my $converter = FLV::FromSWF->new();
   eval { $converter->parse_swf('nosuchfile.swf'); };
   like($@, qr/No such file or directory/, 'parse non-existent file');

   eval { $converter->save(File::Spec->catfile('nosuchdir/file.flv')); };
   like($@, qr/Failed to write FLV/, 'impossible output filename');
}

for my $sample (@samples)
{
   my $reader = FLV::Info->new();
   $reader->parse($sample->{flvfile});

   my $converter = FLV::FromSWF->new();
   $converter->parse_swf($sample->{swffile});

   # Write the FLV back out as a temp file
   my ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   close $fh;
   $converter->save($tempfilename);

   my $rereader = FLV::Info->new();
   $rereader->parse($tempfilename);

   for my $key (@{$sample->{comparemeta}})
   {
      is($rereader->{file}->get_meta($key), $reader->{file}->get_meta($key), 'meta '.$key);
   }

   is($rereader->{file}->{body}->count_video_frames(), $reader->{file}->{body}->count_video_frames(), 'video frames');
   #is($rereader->{file}->{body}->count_audio_packets(), $reader->{file}->{body}->count_audio_packets(), 'audio packets');
   is($rereader->{file}->{body}->count_meta_tags(), $reader->{file}->{body}->count_meta_tags(), 'meta tags');

#    # remove properties which are guaranteed to differ
#    for my $r ($reader, $rereader)
#    {
#       my $meta = $r->{file}->{body}->{tags}->[0]->{data}->[1];
#       for my $key (qw(videodatarate audiodatarate duration creationdate audiodelay))
#       {
#          delete $meta->{$key};
#       }
#       @{$r->{file}->{body}->{tags}}
#          = sort {$a->{start} <=> $b->{start} || (ref $a) cmp (ref $b)}
#            @{$r->{file}->{body}->{tags}};
# 
#       delete $_->{data} for @{$r->{file}->{body}->{tags}};
# 
#       $r->{file}->{filename} = undef;
#    }
# 
#    shift @{$reader->{file}->{body}->{tags}};
# 
#    use File::Slurp;use Data::Dumper;
#    write_file 't1', Dumper $reader->{file};
#    write_file 't2', Dumper $rereader->{file};
# 
#    is_deeply($rereader->{file}, $reader->{file}, 'compare');
}

END
{
   # Delete temp files
   unlink $_ for @cleanup;
}
