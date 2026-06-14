package DbiBatchExecutor;

use strict;
use DBI;
use DBI qw(:sql_types);

=pod

A class that makes it easy to call DBI's execute_array to do batch inserts or updates

batchSize:  how many rows will be included in the array that is submitted
commitSize: how many rows will be included in a commit

=cut

sub new {
  my ($class, $batchSize, $commitSize) = @_;
  my $self = {
	      batchSize=> $batchSize,
	      commitSize => $commitSize,
	      batchCount => 0,
	      commitCount => 0,
	      batchNum => 0
	     };

  bless($self, $class);
  return $self;
}

=pod

Call this method once per row that you want to insert or update.  It will periodically
call execute_array (based on batchSize) and commit (based on commitSize).

dbh: a connection handle, used to call commit
sth: a statement handle that has a prepared statement with one or more bind variables
finalBatch: a 0/1 flag.  1 means that this is the final batch.  do an execute and commit unconditionally
paramTypes:  an array ref indicating the type of each of the data arrays
arrayRefs: one or more references to parallel arrays, one per bind variable.  these contain the growing
           set of rows to submit in the batch.  THESE ARRAYS ARE EMPTIED AUTOMATICALLY ON EXECUTE.

to discover supported SQL types for your driver, do this:
% perl -e 'use DBI qw(:sql_types); foreach (@{ $DBI::EXPORT_TAGS{sql_types} }) { printf "%s=%d\n", $_, &{"DBI::$_"}; }'

does not close the statement or connection.


Sample calling code:

use DBI qw(:sql_types);
my $batchExecutor = new  DbiBatchExecutor(100, 1000);
my @udIdArray;
my @geneIdArray;
while(<F>) {
  chomp;
  push(@udIdArray, $userDatasetId);
  push(@geneIdArray, $_);
  $batchExecutor->periodicallyExecuteBatch($sth, 0, [SQL_INTEGER, SQL_VARCHAR], \@udIdArray, \@geneIdArray);
}
$batchExecutor->periodicallyExecuteBatch($sth, 1, [SQL_INTEGER, SQL_VARCHAR], \@udIdArray, \@geneIdArray);

=cut

sub periodicallyExecuteBatch {
  my ($self, $dbh, $sth, $finalBatch, $paramTypes, @arrayRefs) = @_;

  die "paramTypes and arrayRefs must have the same number of elements\n" if scalar(@$paramTypes) != scalar(@arrayRefs);

  $self->{batchCount}++;  # count of rows so far in this batch
  $self->{commitCount}++; # count of rows so far in this commit
  $self->{rowNum}++;      # total number of rows processed
  if ($self->{batchCount} == $self->{batchSize} || $finalBatch) {
    for (my $i=0; $i<scalar(@arrayRefs); $i++) {
      $sth->bind_param_array($i+1, @arrayRefs[$i], $paramTypes->[$i]);
    }

    # Temporarily disable RaiseError so execute_array populates ArrayTupleStatus
    my $old_raise_error = $dbh->{RaiseError};
    $dbh->{RaiseError} = 0;
    $sth->{RaiseError} = 0;

    my $executeCount = $sth->execute_array({ ArrayTupleStatus => \my @tuple_status });

    # Restore RaiseError
    $dbh->{RaiseError} = $old_raise_error;

    # Check for errors - report only the first/causative error
    for (my $i = 0; $i < @tuple_status; $i++) {
      my $status = $tuple_status[$i];
      if (ref($status) eq 'ARRAY') {
        # Found the first error that caused transaction abort
        my ($err_code, $err_string) = @$status;
        my $absoluteRow = $self->{rowNum} - $self->{batchCount} + $i + 1;
        my @rowValues;
        for my $arrayRef (@arrayRefs) {
          push @rowValues, defined($arrayRef->[$i]) ? $arrayRef->[$i] : 'NULL';
        }
        die sprintf("Batch execution failed at row %d:\n[Error %s] %s\nData values: [%s]\n",
                    $absoluteRow, $err_code // 'unknown', $err_string // 'unknown error',
                    join(", ", @rowValues));
      }
    }

    $self->{batchCount} = 0;
    for my $arrayRef (@arrayRefs) {  # empty the provided arrays
      @$arrayRef = ();
    }
  }
  if ($self->{commitCount} == $self->{commitSize} || $finalBatch) {
    $dbh->commit();
    $self->{commitCount} = 0;
  }
}

1;

