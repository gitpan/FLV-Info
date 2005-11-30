#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);

BEGIN
{
   use Test::More tests => 1;
   use_ok('FLV::Info');
}
