package Finance::FINRA::File::PostBranchIndividualReport;

use Moose;
use XML::LibXML;
use MooseX::Types::DateTime qw(DateTime);
use MooseX::Types::Path::Class qw(File);

our $VERSION = '0.001000';

has file => (is => 'ro', isa => File, required => 1, coerce => 1);
has dom => (is => 'ro', isa => 'XML::LibXML::Node', lazy_build => 1);
has records => (is => 'ro', isa => 'ArrayRef', lazy_build => 1);
has firm_crd_number => (is => 'ro', isa => 'Str', lazy_build => 1);
has posting_date => (is => 'ro', isa => DateTime, coerce => 1, lazy_build => 1);

our %street_code_map = (
  strt1 => 'street1',
  strt2 => 'street2',
  city => 'city',
  state => 'state',
  cntry => 'country',
  postlCd => 'postal_code',
);

sub _build_dom {
  return XML::LibXML->new->parse_file(shift->file);
}

sub _build_firm_crd_number {
  my ($report) = shift->dom->getElementsByTagName('PostBranchIndividualReport');
  my ($criteria) = $report->getChildrenByTagName('Criteria');
  return $criteria->getAttribute('firmCRDNumber');
}

sub _build_posting_date {
  my ($report) = shift->dom->getElementsByTagName('PostBranchIndividualReport');
  my ($criteria) = $report->getChildrenByTagName('Criteria');
  my @ymd = split('-', $criteria->getAttribute('postingDate'));
  return { year => $ymd[0], month => $ymd[1], day => $ymd[2]};
}


sub _build_records {
  my $self = shift;
  my ($report) = $self->dom->getElementsByTagName('PostBranchIndividualReport');
  my ($office_records) = $report->getChildrenByTagName('BrnchOfcs')
    ->get_nodelist;

  my @branches;
  for my $bo ( $office_records->getChildrenByTagName('BrnchOfc') ) {
    my $branch = {
      crd_number => $bo->getAttribute('brnchPK'),
      operational_status_code => $bo->getAttribute('oprnlStCd'),
      address => {},
    };
    #optional fields
    $branch->{nyse_branch_code_number} = $bo->getAttribute('NYSEBrnchCdNb')
      if $bo->hasAttribute('NYSEBrnchCdNb');
    $branch->{billing_code} = $bo->getAttribute('bllngCd')
      if $bo->hasAttribute('bllngCd');
    $branch->{district_code} = $bo->getAttribute('dstrtPK')
      if $bo->hasAttribute('dstrtPK');

    my ($addr) = $bo->getChildrenByTagName('Addr');
    for( my($xml_key, $our_key) = each(%street_code_map) ){
      next unless $addr->hasAttribute($xml_key);
      $branch->{address}->{$our_key} = $addr->getAttribute($xml_key);
    }

    $branch->{names} ||= [];
    my ($other_names) = $bo->getChildrenByTagName('OthrNms');
    for my $other_name ($other_names->getChildrenByTagName('OthrNm')){
      push(@{$branch->{names}}, $other_name->getAttribute('Nm'));
    }

    $branch->{individuals} ||= [];
    my ($asctds) = $bo->getChildrenByTagName('AsctdIndvls');
    for my $asctd ( $asctds->getChildrenByTagName('AsctdIndvl')){
      my $individual = {
        crd_number => $asctd->getAttribute('indvlPK'),
        supervisor_flag => ($asctd->getAttribute('sprvPICFl') eq 'Y' ? 1 : 0)
      };
      push(@{ $branch->{individual} }, $individual);
      $individual->{independent_contractor_flag} =
        ( $asctd->getAttribute('ndpndCntrcrFl') eq 'Y' ? 1 : 0 )
          if $asctd->hasAttribute('ndpndCntrcrFl');

      my ($ind_name) = $asctd->getChildrenByTagName('Nm');
      $individual->{first} = $ind_name->getAttribute('first')
        if $ind_name->hasAttribute('first');
      $individual->{last} = $ind_name->getAttribute('last')
        if $ind_name->hasAttribute('last');
      $individual->{middle} = $ind_name->getAttribute('mid')
        if $ind_name->hasAttribute('mid');
      $individual->{suffix} = $ind_name->getAttribute('suf')
        if $ind_name->hasAttribute('suf');
    }
    push(@branches, $branch);
  }

  return \@branches;
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Finance::FINRA::File::PostBranchIndividualReport - Parse the Branch CRD Report

=head1 DESCRIPTION

C<Finance::FINRA::File::PostBranchIndividualReport> is a set of tools designed
for interacting with the FINRA CRD BatchFiling and Data Download transfer
individual branch file.

=head1 SYNOPSIS

    use Finance::FINRA::File::PostBranchIndividualReport;
    my $report = Finance::FINRA::File::PostBranchIndividualReport->new(
      file => 'report.xml'
    );
    $report->firm_crd_number;
    $report->posting_date;
    for my $branch ( @{ $report->records } ) {
       ...
    }

=head1 ATTRIBUTES

=head2 file

A required, read-only, coercing L<Path::Class::File> object. This should be
either a L<Path::Class:File> instance or a string pointing to the XML file.

=head2 dom

A private, read-only, lazy-building L<XML::LibXML::Node> representing the
root Node of the file.

=head2 records

A read-only, lazy-building array reference with holding the branch records.
Refer to the record description below.

=head2 firm_crd_number

A read-only, lazy-building string. The unique CRD number of the requesting firm.

=head2 posting_date

A read-only, lazy-building L<DateTime> object of the date the file was posted.

=head1 METHODS

=head2 new file => $file_name

Create a new instance.

=head2 meta

See L<Moose::Meta::Class>

=head1 RECORD DESCRIPTION

=head2 branch

An hash reference representing the branch and it's members.

=over 4

=item B<crd_number:> The Branch's unique CRD Number Required.

=item B<operational_status_code:> Required.

=item B<address:> Required, see address record description

=item B<individuals:> Required, Array ref of "individual" records
see "individual" record description.

=item B<names:> Required, An array reference of the different names the branch
is known as.

=item B<nyse_branch_code_number:> Optional

=item B<billing_code:> Optional

=item B<district_code:> Optional

=back

=head2 address

=over 4

=item B<street1:> Optional.

=item B<street2:> Optional.

=item B<city:> Optional.

=item B<state:> Optional.

=item B<postal_code:> Optional.

=item B<country:> Optional.

=back

=head2 individual

=over 4

=item B<crd_number:> Required

=item B<supervisor_flag:> Required, zero or one.

=item B<independent_contactor_flag:> Optional, zero or one.

=item B<first:> Optional.

=item B<last:> Optional.

=item B<middle:> Optional.

=item B<suffic:> Optional.

=back

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COMMERCIAL SUPPORT AND FEATURE / ENHANCEMENT REQUESTS

This software is developed as free software and is distributed free of charge,
but if you or your organization would like to contribute to the further
development, maintenance and QA of this project we ask that you sponsor the
development of one ore more of these areas. Please contact groditi@cantella.com
for more information.

Commercial support and sponsored development are available for this project
through Cantella & Co., Inc. If you or your organization would like to use this
package and need help customising it or new functionality added please
contact groditi@cantella.com or jlanstein@cantella.com for rates.

=head1 BUGS AND CONTRIBUTIONS

Google Code Project Page - L<http://code.google.com/p/finance-finra-files/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Cantella & Co., Inc. ( http://www.cantella.com/ )

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself

=cut
