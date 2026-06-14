package BigWigUtils;

use strict;
use Exporter;
use File::Copy;
use File::Basename;
our @ISA = 'Exporter';
our @EXPORT = qw(installBwFile);

sub installBwFile {
  my ($bwFile, $dataFilesDir) = @_;


  print STDERR "Copying file '$bwFile' to '$dataFilesDir'\n";
  copy($bwFile, $dataFilesDir) or die "Copy of '$bwFile' to '$dataFilesDir' failed: $!";
  my $f = basename($bwFile);
  chmod(0664, "$dataFilesDir/$f") or die "Could not chmod $dataFilesDir/$f\n";
}


1;
