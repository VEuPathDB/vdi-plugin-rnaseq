package RnaSeqHandlerCommon;

use strict;
use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw($MANIFEST_FILE $VALIDATION_ERROR_CODE readAndValidateManifestLine validationError);

# constants
our $MANIFEST_FILE = 'manifest.txt';
our $VALIDATION_ERROR_CODE = 99;

#my @VALID_STRAND_TYPES = ('unstranded', 'sense', 'antisense', 'firststrand', 'secondstrand');
my @VALID_STRAND_TYPES = ('unstranded'); # only support unstranded for now.

sub readAndValidateManifestLine {
  my ($fh, $dataFilesDir) = @_;  

  #skip blank lines
  my $line;
  do {
    $line = <$fh>;
    return () unless $line;
    chomp $line;
    print STDERR "manifest file line: '$line'\n";
  } while (!$line);

  my @line = split(/\t/, $line);

  validationError("Invalid manifest file.  Wrong number of columns: '$line'. Must be two columns, tab delimited.")
    unless scalar(@line) == 2 || scalar(@line) == 3;  # third column for now must be 'stranded', so it is optional

  my ($sampleName, $filename, $strandInfo) = @line;

  $strandInfo = 'unstranded' unless $strandInfo;

  validationError("Invalid manifest file third column value '$strandInfo'.  Must be: " . join(', ', @VALID_STRAND_TYPES))
      unless grep( /^$strandInfo$/, @VALID_STRAND_TYPES );
  my $path = "$dataFilesDir/$filename";

  print STDERR "sample: $sampleName filepath: $path strand: $strandInfo\n";

  validationError("File in manifest does not exist: '$path'") unless -e $path;

  return @line;
}

sub validationError {
  my ($msg) = @_;

  print STDOUT "$msg\n";
  exit($VALIDATION_ERROR_CODE);
}


1;
