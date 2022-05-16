#######################################################################
#
# uber_date.pl
#
# A date calculator
#
# Author: Mike Stollery - mike@stollery.co.uk
#
# To use this from a command line script:
#
#   #!/usr/bin/perl
#   # dateman.pl
#   require "uber_date.pl";
#   my $result = date_manip(@ARGV);
#   print qq($result
#   );
#   exit(0);
#
#######################################################################

# Useful globals - for use by client
@DayList = ("Sunday", "Monday", "Tuesday", "Wednesday",
            "Thursday", "Friday", "Saturday");
@MonthList = ("January", "February", "March", "April", "May",
              "June", "July", "August", "September",
              "October", "November", "December"); 
($Sec, $Min, $Hour, $Mday, $Mon, $Year, $Wday, $Yday, $Isdst);
$DayOfWeek;
$Month;
$Mon;
$Year;
$YYYYMMDD;
$HHMMSS;
$Julian;
$TimeInSeconds;

reset_date_time();

#######################################################################
#
# Set globals to the date and time now

sub reset_date_time
{
    $TimeInSeconds = time + $UBERENV{TIME_ZONE_OFFSET};

    ($Sec, $Min, $Hour, $Mday, $Mon, $Year, $Wday, $Yday, $Isdst) =
        gmtime($TimeInSeconds);
    $DayOfWeek = $DayList[$Wday];
    $Month = $MonthList[$Mon];
    $Mon += 1;                  # (0..11) --> (1..12)
    $Year += 1900;

    $YYYYMMDD = sprintf ("%04d%02D%02d", $Year, $Mon, $Mday);
    $Julian = toJulian($YYYYMMDD);
    $HHMMSS = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
}

#######################################################################
 
sub ProgInfo                    # Error handling functions
{
    @progPath  = split('/', $0);
    $progName  = $progPath[$#progPath];
    $progUsage ="USAGE:\
$progName [-fFORMAT] [-dDAYS] [-wWEEKS] [-nNEXT] [-m] [-s] [-j] [YYYYMMDD]\
$progName -c YYYYMMDD [YYYYMMDD]\
$progName -h";
}
 
sub Abort                       # User error
{
    ProgInfo;
    print STDERR "$progName: @_\n";
    print STDERR "$progUsage\n";
    exit (1);
}
 
sub Error                       # System or application error
{
    ProgInfo;
    print STDERR "$progName: @_\n";
    print STDERR "Fatal error.\n";
    exit (1);
}
 

#######################################################################

sub manual
{
    ProgInfo;
    print <<EOF;

"$progName"  -  A date manipulation program

Takes as input a date in the format YYYYMMDD, performs arithmetic
operations on it according to supplied options and returns the
resulting date in the same format.
If an input date is not supplied, today's date is used by default.

$progUsage

OPTIONS:
-d  Adds a given number of days to the date.

-w  Adds a given number of weeks to the date.

-n  Jumps forward to the next date of a given day.
    The day can be given in upper or lower case and need only match
    a day's name in the first 2 letters.  E.g. a jump to next Tuesday
    can made with -nTuesday, -nTUES or -ntu etc.

-l  Jumps to last day of current month.

-f  Formats the resulting date (see below)

-c  Returns the number of days between 2 given dates.
    If the second date is not supplied, today's date is used by default.

-h  Help.

-s  In addition to the resulting date, the day of the week on which
    it falls is output.
    [Deprecated: equivalent to -fYYYYMMDD_DAYOFWEEK]

-j  The resulting date is output as a Julian date instead of YYYYMMDD.
    [Deprecated: equivalent to -fJULIAN]

EXAMPLES:
$progName                      # today
$progName -d-1                 # yesterday
$progName -d1                  # tomorrow
$progName -w-1                 # this time last week
$progName -w2 -d-3             # two weeks in the future minus 3 days
$progName -nSAT                # next saturday
$progName -s                   # today's date and day of week
$progName -d30 19980226        # 30 days after 26th Feb 1998
$progName -c 19620923 19640118 # number of days between 2 dates
$progName -c 19620923          # number of days since 23rd Sept 1962

Valid formats:
-fDD-MM-YYYY                   # 18-08-1999
-fD/M/YY                       # 18/8/99
-fDD_MON_YYYY                  # 18 Aug 1999
-fDOW_DD_MON_YYYY              # Wed 18 Aug 1999
-fDAYOFWEEK_DD_MONTH_YYYY      # Wednesday 18 August 1999
-fJULIAN                       # 2451409
EOF
}

#######################################################################

sub dayOfWeekNumber        # Gets day-of-week number from a day's name
                           # e.g. TUES ==> 2
{
    my $day = lc substr shift(@_), 0, 2;
    
    for ($i = 0; $i < @DayList; $i++)
    {
        $dow = lc substr $DayList[$i], 0, 2;

        if ($day eq $dow)
        {
            return $i;   # Days are numbered 0..6
        }
    }
    return -1;   # no match
}
 
#######################################################################
 
sub dayOfWeekNumberJulian  # Gets day-of-week number from a Julian date
{
    my $dow = shift(@_);
 
    return ($dow + 1) % 7;
}


#######################################################################

sub toJulian                # Converts a YYYYMMDD date to a Julian date
{
    my $yyyymmdd = shift(@_);
    my $yyyy = substr ($yyyymmdd, 0, 4);
    my $mm   = substr ($yyyymmdd, 4, 2);
    my $dd   = substr ($yyyymmdd, 6, 2);

    if ($mm > 2)
    {
        $mm -= 3;   # wash out the leap year
    }
    else
    {
        $mm += 9;
        $yyyy--;
    }

    my $c = int $yyyy / 100;
    my $ya = $yyyy - 100*$c;
    my $ja = int ((146097*$c)>>2);
    my $jb = int ((1461*$ya)>>2);
    my $jc = int ((153*$mm + 2)/5);
    $j = $ja + $jb + $jc + $dd + 1721119;

    return $j;
}

#######################################################################


sub fromJulian              # Converts a Julian date to a YYYYMMDD date
{
    my $julian = shift(@_);
    my $j = $julian - 1721119;
    my $y = int ((($j<<2) - 1) / 146097);
       $j = int (($j<<2) - 1 - 146097*$y);
    my $d = int ($j>>2);
       $j = int ((($d<<2) + 3) / 1461);
       $d = int (($d<<2) + 3 - 1461*$j);
       $d = int (($d + 4)>>2);
       $m = int ((5*$d - 3)/153);
       $d = int (5*$d - 3 - 153*$m);
       $d = int (($d + 5)/5);
       $y = int (100*$y + $j);

    if ($m < 10)
    {
        $m += 3;
    }
    else
    {
        $m -= 9;
        $y++;
    }

    $yyyymmdd = sprintf "%04d%02d%02d", $y, $m, $d;

    return $yyyymmdd;
}


#######################################################################

sub validJulian             # Converts a YYYYMMDD date to a Julian date
{                           # and validates it
    my $yyyymmdd = shift(@_);
    my $julian = toJulian $yyyymmdd;
    my $checkDate = fromJulian $julian;

    if ($yyyymmdd == $checkDate)
    {
        return $julian;
    }
    else
    {
#        Abort "Invalid date - $yyyymmdd";
        return "INVALID_DATE";
    }
}

#######################################################################

sub todaysDate              # Gets today's date in YYYYMMDD format
{
    reset_date_time();
    return($YYYYMMDD);
}

#######################################################################

sub zz_todaysDate              # Gets today's date in YYYYMMDD format
{
    my $century = 19;                                # Boo!
    my $year  = (localtime)[5] + (100 * $century);
    my $month = (localtime)[4] + 1;
    my $mday  = (localtime)[3];
    my $today = sprintf "%04d%02d%02d", $year, $month, $mday;
    return $today;
}
 
#######################################################################

sub date_manip
{
    my @args = @_;
    my $output = "";
    my @flagList = ();
    my @dateList = ();
    my $numFlags = 0;
    my $numDates = 0;
    my $showDay = 0;
    my $showJulian = 0;
    my $format = "";

    push(@args, todaysDate()) if (scalar(@args) < 1);

    while (<@args>)             # Parse the command line
    {
        if (/^-/)                                             # It's a flag
        {
            push (@flagList, $_);
    
            if (scalar(@dateList) > 0) # Flags are not permitted after dates
            {
                Abort "Invalid usage.";
            }
        }
        elsif (/^[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]$/)  # It's a date
        {
            push (@dateList, $_);
        }
        else
        {
            Abort "Invalid argument";
        }
    
        shift;
    }
    
    $numFlags = @flagList;
    $numDates = @dateList;
    
    # check for 'compare' operation (-c flag)
    
    if ($flagList[0] eq "-c")
    {
        # The -c flag should have no value (in which case the above if is false),
        # there should be 1 or 2 dates and no other flags.
    
        if ($numFlags != 1)
        {
            Abort "Invalid use of -c flag";
        }
    
        if ($numDates == 1)
        {
            $today = todaysDate();
            push (@dateList, $today);  # 2nd date defaults to today
        }
        elsif ($numDates != 2)
        {
            Abort "Invalid number of dates for -c flag.";
        }
    
        $fromJDate = validJulian $dateList[0];
        $toJDate   = validJulian $dateList[1];
        $diff = $toJDate - $fromJDate;
	return ($diff);
    }
    
    # Here, there should be only ONE date.
    # If there isn't one we default to today's date
    
    if ($numDates == 0)
    {
        $date = todaysDate();
    }
    elsif ($numDates == 1)
    {
        $date = $dateList[0];
    }
    else
    {
        Abort "Too many dates.";
    }
    
    $jdate = validJulian $date;

    if ($jdate eq "INVALID_DATE")
    {
        return ("$date INVALID_DATE");
        1;
    }

    # Now let's perform each operation upon the Julian date
    
    foreach $flag (@flagList)
    {
        $operation = substr $flag, 0, 2;
        $value     = substr $flag, 2;
    
        if ($operation eq "-h")
        {
            manual;
            exit (2);
        }
        elsif ($operation eq "-d")       # Fiddle by day
        {
            $jdate += $value;
        }
        elsif ($operation eq "-w")       # Fiddle by week
        {
            $jdate += (7 * $value);
        }
        elsif ($operation eq "-n")       # jump to next day of week
        {
            $toDay   = dayOfWeekNumber $value;
            $fromDay = dayOfWeekNumberJulian $jdate;
            $diff = ($toDay - $fromDay - 1) % 7 + 1;
            $jdate += $diff;
        }
        elsif ($operation eq "-m")       # fiddle by month
        {
            $tempDate = fromJulian $jdate;
            $yyyy = substr $tempDate, 0, 4;
            $mm   = substr $tempDate, 4, 2;
            $dd   = substr $tempDate, 6, 2;
            $jmonth = (12 * $yyyy) + $mm;
            $jmonth += $value;
            $mm = $jmonth % 12;
            $yyyy = int($jmonth / 12);
            $tempDate = sprintf "%04d%02d%02d", $yyyy, $mm, $dd;

            # check that we haven't landed in a dodgy day of the month
            # e.g. 31-Sep
            $mm++;
            if ($mm > 12) {$mm = 1; $yyyy++;}
            $tempDate2 = sprintf "%04d%02d01", $yyyy, $mm;
            $jd2 = toJulian $tempDate2;
            $jd2--;
            $tempDate2 = fromJulian $jd2;   # last day of month
            $tempDate = $tempDate2 if ($tempDate > $tempDate2);
            $jdate = toJulian $tempDate;
        }
        elsif ($operation eq "-l")       # jump to end of this month
        {
            $tempDate = fromJulian $jdate;
            $yyyy = substr $tempDate, 0, 4;
            $mm   = substr $tempDate, 4, 2;
            $mm++;                                        # next month
            if ($mm > 12) {$mm = 1; $yyyy++;}
            $tempDate = sprintf "%04d%02d01", $yyyy, $mm; # 1st of next month
            $jdate = toJulian $tempDate;
            $jdate--;                                # last day of this month
        }
        elsif ($operation eq "-f")       # format the resultant date
        {                                # (deprecates -s and -j)
            $format = $flag;
        }
        elsif ($operation eq "-s")       # display day of week in result
        {
            $showDay = 1;
        }
        elsif ($operation eq "-j")       # display result as Julian date
        {
            $showJulian = 1;
        }
        else
        {
            Abort "Invalid operation $operation";
        }
    }
    
    
    if ($showJulian > 0)
    {
        $output .= "$jdate";
    }
    else
    {
        $fiddled_date = fromJulian $jdate;
        $output .= "$fiddled_date";
    }
    
    if ($showDay > 0)
    {
        $dayName = dayOfWeekNumberJulian $jdate;
        $output .= " $DayList[$dayName]";
    }


    if (($format ne "") && ($showJulian == 0) && ($showDay == 0))
    {
        $format =~ s/^-f//;
        $output = uber_format_date($format, $output);
    }

    return ($output);
}

#######################################################################

sub uber_format_date
{
    my ($format, $yyyymmdd) = @_;
    my $elem = "";
    my $delim = "";
    my $output = "";

    $format = uc($format);
    $format =~ s/_/ /g;

    return (toJulian($yyyymmdd)) if ($format eq "JULIAN");

    $delim = " " if ($format =~ m/ /);
    
    if ($format =~ m/-/)
    {
        return ($yyyymmdd) if ($delim ne ""); # mixed delimiters
        $delim = "-";
    }
    if ($format =~ m/\//)
    {
        return ($yyyymmdd) if ($delim ne ""); # mixed delimiters
        $delim = "/";
    }

    $delim = " " if (! $delim); # to allow single element formats to work
    for my $f (split /$delim/, $format)
    {
        $elem = "";
        if ($f eq "YYYYMMDD")
        {
            $elem = $yyyymmdd;
        }
        elsif ($f eq "DAYOFWEEK")
        {
            $elem = dayOfWeekNumberJulian(toJulian($yyyymmdd));
            $elem = $DayList[$elem];
        }
        elsif ($f eq "DOW")
        {
            $elem = dayOfWeekNumberJulian(toJulian($yyyymmdd));
            $elem = $DayList[$elem];
            $elem = substr($elem, 0, 3);
        }
        elsif ($f eq "D")
        {
            $elem = $yyyymmdd % 100;
        }
        elsif ($f eq "DD")
        {
            $elem = sprintf "%02d", $yyyymmdd % 100;
        }
        elsif ($f eq "M")
        {
            $elem = (int($yyyymmdd / 100)) % 100;
        }
        elsif ($f eq "MM")
        {
            $elem = sprintf "%02d", (int($yyyymmdd / 100)) % 100;
        }
        elsif ($f eq "MON")
        {
            $elem = (int($yyyymmdd / 100)) % 100;
            $elem = $MonthList[$elem - 1];
            $elem = substr($elem, 0, 3);
        }
        elsif ($f eq "MONTH")
        {
            $elem = (int($yyyymmdd / 100)) % 100;
            $elem = $MonthList[$elem - 1];
        }
        elsif (($f eq "Y") || ($f eq "YY"))
        {
            $elem = sprintf "%02d", int($yyyymmdd / 10000) % 100;
        }
        elsif (($f eq "YYYY") || ($f eq "YEAR"))
        {
            $elem = int($yyyymmdd / 10000);
        }
        else
        {
            return ($yyyymmdd);
        }
        $output .= ($elem . $delim);
    }
    chop($output);
    return ($output);
}

#######################################################################

sub date_calc
{
    return (date_manip(@_));
}

#######################################################################

1;

#######################################################################
# END OF FILE
#######################################################################
