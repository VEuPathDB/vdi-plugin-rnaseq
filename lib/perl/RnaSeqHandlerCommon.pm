package RnaSeqHandlerCommon;

use strict;
use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw($MANIFEST_FILE $VALIDATION_ERR_CODE @VALID_STRAND_TYPES readAndValidateManifestLine validationError);

# constants
my $MANIFEST_FILE = 'manifest.txt';
my $VALIDATION_ERR_CODE = 1;
my @VALID_STRAND_TYPES = ('unstranded', 'sense', 'antisense');

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

  validationError("Invalid manifest file third column value '$strandInfo'.  Must be 'unstranded', 'sense' or 'antisense'")
    unless grep( /^$line[2]$/, @VALID_STRAND_TYPES );

  validationError("File in manifest does not exist: '$filename'") unless -e "$dataFilesDir/$filename";

  return @line;
}

sub validationError {
  my ($msg) = @_;

  print STDOUT "$msg\n";
  exit($VALIDATION_ERR_CODE);
}


1;
