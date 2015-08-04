package db;

use DBI;
use Exporter ();
our @EXPORT;
@EXPORT = qw(query query_hashref first_field first_hashref count execute insert insertid);

my $dbh;

sub query($;@)
{
	my ($query, @params) = @_;
	my $sth = $dbh->prepare($query);
	$sth->execute(@params);
	my $result = $sth->fetchall_arrayref;
	$sth->finish;
	return @{$result};
}

sub query_hashref($;@)
{
	my ($query, @params) = @_;
	my $sth = $dbh->prepare($query);
	$sth->execute(@params);
	my @result;
	while (my $hashref = $sth->fetchrow_hashref) {
		push @result, $hashref;
	}
	$sth->finish;
	return @result;
}

sub first_field($;@)
{
	my ($query, @params) = @_;
	my @result = query($query, @params);
	return $result[0]->[0] if (@result);
	return undef;
}

sub first_hashref($;@)
{
	my ($query, @params) = @_;
	my $sth = $dbh->prepare($query);
	$sth->execute(@params);
	my $result = $sth->fetchrow_hashref;
	$sth->finish;
	return $result;
}

sub count($;@)
{
	my ($query, @params) = @_;
	my @result = query($query, @params);
	return scalar @result;
}

sub execute($;@)
{
	my ($query, @params) = @_;
	my $sth = $dbh->prepare($query);
	$sth->execute(@params);
	$sth->finish;
}

sub insert($$)
{
	my ($table, $hashref) = @_;
	my $query = "INSERT INTO $table SET ";
	my @keys;
	my @values;
	while (my ($key, $value) = each %$hashref) {
		push @keys, "$key = ?";
		push @values, $value;
	}
	$query .= join(', ', @keys);
	execute($query, @values);
	return ($dbh->{insertid});
}

sub insertid()
{
	return ($dbh->{insertid});
}

BEGIN
{
	$dbh = DBI->connect("dbi:mysql:bias", "USERNAME", "PASSWORD") or die $DBI::errstr;
}		

END
{
	$dbh->disconnect;
}
				
1;
