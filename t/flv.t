#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);
use File::Spec;
use Test::More tests => 12 + 2 * 18; # general tests + number of samples * test per sample

BEGIN
{
   use_ok('FLV::Info');
}

FLV::Base->set_verbosity(0);
#FLV::Base->set_verbosity(1);

my @samples = (
   {
      file => File::Spec->catfile('t', 'samples', 'flash6.flv'),
      expect => {
         video_codec => 'Sorenson H.263',
         duration => '7418',
         audio_format => 'MP3',
         audio_type => 'stereo',
         meta_framerate => '20',

         has_video => 1,
         has_audio => 1,
         tags => 435,
         video_tags => 149,
         audio_tags => 285,
         meta_tags => 1,
      },
   },
   {
      file => File::Spec->catfile('t', 'samples', 'flash8.flv'),
      expect => {
         video_codec => 'On2 VP6',
         duration => '7418',
         audio_format => 'MP3',
         audio_type => 'stereo',
         meta_framerate => '20',

         has_video => 1,
         has_audio => 1,
         tags => 435,
         video_tags => 149,
         audio_tags => 285,
         meta_tags => 1,
      },
   },
);

my @cleanup;

{
   my $reader = FLV::Info->new();
   eval { $reader->parse('nosuchfile.flv'); };
   like($@, qr/No such file or directory/, 'parse non-existent file');

   my ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse empty file');

   ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   print {$fh} 'foo';
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse non-flv file');

   ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   print {$fh} 'FLV';
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse non-flv file');

   ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   print {$fh} 'foo' x 1000;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Not an FLV file/, 'parse long non-flv file');

   ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCN', 200, 0, 9;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/only understand FLV version 1/, 'parse badly versioned flv header');

   ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCN', 1, 2, 9;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Reserved header flags are non-zero/, 'parse reserved-flag using flv header');

   ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCN', 1, 0, 8;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Illegal value for body offset/, 'parse too-small length flv header');

   ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   print {$fh} 'FLV'.pack 'CCNC', 1, 0, 10, 0;
   close $fh;
   eval { $reader->parse($tempfilename); };
   like($@, qr/Unexpected end of file/, 'parse long flv header');

   eval { $reader->{file}->serialize(); };
   like($@, qr/Please specify a filehandle/, 'serialize with no filehandle');

   # Expect a failure with a warning
   local $SIG{__WARN__} = sub{};
   ok(!$reader->{file}->serialize($fh), 'serialize with closed filehandle');
}

for my $sample (@samples)
{
   # Read an FLV file and check selected metadata against expectations
   my $reader = FLV::Info->new();
   ok(!scalar $reader->get_info(), 'get_info');
   $reader->parse($sample->{file});
   ok(scalar $reader->get_info(), 'get_info');
   ok($reader->report(), 'report');
   is($reader->{file}->get_filename(), $sample->{file}, 'get_filename');

   my %info = (
      $reader->get_info(),
      'tags'       => scalar $reader->{file}->{body}->get_tags(),
      'has_video'  => $reader->{file}->{header}->has_video(),
      'has_audio'  => $reader->{file}->{header}->has_audio(),
      'video_tags' => $reader->{file}->{body}->count_video_frames(),
      'audio_tags' => $reader->{file}->{body}->count_audio_packets(),
      'meta_tags'  => $reader->{file}->{body}->count_meta_tags(),
      #'end_time'   => $reader->{file}->{body}->end_time(),
   );

   #use Data::Dumper;
   #diag Dumper \%info;
   #diag Dumper [grep {$_->isa('FLV::MetaTag')} @{$reader->{file}->{body}->{tags}}];
   for my $key (sort keys %{$sample->{expect}})
   {
      is($info{$key}, $sample->{expect}->{$key}, $sample->{file}.' - '.$key);
   }

   # Write the FLV back out as a temp file
   my ($fh, $tempfilename) = tempfile();
   push @cleanup, $tempfilename;
   ok($reader->{file}->serialize($fh), 'serialize');
   close $fh;
   
   # Read the temp file back and compare it to the original -- should
   # be identical except for hash key ordering
   my $rereader = FLV::Info->new();
   $rereader->parse($tempfilename);
   # remove filename properties which are guaranteed to differ
   $reader->{file}->{filename} = undef;
   $rereader->{file}->{filename} = undef;
   is_deeply($rereader->{file}, $reader->{file}, 'compare re-serialized');
   # read it again, this time via filehandle
   open my $fh2, '<', $tempfilename or die;
   $rereader->parse($fh2);
   close $fh2;
   is_deeply($rereader->{file}, $reader->{file}, 'compare re-serialized');
}

END
{
   # Delete temp files
   unlink $_ for @cleanup;
}
