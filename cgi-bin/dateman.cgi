#!/usr/bin/perl
############################################################
# dateman.cgi
#
# Front end for date_manip.pl.
############################################################
# This section is for initialisation

require "lib/basic_stuff.pl";   # this in turn requires "lib/date_manip.pl"

$SCRIPT_TITLE = "Date Manipulator";
$ADMIN_EMAIL = "mike\@stollery.co.uk"; 

@PRIVILEGE_LIST = ("Guest",         # 0
                   "Member",        # 1
                   "Manager",       # 2
                   "Administrator", # 3
                   "Owner");        # 4
@CSS_LIST = ("basic_stuff.css");
@COOKIE_LIST = ();
  
basic_stuff();
print $cgi->header(-cookie => [@COOKIE_LIST]);

my $message = "";
my $warning = "";

my $dd_from   = $cgi->param('dd');
my $mm_from   = $cgi->param('mm');
my $yyyy_from = $cgi->param('yyyy');
my $dd_to   = $cgi->param('dd2');
my $mm_to   = $cgi->param('mm2');
my $yyyy_to = $cgi->param('yyyy2');

my $sign = $cgi->param('sign');
my $num  = $cgi->param('num');
my $unit = $cgi->param('unit');
my $next = $cgi->param('next');

my $UnitHash = {'d' => 'day',
                'w' => 'week',
                'm' => 'month'};
my $valid_from = 1;
my $valid_to = 1;

if ($num =~ /^-\d+$/) # negative integer
{
    $sign = ($sign eq "-") ? "+" : "-"; # reverse sign
    $num =~ s/^-//;
}

    # default to today
    my ($dd_now, $mm_now, $yyyy_now) = split / /, date_manip("-fDD_MM_YYYY");
    $dd_from   = $dd_now if ($dd_from eq "");
    $mm_from   = $mm_now if ($mm_from eq "");
    $yyyy_from = $yyyy_now if ($yyyy_from eq "");

    my $yyyymmdd_from = "";
    if ($yyyy_from =~ /\D/)
    {
        $warning = qq(Year must be numeric.);
        $valid_from = 0;
    }
    else
    {
        $yyyymmdd_from = sprintf ("%4d%02d%02d", $yyyy_from,
                                                 $mm_from,
                                                 $dd_from);
    }

    my $dayofweek_from = date_manip("-fDAYOFWEEK $yyyymmdd_from");

    my @args = ("-fDAYOFWEEK_DD_MM_YYYY");
    my $calc_date_to = 0;


    if ($num =~ /\D/)
    {
        $warning = qq(Number must be numeric.);
    }
    else
    {
        $n = int($num);
        if ($n != 0)
        {
            $n = ($sign eq "-") ? 0 - $n : $n;
            push @args, "-${unit}$n";
            $calc_date_to = 1;
        }
    }

    if ($next)
    {
        push @args, sprintf "-n%3s", uc(substr($next, 0, 3));
        $calc_date_to = 1;
    }


    if ($calc_date_to)
    {
        push @args, $yyyymmdd_from;

        ($dayofweek_to, $dd_to, $mm_to, $yyyy_to) = 
            split / /, date_manip(@args);
        write_log(qq(date_manip("@args") = $dayofweek_to $dd_to/$mm_to/$yyyy_to));
    }

    my $yyyymmdd_to = "";
    if ($yyyy_to =~ /\/D/)
    {
        $warning = qq(Year must be numeric.);
        $valid_to = 0;
    }
    else
    {
        $yyyymmdd_to = sprintf ("%4d%02d%02d", $yyyy_to,
                                               $mm_to,
                                               $dd_to);
    }
    if ($yyyymmdd_to =~ /[0-9][0-9][0-9][0-9][0-3][0-9][0-9][0-9]/)
    {
        $dayofweek_to = date_manip("-fDAYOFWEEK $yyyymmdd_to")
            if ($dayofweek_to eq "");

        my $args = "-c $yyyymmdd_from $yyyymmdd_to";
        my $diff = date_manip("$args");
        write_log(qq(date_manip("$args") = $diff days));
        $message .= qq(Difference: $diff days);
    }

    if ($dayofweek_from =~ /INVALID_DATE/)
    {
        $valid_from = 0;
        $dayofweek_from = qq(<div class="basic_warning">INVALID DATE</div>);
    }
    else
    {
        $dow_from = substr($dayofweek_from, 0, 3);
        $mon_from = substr($MonthList[$mm_from - 1], 0, 3);
        $julian_proleptic_from = date_manip("-fJULIAN $yyyymmdd_from");
        $julian_ratadie_from = $julian_proleptic_from - 1721425;
        $julian_dublin_from = $julian_proleptic_from - 2415020;
    }

    if ($dayofweek_to =~ /INVALID_DATE/)
    {
        $valid_to = 0;
        $dayofweek_to = qq(<div class="basic_warning">INVALID DATE</div>);
        $message = "";
    }
    elsif ($yyyymmdd_to =~ /[0-9][0-9][0-9][0-9][0-3][0-9][0-9][0-9]/)
    {
        $dow_to = substr($dayofweek_to, 0, 3);
        $mon_to = substr($MonthList[$mm_to - 1], 0, 3);
        $julian_proleptic_to = date_manip("-fJULIAN $yyyymmdd_to");
        $julian_ratadie_to = $julian_proleptic_to - 1721425;
        $julian_dublin_to = $julian_proleptic_to - 2415020;
    }
    else
    {
        $valid_to = 0;
        $yyyymmdd_to = "";
    }

#$warning = qq(bing);

#print qq(Content-type: text/html
#
print qq(
<html>
 <head>
  <title>$SCRIPT_TITLE</title>
  <meta http-equiv="Content-Type"
        content="text/html;charset=utf-8" />
  <meta name="description" content="Script for testing global functionality" />
  <meta name="keywords" content="$SCRIPT_TITLE, login, logging, admin, globals" />
);
print_css_list();
print qq(
 </head>  
 <body class="basic">
  <br>
  <table class="basic_c">
   <tr>
    <td style="text-align: center">
<!--
sign=$sign<br>
num=$num<br>
unit=$unit<br>
next=$next<br>
dd_from=$dd_from<br>
mm_from=$mm_from<br>
yyyy_from=$yyyy_from<br>
dd_to=$dd_to<br>
mm_to=$mm_to<br>
yyyy_to=$yyyy_to<br>
-->
     <table class="basic_c">
      <tr>
       <td class="basic">
        <div class="basic_title_c">$SCRIPT_TITLE</div><br>
        <div class="basic_warning" style="text-align: center">$warning</div><br>

        <form method="POST" 
              action="$SERVER" 
              enctype="application/x-www-form-urlencoded">
         <table align="center" width="100%" border="0">
          <tr>
           <td class="basic">
            From:
           </td>
           <td class="basic">
            $dayofweek_from
           </td>
           <td class="basic">
            <select name="dd">
);

for (my $d = 1; $d <= 31; $d++) # Date of month
{
    $selected = ($d == $dd_from) ? qq( selected="selected") : "";
    print qq(
             <option value="$d" $selected>$d</option>
    );    
}

print qq(
            </select>
           </td>
           <td class="basic">
            <select name="mm">
);

for (my $m = 1; $m <= 12; $m++) # month
{
    $selected = ($m == $mm_from) ? qq( selected="selected") : "";
    print qq(
             <option value="$m" $selected>$MonthList[$m - 1]</option>
    );    
}

#$num = abs($num);
my $selected_plus = ($sign eq "+") ? qq( selected="selected") : "";
my $selected_minus = ($sign eq "-") ? qq( selected="selected") : "";
my $selected_d = ($unit eq "d") ? qq( selected="selected") : "";
my $selected_w = ($unit eq "w") ? qq( selected="selected") : "";
my $selected_m = ($unit eq "m") ? qq( selected="selected") : "";
my $selected_sun = ($next eq "Sunday") ? qq( selected="selected") : "";
my $selected_mon = ($next eq "Monday") ? qq( selected="selected") : "";
my $selected_tue = ($next eq "Tuesday") ? qq( selected="selected") : "";
my $selected_wed = ($next eq "Wednesday") ? qq( selected="selected") : "";
my $selected_thu = ($next eq "Thursday") ? qq( selected="selected") : "";
my $selected_fri = ($next eq "Friday") ? qq( selected="selected") : "";
my $selected_sat = ($next eq "Saturday") ? qq( selected="selected") : "";

print qq(
            </select>
           </td>
           <td class="basic">
            <input type="text" name="yyyy" value="$yyyy_from" size="4" maxlength="4" />
           </td>
           <td class="basic" style="text-align: right">
            <select name="sign">
             <option value="+" $selected_plus>+</option>
             <option value="-" $selected_minus>&minus;</option>
            </select>
           </td>
           <td class="basic">
            <input type="text" name="num" value="$num" size="4" maxlength="8" />
           </td>
           <td class="basic">
            <select name="unit">
             <option value="d" $selected_d>days</option>
             <option value="w" $selected_w>weeks</option>
             <option value="m" $selected_m>months</option>
            </select>
           </td>
           <td class="basic">
            <select name="next">
             <option value=""></option>
             <option value="Sunday" $selected_sun>next Sunday</option>
             <option value="Monday" $selected_mon>next Monday</option>
             <option value="Tuesday" $selected_tue>next Tuesday</option>
             <option value="Wednesday" $selected_wed>next Wednesday</option>
             <option value="Thursday" $selected_thu>next Thursday</option>
             <option value="Friday" $selected_fri>next Friday</option>
             <option value="Saturday" $selected_sat>next Saturday</option>
            </select>
           </td>
          </tr>




          <tr>
           <td class="basic">
            To:
           </td>
           <td class="basic">
            $dayofweek_to
           </td>
           <td class="basic">
            <select name="dd2">
             <option value="" $selected></option>
);

for (my $d = 1; $d <= 31; $d++) # Date of month
{
    $selected = ($d == $dd_to) ? qq( selected="selected") : "";
    print qq(
             <option value="$d" $selected>$d</option>
    );    
}

print qq(
            </select>
           </td>
           <td class="basic">
            <select name="mm2">
             <option value="" $selected></option>
);

for (my $m = 1; $m <= 12; $m++) # month
{
    $selected = ($m == $mm_to) ? qq( selected="selected") : "";
    print qq(
             <option value="$m" $selected>$MonthList[$m - 1]</option>
    );    
}

print qq(
            </select>
           </td>
           <td class="basic">
            <input type="text" name="yyyy2" value="$yyyy_to" size="4" maxlength="4" />
           </td>
           <td class="basic">
            <input type="submit" name="manip" value="Apply" />
           </td>
           <td class="basic" style="vertical-align: bottom; text-align: right">
<!--
            <input type="reset" name="reset" value="Reset" />
-->
            <a href="${THIS_SCRIPT}?dd=$dd_to&mm=$mm_to&yyyy=$yyyy_to">next</a>
           </td>
           <td class="basic" style="vertical-align: bottom">
            <a href="${THIS_SCRIPT}?">today</a>
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>



         </table>
        </form>

        <div class="basic" style="text-align: center; font-weight: bold">$message</div>
       </td>
      </tr>
     </table>
     <br clear="all">
);

if ($valid_from)
{
    print qq(
     <div style="font-weight: bold">Julian Days</div>
     <table class="basic_c">
      <tr>
       <td class="basic">
        &nbsp;
       </td>
       <td class="basic">
        &nbsp;
       </td>
       <td class="basic">
        &nbsp;
       </td>
       <td class="basic">
        &nbsp;
       </td>
       <td class="basic">
        Proleptic
       </td>
       <td class="basic">
        Rata Die
       </td>
       <td class="basic">
        Dublin
       </td>
      </tr>
      <tr>
       <td class="basic" colspan="4">
        Epoch (Day 1):
       </td>
       <td class="basic">
        01/01/4713&nbsp;BC
       </td>
       <td class="basic">
        01/01/0001
       </td>
       <td class="basic">
        01/01/1900
       </td>
      </tr>
      <tr>
       <td class="basic">
        $dow_from
       </td>
       <td class="basic">
        $dd_from
       </td>
       <td class="basic">
        $mon_from
       </td>
       <td class="basic">
        $yyyy_from
       </td>
       <td class="basic">
        $julian_proleptic_from
       </td>
       <td class="basic">
        $julian_ratadie_from
       </td>
       <td class="basic">
        $julian_dublin_from
       </td>
      </tr>
);

print qq(
      <tr>
       <td class="basic">
        $dow_to
       </td>
       <td class="basic">
        $dd_to
       </td>
       <td class="basic">
        $mon_to
       </td>
       <td class="basic">
        $yyyy_to
       </td>
       <td class="basic">
        $julian_proleptic_to
       </td>
       <td class="basic">
        $julian_ratadie_to
       </td>
       <td class="basic">
        $julian_dublin_to
       </td>
      </tr>
) if ($valid_to);

print qq(
     </table>
     <br clear="all"><br>
);
}

print_copyright();

print qq(
    </td>
   </tr>
  </table>
 </body>
</html>
);

exit(0);

############################################################
# EOF