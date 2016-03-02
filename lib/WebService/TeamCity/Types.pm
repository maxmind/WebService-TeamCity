package WebService::TeamCity::Types;

use strict;
use warnings;

use Type::Library
    -base,
    -declare => qw( BuildStatus TestStatus );
use Type::Utils qw( enum );

enum BuildStatus, [qw( SUCCESS FAILURE ERROR UNKNOWN )];

enum TestStatus, [qw( SUCCESS FAILURE UNKNOWN )];

1;
