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

  validationError("Invalid manifest file.  Wrong number of columns. Must be tab delimited, with these columns: sample name, counts file, 'stranded'(optional), bigwig file (optional).\n '$line'")
    unless scalar(@line) >= 2 || scalar(@line) <= 4;  # third column for now must be 'stranded', so it is optional

  my ($sampleName, $filename, $strandInfo, $bwFile) = @line;

  my $sampleName = $line[0];
  my $bwFile;
  my $strandInfo;
  my $countFile;

  # support legacy format where bw file is in 2nd column
  if ($line[1] =~ /\.bw$|\.bigwig/) {
    validationError("Invalid line in manifest file. Has more than one bigwig file. \n '$line'")
      if ($line[2] =~ /\.bw$|\.bigwig/ || $line[3] =~ /\.bw$|\.bigwig/);
    validationError("Invalid line in manifest file. If bigwig file in second column, fourth column not allowed.\n '$line'")
      if $line[3];
    $bwFile = $line[1];
    $strandInfo = $line[2];
  }
  # strand column omitted
  elsif ($line[2] =~ /\.bw$|\.bigwig/){
    $countFile = $line[1];
    $bwFile = $line[2];
  } else {
    $countFile = $line[1];
    $strandInfo = $line[2];
    validationError("Invalid line in manifest file.  Fourth column must be .bw or .bigwig file\n '$line'")
      if ($line[3] && $line[3] !~ /\.bw$|\.bigwig/);
    $bwFile = $line[3];
  }

  $strandInfo = 'unstranded' unless $strandInfo;

  validationError("Invalid line in manifest file.  Strandedness must be: " . join(', ', @VALID_STRAND_TYPES) . "\n '$line'")
      unless grep( /^$strandInfo$/, @VALID_STRAND_TYPES );

  print STDERR "sample: '$sampleName' countFile: '$countFile' strand: '$strandInfo' bwFile: '$bwFile' \n\n";

  my $path = "$dataFilesDir/$countFile";
  validationError("Counts file in manifest does not exist: '$countFile'")
    unless !$countFile || -e "$dataFilesDir/$countFile";
  validationError("Bigwig file in manifest does not exist: '$bwFile'")
    unless !$bwFile || -e "$dataFilesDir/$bwFile";

  return ($sampleName, $countFile, $strandInfo, $bwFile);
}

sub validationError {
  my ($msg) = @_;

  print STDOUT "$msg\n";
  exit($VALIDATION_ERROR_CODE);
}


1;
