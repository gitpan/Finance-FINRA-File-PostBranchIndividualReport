#!/usr/bin/perl -w

use strict;
use warnings;
use Path::Class qw(dir);
use FindBin qw($Bin);
use Test::More tests => 5;
use Test::Exception;

use_ok('Finance::FINRA::File::PostBranchIndividualReport');

my $xml_file = dir($Bin)->subdir('var')->file('test.xml');
my $report = Finance::FINRA::File::PostBranchIndividualReport->new(
  file => $xml_file
);

lives_ok {
  $report->dom;
} 'dom build ok';

is($report->firm_crd_number, '12345', 'firm crd number');
is($report->posting_date->ymd('-'), '2009-01-06', 'posting date');
my $target =  [
  {
    'district_code' => '11BO',
    'crd_number' => '123456',
    'names' => [
      'LOLITA & CO. INVESTMENTS, LLC',
      'Humbert & Humbert. INVESTMENTS, LLC'
    ],
    'billing_code' => 'BERRY',
    'operational_status_code' => 'ACTV',
    'individuals' => [],
    'address' => {
      'country' => 'USA'
    },
    'individual' => [
      {
        'first' => 'DOLORES',
        'crd_number' => '1234567',
        'last' => 'HAZE',
        'independent_contractor_flag' => 1,
        'supervisor_flag' => 1
      }
    ]
  },
  {
    'district_code' => '9PH',
    'crd_number' => '234567',
    'names' => [
      'FOO & BAR LLC'
    ],
    'billing_code' => 'BLUE',
    'operational_status_code' => 'ACTV',
    'individuals' => [],
    'address' => {
      'city' => 'WILLIAMSBURG'
    },
    'individual' => [
      {
        'first' => 'JOHN',
        'crd_number' => '2345678',
        'last' => 'BAR',
        'independent_contractor_flag' => 1,
        'supervisor_flag' => 0
      },
      {
        'middle' => 'HENRY',
        'first' => 'JACK',
        'crd_number' => '3456789',
        'suffix' => 'Jr',
        'last' => 'FOO',
        'independent_contractor_flag' => 1,
        'supervisor_flag' => 1
      }
    ]
  }
];

is_deeply($report->records, $target, 'records');
