use inc::Module::Install;

name 'Finance-FINRA-File-PostBranchIndividualReport';
license 'perl';
all_from 'lib/Finance/FINRA/File/PostBranchIndividualReport.pm';

requires 'Moose';
requires 'XML::LibXML';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::Path::Class';

build_requires 'FindBin';
build_requires 'Path::Class';
build_requires 'Test::More';
build_requires 'Test::Exception';

WriteAll;
