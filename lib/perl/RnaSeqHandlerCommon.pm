package RnaSeqHandlerCommon;

use strict;
use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw($MANIFEST_FILE $VALIDATION_ERR_CODE readAndValidateManifestLine validationError);

# constants
our $MANIFEST_FILE = 'manifest.txt';
our $VALIDATION_ERR_CODE = 1;

my @VALID_STRAND_TYPES = ('unstranded', 'sense', 'antisense', 'firststrand', 'secondstrand');

sub readAndValidateManifestLine {
  my ($fh, $dataFilesDir) = @_;

  #skip blank lines
  my $line;
  do {
    $line = <$fh>;
    return () unless $line;
    chomp $line;
  } while (!$line);

  my @line = split(/\t/, $line);

  validationError("Invalid manifest file.  Wrong number of columns: '$line'\n")
    unless scalar(@line) == 3;

  my ($sampleName, $filename, $strandInfo) = @line;

  validationError("Invalid manifest file third column value '$strandInfo'.  Must be one of: " . join(', ', @VALID_STRAND_TYPES))
      unless grep( /^$line[2]$/, @VALID_STRAND_TYPES );
  my $path = "$dataFilesDir/$filename";

  validationError("File in manifest does not exist: '$dataFilesDir/$filename'") unless -e $path;

  return @line;
}

sub validationError {
  my ($msg) = @_;

  print STDOUT "$msg\n";
  exit($VALIDATION_ERR_CODE);
}


1;
