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
  my ($class, $batchSize, $commitSize, $platform) = @_;

  # Default to Oracle for backward compatibility if platform not provided
  $platform = 'Oracle' unless $platform;

  my $self = {
	      batchSize=> $batchSize,
	      commitSize => $commitSize,
	      platform => $platform,
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

  my $platform = $self->{platform};

  if ($platform ne 'Oracle') {
    return $self->periodicallyExecuteBatchPostgres($dbh, $sth, $finalBatch, $paramTypes, @arrayRefs);
  } else {
    return $self->periodicallyExecuteBatchOracle($dbh, $sth, $finalBatch, $paramTypes, @arrayRefs);
  }
}

sub periodicallyExecuteBatchOracle {
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

sub periodicallyExecuteBatchPostgres {
  my ($self, $dbh, $sth, $finalBatch, $paramTypes, @arrayRefs) = @_;

  die "paramTypes and arrayRefs must have the same number of elements\n" if scalar(@$paramTypes) != scalar(@arrayRefs);

  $self->{batchCount}++;  # count of rows so far in this batch
  $self->{commitCount}++; # count of rows so far in this commit
  $self->{rowNum}++;      # total number of rows processed

  if ($self->{batchCount} == $self->{batchSize} || $finalBatch) {
    my $numRows = scalar(@{$arrayRefs[0]});
    return unless $numRows > 0;  # nothing to insert

    # Get the original SQL from the prepared statement
    my $originalSql = $sth->{Statement};

    # Parse the SQL to extract INSERT...INTO clause and VALUES clause
    # Expected format: INSERT INTO table (cols) VALUES (placeholders)
    if ($originalSql =~ /^(.+?\bVALUES\s+)(\(.+?\))\s*$/is) {
      my $insertPart = $1;  # "INSERT INTO table (cols) VALUES "
      my $valuesPart = $2;  # "(val1, ?, ?)"

      # Build multi-row VALUES clause
      my @valuesClause = ($valuesPart) x $numRows;
      my $multiValueSql = $insertPart . join(",\n  ", @valuesClause);

      # Prepare the multi-value statement
      my $multiSth = $dbh->prepare($multiValueSql);

      # Bind all parameters in order: row1_col1, row1_col2, row2_col1, row2_col2, ...
      my $paramIndex = 1;
      for (my $row = 0; $row < $numRows; $row++) {
        for (my $col = 0; $col < scalar(@arrayRefs); $col++) {
          $multiSth->bind_param($paramIndex, $arrayRefs[$col]->[$row], $paramTypes->[$col]);
          $paramIndex++;
        }
      }

      # Execute the multi-value insert
      print STDERR "start exec (Postgres multi-value: $numRows rows) " . localtime . "\n";
      eval {
        $multiSth->execute();
      };
      if ($@) {
        my $err = $@;
        print STDERR "end exec (FAILED) " . localtime . "\n";
        die "Batch execution failed: $err\n";
      }
      print STDERR "end exec (Postgres multi-value) " . localtime . "\n";

      $multiSth->finish();
    } else {
      die "Could not parse SQL statement for multi-value INSERT: $originalSql\n";
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

