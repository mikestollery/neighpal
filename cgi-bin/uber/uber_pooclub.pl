############################################################
#
# uber_pooclub.pl
#
# Provides client with poll handling pages
#
# daily     - set a daily event
#
#
############################################################



############################################################
#
# Handle pooclub requests
#
############################################################

sub uber_pooclub
{
    check_for_daily_stuff();

    my $message = "";
    my $page = $cgi->param('page');
    my $id = $cgi->param('id');

    if ($cgi->param('voty_approve') eq "Submit")
    {
        process_voty_approve();
        $page = "voty_all_noms";
    }

    if ($cgi->param('setpoll') eq "Set Poll")
    {
        process_new_poll_notify();
    }
    elsif ($cgi->param('postas')) # eq "Send")
    {
        process_postas_page(); # rename process_postas()  ?
    }
    elsif ($cgi->param('topic')) # eq "Send")
    {
        process_topic();
    }

    if ($cgi->param('cull_candidates') eq "Apply Changes")
    {
        process_cull_candidates();
        $page = "cull_candidates";
    }

    # Which page should we print?
    if ($page eq "daily")
    {
        print_daily_page();
    }
    elsif (($page eq "voty_my_noms") || ($cgi->param('voty_nominate')))
    {
        print_voty_my_noms_page();
    }
    elsif (($page eq "voty_all_noms") || ($page eq "voty") || ($cgi->param('voty_all_noms')))
    {
        print_voty_all_noms_page();
    }
    elsif ($page eq "voty_approve")
    {
        print_voty_approve_page();
    }
    elsif ($page eq "topic")
    {
        print_topic_form_page();
    }
    elsif ($page eq "postas")
    {
        print_postas_form_page();
    }
    elsif ($page eq "cull_candidates")
    {
        print_cull_candidates_form_page();
    }
    elsif ($cgi->param('reg') eq "Register") # catch new user's registration
    {
        print_new_user_page();
    }

#    if ($cgi->param('pooclub') eq "checkdaily")
#    {
#        check_for_daily_stuff();
#    }
}

############################################################
#
# Allow user to set a Daily Drivel feature.
#
############################################################

sub print_daily_page
{
    my ($message) = @_;
    log_info("print_daily_page(message=$message)");

    my $title = "Daily Drivel";
    my $daily = $cgi->param('daily');
    my $message = qq(Add or edit an entry for pooclub's daily drivel);
    my $warning = "";
    my @category_list = ("Event", "Joke", "Thought", "Quote", "Link");
    my $daily_dir = "${USERROOT}/$UBERACC{'USERNAME'}/daily";
    makedir("$daily_dir");

    my $category = $cgi->param('category');
    my $details  = $cgi->param('details');
    my $dd       = $cgi->param('dd_daily');
    my $mm       = $cgi->param('mm_daily');
    my $yyyy     = $cgi->param('yyyy_daily');
    $yyyy = "all" if (!$yyyy);

    my $yyyymmdd = sprintf("%04d%02d%02d", $yyyy, $mm, $dd);
    my $fname = "${daily_dir}/${yyyymmdd}_$category.txt";

    # check if date is valid
    my $date = "";
    $yyyy = substr($yyyymmdd, 0, 4);
    if ($yyyy > 0) # specific year
    {
        $year = $yyyy;
        $diff = date_manip("-c $yyyymmdd");
        $date = date_manip("-fDAYOFWEEK_DD_MONTH_YYYY $yyyymmdd");
        $warning = qq(You must set the event date in the future) if ($diff >= 0);
        $warning = qq(Invalid date) if ($date =~ /INVALID_DATE/);
    }
    else # every year
    {
        $year = "zero";
        $yyyymmdd = sprintf("2008%02d%02d", $mm, $dd);
        $date = date_manip("-fDAYOFWEEK_DD_MONTH_YYYY $yyyymmdd");
        $warning = qq(Invalid date) if ($date =~ /INVALID_DATE/);
        $date = "$dd " . $MonthList[$mm - 1] . " every ";
        $date .= "leap " if ($yyyymmdd =~ /229$/);
        $date .= "year";
    }
    $warning = qq(You need to be logged in to submit some drivel.) if (! is_logged_in());

    if (($daily eq 'Save') && !($details =~ /^\s*$/))
    {
        if ($warning)
        {
            $message = qq(Not saving event.);
        }
        else
        {
            open (OUTF, ">$fname") or $warning = qq(Cannot save to file: $fname);
            printf OUTF "$details\n";
            close(OUTF);
            $message = "Your " . lc($category) . " will be posted on $date" if (!$warning);
            log_info("Saved daily drivel file: $fname");
            email_notify($UBERENV{OWNER_EMAIL}, $UBERENV{ADMIN_EMAIL},
                         "Saved event",
                         "$UBERACC{'USERNAME'} saved file: $fname");
        }
    }
    elsif ($daily eq 'Delete')
    {
        unlink($fname);
        $details = "";
        log_info("Deleted daily drivel file: $fname");
        email_notify($UBERENV{OWNER_EMAIL}, $UBERENV{ADMIN_EMAIL},
                     "Deleted event",
                     "$UBERACC{'USERNAME'} deleted file: $fname");
        $message = qq($category has been deleted.);
    }
    else # get details from file
    {
        open (INF, "$fname");
        $details = "";
        while(<INF>) {$details .= $_;}
        close(INF);
    }
    $warning = "" if (!$daily); # user hasn't submitted a command

    print_html_head();
    print_small_login_line();

    # Get user's request to set up a poll
    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$warning</div>
<!--
daily=$daily<br>
dd=$dd<br>
mm=$mm<br>
yyyy=$yyyy<br>
year=$year<br>
date=$date<br>
diff=$diff<br>
category=$category<br>
details=$details<br>
daily_dir=$daily_dir<br>
fname=$fname<br>
-->
        <form method="POST"
              action="$THIS_SCRIPT"
              enctype="application/x-www-form-urlencoded">
         <table class="basic_c" style="width: 600;">
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            $message<p>
           </td>
          </tr>
          <tr>
           <td class="basic">
            Date
           </td>
           <td class="basic">
            <table class="basic">
             <tr>
    );

    date_input("daily", 0);

    print qq(
             </tr>
            </table>
             <div class="basic_faint">Type 'all' for year if event is to occur every year.</div>
           </td>
          </tr>
          <tr>
           <td class="basic">
            Category
           </td>
           <td class="basic">
            <select name="category">
    );

    for my $cat (@category_list)
    {
        $selected = ($cat eq $category) ? qq(selected="selected") : "";
        print qq(
             <option value="$cat" $selected>$cat</option>
        );
    }

    print qq(
            </select>
            <input type="hidden" name="page" value="daily" />
            <input type="submit" name="daily" value="Load" />&nbsp;
            <input type="submit" name="daily" value="Save" />&nbsp;
            <input type="submit" name="daily" value="Delete" />&nbsp;
           </td>
          </tr>
          <tr>
           <td class="basic">
            Details
           </td>
           <td class="basic">
            <textarea name="details" cols="60" rows="20">$details</textarea>
           </td>
          </tr>
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            <a href="${THIS_SCRIPT}?">home</a>
           </td>
          </tr>
         </table>
        </form>
    );

    print_drivel_index($daily_dir);
    print_copyright();
    print_html_end();

    exit(0);
}


############################################################

sub print_drivel_index
{
    my ($daily_dir) = @_;
    log_info("print_drivel_index(daily_dir=$daily_dir)");

    my $date;
    my $yyyymmdd;
    my $dow;
    my $dd;
    my $mm;
    my $mon;
    my $yyyy;
    my $year;
    my $fname;
    my $f;
    my $first_line;

    print qq(
        <table class="basic_c">
    );

    for my $fname (<${daily_dir}/[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]_*.txt>)
    {
        $f = basename($fname);
        $f =~ s/\.txt$//;
        ($yyyymmdd, $category) = split /_/, $f;
        $date = $yyyymmdd;
        $date =~ s/^0000/2008/;
        ($dow, $dd, $mm, $year) = split / /, date_manip("-fDOW_DD_MM_YYYY $date");
        $mon = substr($MonthList[$mm - 1], 0, 3);
        if (int($yyyymmdd) < 10000)
        {
            $year = "All";
            $dow = "";
        }

        open (INF, "$fname");
        $first_line = <INF>;
        close(INF);
        $first_line = substr($first_line, 0, 64);

        print qq(
        <tr>
         <td class="basic">$dow</td>
         <td class="basic">$dd</td>
         <td class="basic">$mon</td>
         <td class="basic">$year</td>
         <td class="basic">$category</td>
         <td class="basic">:</td>
         <td class="basic"><nobr>$first_line</nobr></td>
         <td class="basic">
          <a href="${THIS_SCRIPT}?page=daily&dd_daily=$dd&mm_daily=$mm&yyyy_daily=$year&category=$category">
           load</a>
         </td>
        </tr>
        );
    }
    print qq(
        </table><br clear="all">
    );
}

############################################################
#
# Handle users' nominations for next year's Vegetable Of The Year
#
############################################################

sub print_voty_my_noms_page
{
    print_voty_all_noms_page("You must be logged in to nominate.") if (! is_logged_in());

    my ($message) = @_;
    log_info("print_voty_my_noms_page(message=$message)");

    my $title = "Vegetable Of The Year";
#    my $voty_year = $cgi->param('voty_year');
#    my $voty_status = get_voty_status($voty_year);
#    my $message = ($voty_status) ? qq(Add or edit your nominations for <b>$voty_year</b>)
#                                 : qq(Nominations for <b>$voty_year</b> are now closed.);
   
    my $warning = "";
    my @winners = read_voty_winners();
    my $voty_year = substr($YYYYMMDD, 0, 4) + 1;
    my $voty_dir = "${USERROOT}/$UBERACC{'USERNAME'}";
    my $voty_file = "${voty_dir}/voty_noms_${voty_year}.dat";
    makedir("$voty_dir");
    my @veg_list = ();
    my $rating;
    my $rating_str;
    my $reason;
    my $disable = "";
#    my $disabled = ($voty_status) ? "" : qq(disabled="disabled");
    my $message = qq(Add or edit your nominations for <b>$voty_year</b>);

    print_html_head();
    print_small_login_line();

    if ($cgi->param('voty_nominate') eq "Submit") # process vegetables
    {
        my $noms = "";
        open (OUTF, ">$voty_file");
        for (my $count = 0; $count < 3; $count++)
        {
            $veg_list[$count] = $cgi->param("veg$count");
            print OUTF "$veg_list[$count]\n";
            $noms .= "; $veg_list[$count]";
        }
        close(OUTF);
        $noms =~ s/^;//;
        log_action("Nominated for VOTY: $noms");

        # notify group by email
        my $subject = "New VOTY Nominations";
        my $user = get_name_for_display($UBERACC{'USERNAME'});
        my $message = qq($user has nominated $noms for Vegetable Of the Year.

To see VOTY nominations go to: http://pooclub.shite.org/voty
);

log_info("FISH user=$user USERNAME=$UBERACC{'USERNAME'}");
log_info("FISH message=$message");
        email_notify($UBERENV{'GROUP_EMAIL'},
#        email_notify($UBERENV{'EMAIL'}, # mike2sheds@gmail.com
                     $UBERENV{'ADMIN_EMAIL'},
                     "$subject",
                     "$message",
                     "Vegetable Of The Year");
    }
    else # read them from file
    {
        open (INF, "$voty_file");
        my $count = 0;
        while(<INF>)
        {
            chop;
            next if (/^#/);
            next if (/^\s*$/);
            $veg_list[$count++] = $_;
        }
        close(INF);
    }

    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$warning</div>

        <form method="POST"
              action="$THIS_SCRIPT"
              enctype="application/x-www-form-urlencoded">
         <table class="basic_c" style="width: 600;">
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" colspan="3">
            <br><br>$message<br><br>
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
    );

    my $not_accepted = 0;
    for (my $count = 0; $count < 3; $count++)
    {
        ($rating, $rating_str, $reason) = check_voty_approval($veg_list[$count]);
        $not_accepted++ if (($rating == 0) || ($rating == -1));
        $icon = "${IMGROOT}/icons/${rating}.gif";

        print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            <input type="text" name="veg$count" value="$veg_list[$count]" size="30" maxlength="30" $disabled/>
           </td>
           <td class="basic">
            <img src="$icon" alt="$rating_str" height="15" />
           </td>
           <td class="basic">
            $rating_str
           </td>
           <td class="basic">
            <nobr>$reason</nobr>
           </td>
          </tr>
        );
    }

    print qq(
          <tr>
           <td class="basic">
            &nbsp
           </td>
           <td class="basic">
            <input type="hidden" name="voty_year" value="$voty_year" />
            <input type="submit" name="voty_nominate" value="Submit" $disabled/>
            &nbsp;<a href="${THIS_SCRIPT}?page=voty_all_noms&voty_year=$voty_year">all nominations</a>
            &nbsp;<a href="${THIS_SCRIPT}?">home</a>
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
          </tr>
          <tr>
           <td class="basic">
            &nbsp
           </td>
           <td class="basic" colspan="3">
    );


    if ($not_accepted)
    {
        print qq(
<br>
Not approved?  Don't worry.  It just means that your nomination is not on
our administrators' list of approved vegetables.
<p>
If your nomination is 'Pending' this means that the pooclub elves are busily
trying to work out if what you have nominated is a proper vegetable.
To speed things along, you can help them by posting evidence of vegetable
worthiness to pooclub where the elves will be happy to give you a big green tick
once they can verify your claim.
<p>
If however your nomination is 'Rejected' this means that the pooclub elves have
carefully considered your nomination but cannot find enough evidence to
validate it.
But don't worry, all is not lost, they will still consider fresh evidence if
it is presented before close of nominations.
Mind you, this would have to be totally new evidence - the elves will not
be swayed by moans of 'aw go on, please' or bickering.
        );
    }

    print qq(
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
         </table>
        </form>
    );


    print_copyright();
    print_html_end();

    exit(0);
}


############################################################
#
# assumes voty_winners.dat is reverse sorted, i.e. most
# recent winner first.  This file is manually maintained.

sub read_voty_winners
{
    my $fname = "${SHAREDROOT}/voty_winners.dat";
    my @winners;
    open (VOTY, $fname) or log_error("Cannot open VOTY Winners file: $fname");
    while(<VOTY>)
    {
        chop;
        next if (! /;/);
        push @winners, $_;
    }
    close(VOTY);
    return @winners;
}

############################################################

sub check_voty_approval
{
    my ($veg) = @_;
    log_info("check_voty_approval(veg=$veg)");

    return (2, "", "") if ($veg =~ /^\s*$/);

    my @rating_list = ("Rejected", "Pending", "Approved");
    my $fname = "${SHAREDROOT}/voty_vegetables.dat";
    my $veg_rating;
    my $veg_reason;

    open (VEGF, "$fname");
    while(<VEGF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s$/);
        ($vegetable, $rating, $reason, $others) = split /;/, $_;
        if (lc($veg) eq lc($vegetable))
        {
            $veg_rating = $rating;
            $veg_reason = $reason;
        }
    }
    close(VEGF);

    $veg_rating = 0 if (! $veg_rating);
    return ($veg_rating, $rating_list[$veg_rating + 1], $veg_reason);
}

############################################################

sub print_voty_all_noms_page
{
    my ($warning) = @_;
    log_info("print_voty_all_noms_page(warning=$warning)");

    my $title = "Vegetable Of The Year - Nominations";
    my $message;
    my @approved_list = ();
    my @rejected_list = ();
    my @pending_list = ();
    my %nominator_hash = {};
    my %reason_hash = {};
    my $vegetable;
    my $rating;
    my $rating_str;
    my $reason;
    my $member;

    print_html_head();
    print_small_login_line();

    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$warning</div>

         <table class="basic_c" style="width: 500;">
          <tr>
           <td class="basic" colspan="5" style="text-align: center">
    );

    # Determine voty year
    my $voty_year = $cgi->param('voty_year');
    my $next_year = substr($YYYYMMDD, 0, 4) + 1;
    print_voty_year_form();
    $voty_year = $next_year if (! $voty_year);
    if ($voty_year ne $next_year)
    {
        $message = qq(Nominations for <b>$voty_year</b> are closed.);
    }

    print qq(
            <a href="${THIS_SCRIPT}?page=voty_my_noms&voty_year=$voty_year">my nominations</a> |
            <a href="${THIS_SCRIPT}?p=vegetable">about VOTY</a> |
            <a href="${THIS_SCRIPT}?">home</a>
           </td>
          </tr>
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" colspan="3">
            $message<p>
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
    );

    for my $fname (<${USERROOT}/*/voty_noms_${voty_year}.dat>)
    {
        $member = $fname;
        $member =~ s/\/voty_noms_${voty_year}.dat$//;
        $member = basename($member);

        open (INF, "$fname");
        my $count = 0;
        while(<INF>)
        {
            chop;
            next if (/^#/);
            next if (/^\s*$/);
            $vegetable = $_;
            ($rating, $rating_str, $reason) = check_voty_approval($vegetable);
            log_info("vegetable=$vegetable rating=$rating rating_str=$rating_str reason=$reason");

            if (! $nominator_hash{"$vegetable"})
            {
                if ($rating == 1)
                {
                    push (@approved_list, $vegetable);
                }
                elsif ($rating == -1)
                {
                    push (@rejected_list, $vegetable);
                }
                else
                {
                    push (@pending_list, $vegetable);
                }
            }
            $nominator_hash{"$vegetable"} .= "${member}, ";
            $reason_hash{"$vegetable"} = $reason;
        }
        close(INF);
    }

    if (scalar(@approved_list))     # Approved List
    {
        print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="font-weight: bold" colspan="2">
            Approved
           </td>
           <td class="basic">
            Nominated by
           </td>
          </tr>
        );
        for my $veg (sort @approved_list)
        {
            $nominated_by = substr($nominator_hash{"$veg"}, 0, -2);
            $nominated_by = get_name_for_display($nominated_by);
            print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            $veg
           </td>
           <td class="basic">
            <img src="${IMGROOT}/icons/1.gif" alt="Approved" height="15">
           </td>
           <td class="basic">
            $nominated_by
           </td>
           <td class="basic">
            $reason_hash{"$veg"}
           </td>
          </tr>
            );
        }
    }

    if (scalar(@pending_list))     # Pending List
    {
        print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="font-weight: bold" colspan="3">
            <br>Pending
           </td>
          </tr>
        );
        for my $veg (sort @pending_list)
        {
            $nominated_by = substr($nominator_hash{"$veg"}, 0, -2);
            $nominated_by = get_name_for_display($nominated_by);
            print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            $veg
           </td>
           <td class="basic">
            <img src="${IMGROOT}/icons/0.gif" alt="Approved" height="15">
           </td>
           <td class="basic">
            $nominated_by
           </td>
           <td class="basic">
            <a href="${THIS_SCRIPT}?page=voty_approve&veg=$veg">approve</a>
           </td>
          </tr>
            );
        }
    }

    if (scalar(@rejected_list))     # Rejected List
    {
        print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="font-weight: bold" colspan="3">
            <br>Rejected
           </td>
          </tr>
        );
        for my $veg (sort @rejected_list)
        {
            $nominated_by = substr($nominator_hash{"$veg"}, 0, -2);
            $nominated_by = get_name_for_display($nominated_by);
            print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            $veg
           </td>
           <td class="basic">
            <img src="${IMGROOT}/icons/-1.gif" alt="Approved" height="15">
           </td>
           <td class="basic">
            $nominated_by
           </td>
           <td class="basic">
            $reason_hash{"$veg"}
           </td>
          </tr>
            );
        }
    }

    print qq(
         </table><p>
         <div style="text-align: center">
          <a href="${THIS_SCRIPT}?page=voty_my_noms&voty_year=$voty_year">my nominations</a> |
          <a href="${THIS_SCRIPT}?p=vegetable">about VOTY</a> |
          <a href="${THIS_SCRIPT}?">home</a>
         </div><br>
    );

    if (! is_logged_in())
    {
        print qq(
         <div style="text-align: center">
Not got a pooclub account?  Then
<div style="font-size: 20px"><a href="${THIS_SCRIPT}?page=signup">sign up</a></div>
and nominate your chosen vegetables<br> for our next Vegetable Of The Year<br> elections.<p>
         </div>
        );
    }

    print_copyright();
    print_html_end();

    exit(0);
}


############################################################
#
# Admin: approve or reject a nomination
#
############################################################

sub print_voty_approve_page
{
    my ($message) = @_;
    log_info("print_voty_approve_page(message=$message)");

    my $title = "Vegetable Of The Year";
    my $veg = $cgi->param('veg');
    my $message = qq(Approve or reject a nomination);
    my $warning = "";
    my $disabled = "";

    if ($UBERACC{'PRIVILEGE'} < 3)
    {
        $message = qq(Only administrators may approve or reject nominations.);
        $disabled = qq(disabled="disabled");
    }

    print_html_head();
    print_small_login_line();

    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$warning</div>

        <form method="POST"
              action="$THIS_SCRIPT"
              enctype="application/x-www-form-urlencoded">
         <table class="basic_c" style="width: 600;">
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" colspan="3">
            $message<p>
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            Nomination:
           </td>
           <td class="basic">
            <input type="text" name="veg" value="$veg" size="30" maxlength="40" $disabled />
           </td>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            Reason: (optional)
           </td>
           <td class="basic">
            <input type="text" name="reason" value="" size="30" maxlength="120" $disabled />
           </td>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            <select name="action" $disabled>
             <option value="-1">Reject</option>
             <option value="0" selected="selected">Pending</option>
             <option value="1">Approve</option>
            </select>
            <input type="submit" name="voty_approve" value="Submit" $disabled />
            <a href="${THIS_SCRIPT}?page=voty_all_noms">all nominations</a>
           </td>
           <td class="basic">
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>



         </table>
        </form>
    );

    print_copyright();
    print_html_end();

    exit(0);
}

############################################################

sub process_voty_approve
{
    return if ($UBERACC{'PRIVILEGE'} < 3);

    log_info("process_voty_approve()");

    my $fname = "${SHAREDROOT}/voty_vegetables.dat";
    my $veg = $cgi->param('veg');
    my $reason = $cgi->param('reason');
    my $action = $cgi->param('action');
    my $act = "";
    $act = "Approved" if ($action > 0);
    $act = "Rejected" if ($action < 0);
    my $year = substr($YYYYMMDD, 0, 4) + 1;
    log_action("$act VOTY nomination: $veg (reason: $reason)");
    open (OUTF, ">>$fname");
    print OUTF "${veg};${action};${reason};${year};${YYYYMMDD}\n";
    close(OUTF);

    my $subject = "$veg Has Been $act";
    $act = lc($act);
    my $user = get_name_for_display($UBERACC{'USERNAME'});
    my $message = qq(Vegetable of the Year nomination 
"$veg" has been $act

To see VOTY nominations go to: http://pooclub.shite.org/voty
);
log_info("FISH message=$message");

    email_notify($UBERENV{'GROUP_EMAIL'},
#    email_notify($UBERENV{'EMAIL'}, # mike2sheds@gmail.com
                 $UBERENV{'ADMIN_EMAIL'},
                 "$subject",
                 "$message",
                 "Vegetable Of The Year");
}


############################################################
#
# Welcome new user to pooclub
#
############################################################

sub print_new_user_page
{
    my ($message) = @_;
    my $title = "Welcome To Pooclub";

    print_html_head();
    print_small_login_line();

    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_medium" style="text-align: left; width: 500">
<br />
<img src="${IMGROOT}/cvjump.jpg" alt="Welcome" align="right" style="width: 150" />
Well done!  You now have a poopages account.
<p />
Before we return you to the poopages, would you like to subscribe to our 
googlegroups forum where you can observe, and even interact with,
other pooclubbers in their natural habitat?  
These are the people that you’ll be voting for if you wish to expel
anyone in The Cull.
<ul>
<li><a href="http://groups.google.com/group/pooclub/subscribe">Yes please – sign me up now!</a>
<li><a href="http://groups.google.com/group/pooclub">Can I just take a look at the forum and decide later?</a>
<li><a href="?">Thanks, but I’m already a member of the forum.</a>
<li><a href="?">Not on your nelly.  They look a right motley bunch.</a>
</ul>
<img src="${IMGROOT}/forum.jpg" alt="Forum" style="width: 200" />
<div class="basic_title"><a href="http://groups.google.com/group/pooclub/subscribe">Join the Forum</a></div>
        </div>

    );

    print_drivel_index($daily_dir);
    print_copyright();
    print_html_end();

    exit(0);
}

############################################################

sub voty_year
{
    my $fname = "${SHAREDROOT}/voty_years.dat";
    my $voty_year_status = $cgi->param('voty_year_status');
    my ($voty_year, $voty_status) = split /;/, $voty_year_status;

    print qq(
        <form method="POST"
              action="$THIS_SCRIPT"
              enctype="application/x-www-form-urlencoded">Year:
        <select name="voty_year_status">
    );
    open (INF, "$fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($year, $status) = split /;/, $_;
        if (! $voty_year)
        {
            if ($status)
            {
                $voty_year = $year;
                $voty_status = $status;
            }
        }
        $selected = ($voty_year eq $year) ? qq(selected="selected") : "";
        print qq(
         <option value="${year};${status}" $selected>$year</option>
        );
    }
    close(INF);
    print qq(
        </select>
        <input type="submit" name="voty_all_noms" value="Select" />
        </form>
    );
    return($voty_year, $voty_status); # default values
}

############################################################

sub print_voty_year_form
{
    # get list of years from voty_vegetables file
    my $fname = "${SHAREDROOT}/voty_vegetables.dat";
    my $selected_year = $cgi->param('voty_year');

    my $yyyymmdd;
    my $year = substr($YYYYMMDD, 0, 4) + 1;
    my %yearFlag;
    $yearFlag{$year} = "Y";
    my @year_list = ($year);
    $selected_year = $year if ($selected_year eq "");

    open(INF, $fname) or log_error("print_voty_year_form() Cannot open file: $fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($veg, $app, $reason, $year, $yyyymmdd) = split /;/, $_;
        if ((! $year =~ /^\s*$/) && ($yearFlag{$year} ne "Y"))
        {
            $yearFlag{$year} = "Y";
            push @year_list, $year;
        }
    }
    close(INF);

#@array = ('Apple', 'Orange', 'Apple', 'Banana');
#%hashTemp = map { $_ => 1 } @array;
#@array_out = sort keys %hashTemp;
## @array_out contains ('Apple', 'Banana', 'Orange')

    print qq(
        <form method="POST"
              action="$THIS_SCRIPT"
              enctype="application/x-www-form-urlencoded">Year:
        <select name="voty_year">
    );

    for $year (reverse sort @year_list)
    {
        $selected = ($selected_year eq $year) ? qq(selected="selected") : "";
        print qq(
         <option value="$year" $selected>$year</option>
        );
    }

    print qq(
        </select>
        <input type="submit" name="voty_all_noms" value="Select" />
        </form>
    );
}

############################################################

sub get_voty_status
{
    my ($voty_year) = @_;
    my $fname = "${SHAREDROOT}/voty_years.dat";
    my $voty_status = 0;

    open (INF, "$fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($year, $status) = split /;/, $_;
        $voty_status = $status if ($voty_year eq $year);
    }
    close(INF);

    return($voty_status);
}

############################################################

sub check_for_daily_stuff
{
    # Only perform these tasks ONCE per day
    my $date_file = "${SHAREDROOT}/latest_date.txt";
    open (DATE, "$date_file");
    my $latest_date = <DATE>;
    close(DATE);
    my $today = date_manip();
#    log_info("FISH check_for_daily_stuff() latest_date=$latest_date today=$today");

    if ($today eq $latest_date)
    {
#        log_info("FISH check_for_daily_stuff() - same day, no action.");
        return;
    }

    # record today's date as latest date
    open (DATE, ">$date_file");
    print DATE $today;
    close(DATE);

    log_info("Doing daily stuff");
    check_for_expired_polls();

    # Check for events...
    make_daily_drivel();
    make_new_cull_poll();
    post_todays_topic();
}

############################################################
############################################################

# deprecated
sub write_log2
{
    my @items = @_;
    reset_date_time();
    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
    open (LOG, ">>$LOGFILE");
    if (LOG)
    {
        print LOG "$timestamp $ENV{REMOTE_ADDR} $UBERACC{'USERNAME'}";
        for $item (@items)
        {
            print LOG " $item";
        }
        print LOG "\n";
    }
    close(LOG);
}

############################################################

sub make_new_cull_poll
{
    log_info("make_new_cull_poll()");
    # only do this on the first day of the month
    if (substr($YYYYMMDD, 6, 2) != "01")
#    if (substr($YYYYMMDD, 6, 2) != "11") # FISH
    {
        return;
    }
    log_info("Setting up new cull poll");

    my $name;
    my $flag;
    my $c = 0;
    my $candidates_file = "${SHAREDROOT}/cull_candidates.dat";
    open (CULL, "$candidates_file");
    if (! CULL)
    {
        log_info("Cannot open Cull Candidates file: $candidates_file");
        return;
    }
    while(<CULL>)
    {
        chop;
        next if (/^#/);
        next if (/^s*$/);
        ($name, $flag) = split /;/;
        if ($flag eq "1")
        {
            log_info("Including $name");
            $cgi->param(-name => "choice$c", -value => "$name");
            $c++;
        }
        else
        {
            log_info("$name is switched off");
        }
    }
    close(CULL);

    my $closing_date = date_manip("-l $YYYYMMDD");
    my $yyyy_poll = substr($closing_date, 0, 4);
    my $mm_poll = substr($closing_date, 4, 2);
    my $dd_poll = substr($closing_date, 6, 2);
    my $closing_month = date_manip("-fMONTH $closing_date");
    my $question = qq(The Cull - $closing_month $yyyy_poll);
    $question .= qq(: Vote for the player you wish to see thrown out of pooclub.);

    $cgi->param(-name => 'yyyy_poll', -value => "$yyyy_poll");
    $cgi->param(-name => 'mm_poll', -value => "$mm_poll");
    $cgi->param(-name => 'dd_poll', -value => "$dd_poll");
    $cgi->param(-name => 'question', -value => "$question");
    $cgi->param(-name => 'choices', -value => "$c");
    $cgi->param(-name => 'setpoll', -value => "Set Poll");
    my $save_username = $UBERACC{'USERNAME'};
    $UBERACC{'USERNAME'} = "philip";
log_info("question=$question");

    my $message = process_setnewpoll();

    log_info("message=$message");
    $UBERACC{'USERNAME'} = $save_username;
}

############################################################

sub get_monthly_drivel
{
    my $dd = substr($YYYYMMDD, 6, 2);
#    my $drivel = qq(FISH);
    my ($fname) = "${REFROOT}/monthly_drivel.dat";
    open (INF, "$fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($day_num, $message, $link)
            = split /;/, $_;
        if ($dd eq $day_num)
        {
            $drivel = "$message\n";
            $drivel .= "$link\n" if ($link ne "");
            last;
        }
    }
    return $drivel;
}

############################################################

sub make_daily_drivel
{
    makedir("${SHAREDROOT}/drivel");
    my $drivel_file = "${SHAREDROOT}/drivel/drivel_${YYYYMMDD}.txt";
log_info("make_daily_drivel() drivel_file=$drivel_file");
log_info("make_daily_drivel() EVENTS_FILE=$EVENTS_FILE");
log_info("make_daily_drivel() DATAROOT=$DATAROOT");

log_info("make_daily_drivel() DATE_FILE=$DATE_FILE");

    my $poodate = date_manip("-c 20000727 $YYYYMMDD"); #Num days since 27 July 2000
#    $poodate--; # dirty fix to some problem with dreamhost's time zone that I don't understand.
log_info("make_daily_drivel() YYYYMMDD=$YYYYMMDD poodate=$poodate");

    my $today = date_manip("-fDAYOFWEEK_DD_MONTH_YEAR");
    my $monthDD = date_manip("-fMONTH_DD");
    $monthDD =~ s/\s//g;

    my $events = 0;
    my $events_file = "${DATAROOT}/../tripe/public/data/general/events.dat";
    my $events_file2 = "${DATAROOT}/../tripe/public/data/events/$monthDD";
log_info("make_daily_drivel() events_file=$events_file");
log_info("make_daily_drivel() events_file2=$events_file2");

    # test if today's drivel file exists yet
    open (DRIVEL, "$drivel_file");
    my $test = <DRIVEL>;
    close(DRIVEL);
    if ($test)
    {
        log_info("drivel_file already exists: $drivel_file");
        return;
    }
    log_info("Making drivel_file: $drivel_file");

    open (DRIVEL, ">$drivel_file");
    print DRIVEL "Daily Drivel - Poodate: $poodate ($today)\n\n";

    if (open (EVENTFILE, "$events_file"))
    {
        while (<EVENTFILE>)
        {
            chop;
            ($new, $eventMonthDD, $text) = split /;/, $_, 3;
            if ($monthDD eq $eventMonthDD)
            {
                if ($events > 0) {print DRIVEL "---------\n";}
                $events++;
                $text =~ s/<br>/\n/g;  # FISH untested
                print DRIVEL "$text\n";
            }
        }
        close (EVENTFILE);
    }

    if (open DATEFILE, "$EVENTDIR/$fname")
    {
        if ($events > 0) {print DRIVEL "-------------\n";}

        while (<DATEFILE>) 
        {
            s/<br>/\n/g;  # FISH untested
            print DRIVEL $_; 
        }
        close (DATEFILE);
        $events++;
    }
    if ($events > 0) {print DRIVEL "\n\n";}

    # Include monthly messages
    my $monthly_drivel = get_monthly_drivel();
    print DRIVEL $monthly_drivel;

    # Put Today's Poem in Drivel File
    $POEMS_FIXED_FILE = "${DATAROOT}/../tripe/public/data/meta/poems_fixed.dat";
    $SHITE_INDEX_FILE = "${DATAROOT}/../tripe/public/data/meta/shite_index.dat";

log_info("make_daily_drivel() POEMS_FIXED_FILE=$POEMS_FIXED_FILE");
    require "tripe/stuff_funcs.pl";
    # Because tripe/stuff_funcs.pl defines its own log_info
    # logs from this point get written to ../htdocs/uber/logs/pooclub/pages_.log
    # so we now have to use log_info

    my $poem_record = todays_poem($YYYYMMDD);
    my ($shiteId, $poemTitle, $poemAuthor, $poemType, $imageCode)
        = split /;/, $poem_record;

log_info("make_daily_drivel() shiteId=$shiteId");
    my $poem_file = "${DATAROOT}/../tripe/public/data/poetry/${shiteId}.txt";
    open (POEM_FILE, "$poem_file");
    print DRIVEL qq(
Poem Of The Day
---------------

$poemTitle
($poemAuthor)
);
    while(<POEM_FILE>)
    {
        next if (/^#/);
        s/<br>/\n/g;  # FISH untested
        print DRIVEL $_;
    }
    close(POEM_FILE);

    print DRIVEL qq(
-------------------
For quick links to important pooclub pages, 
bookmark this:
  http://pooclub.shite.org/map

The Shit At The End
-------------------
If you’ve received this email it’s either because the
‘Daily Drivel’ box in your poopages account has been 
selected or because you've been foolish enough to wander 
into the pooclub forum.  
If you don’t want this bollocks anymore you can deselect 
it by editing your poopages account here:

  http://pooclub.shite.org/account

or change your mailing options in the forum here:

  http://groups.google.com/group/pooclub

or you can email us and we’ll sort it out for you. 
(Please quote your user id)

  pooclub\@shite.org

pooclub admin
);

    close(DRIVEL);

    check_daily_drivel();
    send_daily_drivel($UBERENV{GROUP_EMAIL}); # to pooclub forum
}

############################################################
#
# Check if any users want Daily Drivel sent to their
# personal email address

sub check_daily_drivel
{
    log_info("check_daily_drivel() Checking Daily Drivel for email");
    my $fname;
    my $dir;
    my %account;
    my @loginfiles = <${LOGINROOT}/*/login.dat>;
    for $fname (@loginfiles)
    {
        $dir = $fname;
        $dir =~ s/\/login.dat//;
        ($user_id, $tmp) = split /\./, basename($dir);
        read_login_file(\%account, $user_id);
        $daily = $account{'DAILY'};
        $email = $account{'EMAIL'};
log_info("check_daily_drivel() user_id=$user_id daily=$daily email=$email");
        if (($daily eq "1") && ($email ne ""))
        {

#            if (($email =~ /@/) && ($email =~ /\./))
            if (valid_email_address($email))
            {
                send_daily_drivel($email);
            }
            else
            {
                log_info("WARNING $user_id has bad email address: $email");
            }
        }
    }
}

############################################################
#
# Post Daily Drivel to pooclub forum

sub send_daily_drivel
{
    my ($to_email) = @_;
log_info("send_daily_drivel()");
    my $drivel_file = "${SHAREDROOT}/drivel/drivel_${YYYYMMDD}.txt";
    my $poodate = date_manip("-c 20000727 $YYYYMMDD");
    my $subject = "Daily Drivel $poodate";
log_info("send_daily_drivel() YYYYMMDD=$YYYYMMDD poodate=$poodate");
log_info("send_daily_drivel() Sending mail to $to_email from ADMIN_EMAIL=$UBERENV{ADMIN_EMAIL} subject=$subject");

    email_notify_file($to_email,
                      $UBERENV{ADMIN_EMAIL},
                      "$subject",
                      "$drivel_file",
                      "Daily Drivel");
}

############################################################
#
# email today's topic

sub post_todays_topic
{
    log_info("post_todays_topic()");

    my $mailto = $UBERENV{'GROUP_EMAIL'};
#$mailto = $UBERENV{'EMAIL'};              # mike2sheds@gmail.com
    my $mailfrom = $UBERENV{'ADMIN_EMAIL'};
    my $mailname = qq(Today's Topic);
    my $user;
    my $subject;
    my $message;
    my $signature;

    # look for a scheduled topic for today
    my $fname = read_topic_file(\$user, \$subject, \$message, $YYYYMMDD);

    if ($fname eq "") # try for a queued topic
    {
        my @num_list = get_queued_topic_num_list();
        my $num = $num_list[0];
        $fname = read_topic_file(\$user, \$subject, \$message, $num);
        write_log("No scheduled topic for $YYYYMMDD - topic num=$num");
    }

    if ($fname ne "")
    {

        log_info("Found topic file: $fname");

        my $today = date_manip();
        my $date_file = "${SHAREDROOT}/latest_topic_date.txt";
        open (DATE, "$date_file");
        my $latest_topic_date = <DATE>;
        close(DATE);
    
    log_info("FISH latest_topic_date=$latest_topic_date today=$today");

        if ($today <= $latest_topic_date)
        {
            log_info("Cannot post topic - a topic has already been posted today");
            return;
        }


        # record today's date as latest date
        open (DATE, ">$date_file");
        print DATE $today;
        close(DATE);

        open(SENDMAIL, "|$SENDMAIL") 
            or $error = qq(ERROR - Sorry, cannot send topic.);
        print SENDMAIL qq(To: $mailto
From: "$mailname" <$mailfrom>
Subject: Today's Topic: $subject
Content-type: text/plain

$message

$signature
------------------------------
To set a topic of your own:
http://pooclub.shite.org/topic
------------------------------
);
        close(SENDMAIL);
        log_info("Sent topic from '$user' to $mailto on '$subject'");
        makedir("${SHAREDROOT}/topics/posted");
        move ("$fname", "${SHAREDROOT}/topics/posted");
#        $fname =~ s/topics/topics\/posted/; # add posted subdir to filename
        $fname = basename($fname);

        # record topic in history of posted topics
        my $history_file = "${SHAREDROOT}/topics/topic_history.dat";
        open (HISTORY, ">>$history_file") or log_error("Cannot write to topic history file: $history_file");
        print HISTORY qq(${YYYYMMDD};${subject};${user};${fname};\n);
        close(HISTORY);
    }
    else
    {
        write_log("No queued topics");
    }
}

############################################################

sub get_topic_file_info
{
    my ($fname) = @_;
    log_info("get_topic_file_info($fname)");

    open (TOPIC, "$fname");
    $user = <TOPIC>;
    chop($user);
    $subject = <TOPIC>;
    chop($subject);
    close(TOPIC);

    return ($user, $subject);
}


############################################################

sub zz_read_topic_file
{
    my ($user_ref, $subject_ref, $message_ref, $yyyymmdd) = @_;
#    $yyyymmdd = $YYYYMMDD if ($yyyymmdd eq "");
    my $fname = $yyyymmdd;

    log_info("read_topic_file($yyyymmdd)");

    if ($fname =~ /\w/) # filename has been provided
    {
log_info("Using fname=$fname");
    }
    elsif ($yyyymmdd > 20000000) # it's a scheduled topic
    {
        $fname = "${SHAREDROOT}/topics/scheduled_${yyyymmdd}.txt";
    }
    else
    {
        $fname = "${SHAREDROOT}/topics/queued_${yyyymmdd}.txt";
    }
log_info("Looking for file: $fname");
    my $found = 1;
    open (TOPIC, "$fname") or $found = 0;
log_info("found=$found");

    if ($found == 1)
    {
        log_info("Found topic file: $fname");
        $$user_ref = <TOPIC>;
        chop($$user_ref);
        $$subject_ref = <TOPIC>;
        chop($$subject_ref);
        while(<TOPIC>)
        {
            chop;
            $$message_ref .= $_;
        }

        close(TOPIC);
        return $fname;
    }
    else
    {
        $$user = "";
        $$subject = "";
        $$message = "";
    }
    return "";
}

############################################################

sub read_topic_file
{
    my ($user_ref, $subject_ref, $message_ref, $id) = @_;

    log_info("read_topic_file($id)");

log_info("read_topic_info() calling make_topic_filename($id)");
    my $fname = make_topic_filename($id);

log_info("Looking for file: $fname");

    if (-e $fname) # file exists
    {
        log_info(" Found topic file: $fname");

        open (TOPIC, "$fname") or log_error("Cannot open topic file: $fname");
        $$user_ref = <TOPIC>;
        chop($$user_ref);
        $$subject_ref = <TOPIC>;
        chop($$subject_ref);
        while(<TOPIC>)
        {
            chop;
            $$message_ref .= $_;
        }

        close(TOPIC);
        return $fname;
    }
    else
    {
        log_info(" No topic file: $fname");
        $$user = "";
        $$subject = "";
        $$message = "";
    }
    return "";
}


############################################################

sub make_topic_filename
{
    my ($id, $subdir) = @_;
    my $fname;
    if ($id =~ /^\d+/) # purely numeric id
    {
        if ($id > 20000000) # use id as yyyymmdd
        {
            $fname = "${SHAREDROOT}/topics/scheduled_${id}.txt";
        }
        else # treat it as a sequence number
        {
            $fname = "${SHAREDROOT}/topics/queued_${id}.txt";
        }        
    }
    elsif ($id =~ /\.txt$/) # id already contains the filename
    {
        if ($id =~ /\/topics\//) # assume it comprises the
        {                        # full file path too
            $fname = $id;
        }
        else
        {
            $fname = "${SHAREDROOT}/topics/${subdir}/$id";
        }
    }
    else
    {
        $fname = "BAD_TOPIC_FILENAME";
        log_error("make_topic_filename() fname=$fname Cannot make topic filename from id=$id subdir=$subdir");
    }
}

############################################################

sub process_new_poll_notify
{
    log_info("FISH process_new_poll_notify");
    log_info("FISH2 process_new_poll_notify");
}


############################################################
#
# Allow user to post to pooclub under an alias
# e.g. Carol Vorderman
#      Prince Philip
#
############################################################

sub print_postas_form_page
{
    my $who = $cgi->param('who');
    my $title = "Post as ...";
    my $whoami = username_and_priv();

    my ($fname) = "${REFROOT}/postas.dat";
    open (INF, "$fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($id, $from_name, $from_email, $to_name, $to_email, $signature)
            = split /;/, $_;
        last if ($who eq $id);
    }

#log_info("FISH from_name=$from_name");
#log_info("FISH from_email=$from_email");
    my $mailfrom = qq("$from_name"<$from_email>);
#$mailfrom = '"' . $from_name . '" <' . $from_email . '>';
$mailfrom = $from_email;

#log_info("FISH mailfrom=$mailfrom");
    my $mailfrom_html = qq(<b>"$from_name"</b>&lt;$from_email&gt;);
    my $mailto = "$to_name<$to_email>";
$mailto = $to_email;
    my $mailto_html = "<b>$to_name</b>&lt;$to_email&gt;";
    my $disabled = "";

    if ($UBERACC{'PRIVILEGE'} < 2)
    {
        $warning = qq(Only managers may post as celebrity pooclubbers.);
        $disabled = qq(disabled="disabled");
    }

    print_html_head();
    print qq(
     <br>
     <form method="POST" 
           action="$THIS_SCRIPT" 
           enctype="application/x-www-form-urlencoded">
      <table class="basic_c" style="width: 400;">
       <tr>
        <td class="basic_title_c" colspan="4"><nobr>$title</nobr><p></td>
       </tr>
    );

    if ($warning ne "")
    {
        print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic_warning" colspan="2">$warning</td>
       </tr>
        );
    }

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Login:</td>
        <td class="basic">$whoami</td>
        <td class="basic">&nbsp;</td>
       </tr>
    ) if (is_logged_in());

    print qq(<tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">From:</td>
        <td class="basic">$mailfrom_html
         <input type="hidden" name="mailfrom" value="$mailfrom" />
         <input type="hidden" name="from_email" value="$from_email" />
         <input type="hidden" name="from_name" value="$from_name" />
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">To:</td>
        <td class="basic">$mailto_html<input type="hidden" name="mailto" value="$mailto" />
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Subject:</td>
        <td class="basic"><input type="text" name="subject" value="" size="79" maxlength="79" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Message:</td>
        <td class="basic"><textarea name="message" cols="60" rows="20">$message</textarea></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Signature:</td>
        <td class="basic">$signature<input type="hidden" name="signature" value="$signature" />
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="submit" name="postas" value="Send" $disabled />&nbsp;&nbsp;&nbsp;
        </td>
        <td class="basic" style="vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?">home</a>&nbsp;&nbsp;&nbsp;
        </td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
       </tr>
      </table>
     </form>
    );

    print_html_end();
    exit(0);
}

############################################################
#
# Allow user to set a Today's Topic for pooclub
#
############################################################

sub print_topic_form_page
{
    my $yyyymmdd = $cgi->param('d');

    log_info("print_topic_form_page(yyyymmdd=$yyyymmdd)");

    my $warning = "";
    my $whoami = username_and_priv();
    my $title = qq(Set A Queued Topic);
    my $date = qq(the next available date);

    if ($yyyymmdd > 20000000) # it's a scheduled topic
    {
        $title = qq(Set A Scheduled Topic);
        $date = date_manip("-fDAYOFWEEK_DD_MONTH_YYYY $yyyymmdd");
    }

    if (! is_logged_in())
    {
        $warning = qq(You are not logged in.
If you set a topic without being logged in, others may
edit or delete your topic before it is posted.
However, if you log in then only you will be able to edit
or delete your topic.);
    }

    my $user = "";
    my $subject = "";
    my $message = "";
    my $fname = read_topic_file(\$user, \$subject, \$message, $yyyymmdd);
log_info("user=$user subject=$subject message=$message");

#    open (INF, "$fname");
#    while(<INF>)
#    {
#        chop;
#        next if (/^#/);
#        next if (/^\s*$/);
#        ($id, $from_name, $from_email, $to_name, $to_email, $signature)
#            = split /;/, $_;
#        last if ($who eq $id);
#    }

    my $disabled = "";

#    if ($UBERACC{'PRIVILEGE'} < 2)
#    {
#        $warning = qq(Only managers may set a topic.);
#        $disabled = qq(disabled="disabled");
#    }

    print_html_head();
    print_small_login_line();
    print qq(
     <br>
     <form method="POST" 
           action="$THIS_SCRIPT" 
           enctype="application/x-www-form-urlencoded">
      <table class="basic_c" style="width: 400;">
       <tr>
        <td class="basic_title_c" colspan="4"><nobr>$title</nobr><p></td>
       </tr>
    );

    if ($warning ne "")
    {
        print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic_warning" colspan="2">$warning</td>
       </tr>
        );
    }

    print qq(<tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic"><br />
Enter your topic in the form below.  
Your topic will then be posted to the pooclub forum on 
<b>$date</b> 
where it will be discussed in detail by our professional 
body of bickerers and nit pickers.  
Make sure you are subscribed to the forum if you want 
to see their responses.
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Today's&nbsp;Topic:</td>
        <td class="basic"><input type="text" name="subject" value="$subject" size="79" maxlength="79" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Introduction:</td>
        <td class="basic"><textarea name="message" cols="60" rows="12">$message</textarea></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="hidden" name="p" value="topicthankyou" />
         <input type="hidden" name="yyyymmdd" value="$yyyymmdd" />
         <input type="hidden" name="date" value="$date" />
         <input type="submit" name="topic" value="Send" $disabled />&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?p=topic">back to topics</a>
        </td>
        <td class="basic" style="vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?">home</a>&nbsp;&nbsp;&nbsp;
        </td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
If you'd like to propose a Today's Topic but have got 
a bit of shiter's block regarding the introduction, 
why not use our template topic introduction below? 
Simply copy and paste the below text replacing the words 
in angle brackets with ones applicable to your topic. 
<p />
<table border="1"><tr><td align="left">
<pre>
Today's Topic: &lt;Wibbles&gt;

Love them, loathe them, or simply ignore them, it's difficult 
to imagine a world without &lt;wibbles&gt;. &lt;Wibbles&gt; have now become 
the &lt;thingiest&gt; thing since &lt;nubwarts&gt;, and look set to take 
over as the world's favourite &lt;barmuttock&gt;.

But what do really know about &lt;wibbles&gt; Can they ever be a 
suitable replacement for &lt;ninglummies&gt;? And is there any truth 
in the recent allegations about their tendency to &lt;hiberponge&gt;?

Pooclubbers, you decide.
</pre>
</td></tr></table><br clear="all" />
Then just post it to pooclub and enjoy the barrage of bollocks 
you'll get back in response.
<p />
Other ideas:
<ul>
 <li>An otherwise dull news item can be given a good freshen up in pooclub.</li>
 <li>A problem shared is a problem several people have.  Don’t be shy to trouble us with something that’s bothering you.  We just might be able to help.</li>
 <li>Sometimes pooclubbers have simply chosen Wikipedia’s current featured article and just cut-n-paste a couple of paragraphs from that.  That’s fine by us.</li>
</ul>
        </td>
        <td class="basic">&nbsp;</td>
       </tr>
      </table>
     </form>
    );

    print_html_end();
    exit(0);
}


############################################################
#
# Handle user's request to set a topic.
#
############################################################

sub process_topic
{
    log_info("process_topic()");
    my $num = $cgi->param('yyyymmdd');
    my $date = $cgi->param('date');
    my $subject = $cgi->param('subject');
    my $message = $cgi->param('message');
    my $fname;

    $subject =~ s/^\s*Today.*s\s*Topic//i;
    $subject =~ s/^\W+//;

    log_info("num=$num");
    log_info("subject=$subject");
    log_info("message=$message");

    log_action("set a topic for $date entitled '$subject'");
    makedir("${SHAREDROOT}/topics");

    if ($num eq "") # set a new queued topic
    {
        # assign next sequence number
        my $posted_num = get_latest_queued_topic_number("posted");
        my $pending_num = get_latest_queued_topic_number();
        $num = ($posted_num > $pending_num) ? $posted_num : $pending_num;
        $num = sprintf "%05d", $num + 1;
    }
log_info("process_topic() calling make_topic_filename($num)");
    my $fname = make_topic_filename($num);

#    if (length($num) < 8) # its a queued topic
#    {
#        $fname = "${SHAREDROOT}/topics/queued_${num}.txt";
#    }
#    else # num is yyyymmdd
#    {
#        $fname = "${SHAREDROOT}/topics/scheduled_${num}.txt";
#    }

    open(TOPIC, ">$fname") or log_error("Cannot write topic file: $fname");
    print TOPIC qq($UBERACC{'USERNAME'}
$subject
$message
);
    close(TOPIC);

    # if the sun's not yet over the yardarm
    my $hh = substr($HHMMSS, 0, 2);
    if ($hh < 12)
    {
        post_todays_topic();
    }
}


############################################################

sub get_queued_topic_num_list
{
    my ($subdir) = @_; # so we can get posted topics

    my @fname_list = <${SHAREDROOT}/topics/${subdir}/queued_*.txt>;
#    my $fnames = scalar(@fname_list);
    my $num;
    my @num_list;

    for $fname (@fname_list)
    {
        $num = $fname;
        $num =~ s/^.*queued_//;
        $num =~ s/\.txt$//;
        push @num_list, $num;
    }
    return sort @num_list;
}

############################################################

sub show_queued_topics
{
    my @fname_list = sort <${SHAREDROOT}/topics/queued_*.txt>;
    my $fnames = scalar(@fname_list);
    my $num;
    my $user;
    my $subject;
    print qq(There are $fnames queued topics.<br />);

    for $fname (@fname_list)
    {
        $num = $fname;
        $num =~ s/^.*queued_//;
        $num =~ s/\.txt$//;
        ($user, $subject) = get_topic_file_info($fname);
        if ($UBERACC{'PRIVILEGE'} > 3) # admin owner
        {
            print qq(
&nbsp;&nbsp;<a href="${THIS_SCRIPT}?page=topic&d=$num">q$num</a> [${user}] $subject - delete<br>
            );
        }
        elsif (($UBERACC{'USERNAME'} eq $user) || ($user eq ""))
        {
            print qq(
&nbsp;&nbsp;<a href="${THIS_SCRIPT}?page=topic&d=$num">q$num</a> [${user}] $subject<br>
            );
        }
        else
        {
            print qq(
&nbsp;&nbsp;<font color="gray">q$num private</font><br>
            );
        }
    }
}

############################################################
#
# called by:
# \sub show_topic_dates()
# in data/poo/pooclub_topic.html
#
# Shows list of scheduled topics and available dates

sub show_topic_dates
{
    my @args = @_;

#    print qq(
#   <a href="${THIS_CGI}?page=topic">
#    <img src="${IMGPOODIR}/topic3.jpg" border="0" zwidth="150" align="right"
#         alt="Today's Topic"></a>
#    );

    for my $arg (@args)
    {
        print qq(arg="$arg"<br>);
    }

    my $yyyymmdd = $YYYYMMDD;
    my $days_ahead = 10;
    my $last_date = date_manip("-d$days_ahead $YYYYMMDD");
    my $hh = substr($HHMMSS, 0, 2);
    my $date;
    my $user;
    my $subject;

    require("uber/uber_date.pl");

#    # Can't post for today if it's gone mid-day
    $yyyymmdd = date_manip("-d1 $yyyymmdd"); # if ($hh > 11);

    while($yyyymmdd < $last_date)
    {
        $fname = "${SHAREDROOT}/topics/scheduled_${yyyymmdd}.txt";

        ($user, $subject) = get_topic_file_info($fname);

        $yyyy = substr($yyyymmdd, 0, 4);
        $mm = substr($yyyymmdd, 4, 2) - 1;
        $dd = substr($yyyymmdd, 6, 2);
        $date = qq($dd $MonthList[$mm] $yyyy);
        ($thingy, $dow) = split / /, date_calc("-s $yyyymmdd");
        $dow = substr($dow, 0, 3);

        if (($UBERACC{'USERNAME'} eq $user) || ($user eq ""))
        {
            $user = "[" . $user . "]" if ($subject ne "");
            print qq(
            <nobr>&nbsp;&nbsp;<a href="${THIS_CGI}?page=topic&d=$yyyymmdd">$dow $date</a> $user</nobr> $subject<br />
            );
        }
        else
        {
            print qq(&nbsp;&nbsp;<font color="gray">$dow $date private</font><br />);
        }
        $yyyymmdd = date_manip("-d1 $yyyymmdd");
    }
    print qq(<br clear="all" />);
}

############################################################

sub get_latest_queued_topic_number
{
    my ($subdir) = @_;

    my @num_list = get_queued_topic_num_list($subdir);
    for my $num (@num_list)
    {
        log_info("SQUID num=$num");
    }
    if (scalar(@num_list) < 1)
    {
        return 0;
    }
    return $num_list[scalar(@num_list) - 1];
}

############################################################
#
# Handle user's request to post as someone else.
#
############################################################

sub process_postas_page
{
    my $title     = "Sent Poomail";
    my $mailto    = $cgi->param('mailto');
    my $mailfrom  = $cgi->param('mailfrom');
    my $from_email  = $cgi->param('from_email');
    my $from_name  = $cgi->param('from_name');
    my $subject   = $cgi->param('subject');
    my $message   = $cgi->param('message');
    my $signature = $cgi->param('signature');
    $signature =~ s/<br>/\n/;

    my $thankyou = "";
    my $error = "";
    $error .= "No subject. " if ($subject =~ /^\s*$/);
    $error .= "No message. " if ($message =~ /^\s*$/);

    if ($error eq "")
    {
        open(SENDMAIL, "|$SENDMAIL") 
            or $error = qq(ERROR - Sorry, cannot send email.);
        print SENDMAIL qq(To: $mailto
From: "$from_name" <$from_email>
Reply-to: $mailfrom
Subject: $subject
Content-type: text/plain

$message

$signature
);
        close(SENDMAIL);
        $thankyou = qq(Your message has been posted to $mailto);
        log_action("Post As: Sent mail from $mailfrom to $mailto subject: $subject");
    }
    else
    {
        $title = "Not $title";
        log_info("Post As: Not sent mail from $mailfrom to $mailto subject=$subject error=$error");
    }


    print_html_head();
    print qq(
     <br>
     <form method="POST" 
           action="$THIS_SCRIPT" 
           enctype="application/x-www-form-urlencoded">
      <table class="basic" width="400">
       <tr>
        <td colspan="4"><div class="basic_title" align="center">$title</div><br></td>
       </tr>
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic" colspan="2">
         $thankyou
         <div class="basic_warning">$error</div>
         <p></td>
        <td class="basic">&nbsp;</td>
       </tr>
    );

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Login:</td>
        <td class="basic" style="font-weight: bold">$UBERACC{'USERNAME'}</td>
        <td class="basic">&nbsp;</td>
       </tr>
    ) if ($UBERACC{'USERNAME'} ne "");

    print qq(<tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">From:</td>
        <td class="basic">$mailfrom</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">To:</td>
        <td class="basic">$mailto</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Subject:</td>
        <td class="basic">$subject</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Message:</td>
        <td class="basic">$message</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Signature:</td>
        <td class="basic">$signature</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;&nbsp;&nbsp;</td>
        <td class="basic"><a href="${THIS_SCRIPT}?">home</a>&nbsp;&nbsp;&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
       </tr>
      </table>
     </form>
    );

    print_html_end();
    exit(0);
}


############################################################
#
# Admin: edit cull candidates
#
############################################################

sub print_cull_candidates_form_page
{
    my ($message) = @_;
    my $title = "Edit Cull Candidates";
    my $message = qq(Checked candidates will appear in next month's cull.);
    my $warning = "";
    my $disabled = "";

    my $mday = substr($YYYYMMDD, 6, 2);
    if ($mday > 25) # Near end of month only administrators
    {               # may edit candidates
        if ($UBERACC{'PRIVILEGE'} < 3)
        {
            $message = qq(Only administrators may edit cull candidates near the end of the month.);
            $disabled = qq(disabled="disabled");
        }
    }
    else
    {
        if ($UBERACC{'PRIVILEGE'} < 2)
        {
            $message = qq(Only managers may edit cull candidates.);
            $disabled = qq(disabled="disabled");
        }
    }

    print_html_head();
    print_small_login_line();

    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$warning</div>

        <form method="POST"
              action="$THIS_SCRIPT"
              enctype="application/x-www-form-urlencoded">
         <table class="basic_c" style="width: 400;" border="0">
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" colspan="3">
            $message<p>
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
    );

    my $i = 0;
    my $cand_name;
    my $active_flag;
    my $checked;

    # Allow user to edit current candidates
    open(CULL, "${SHAREDROOT}/cull_candidates.dat");
    while(<CULL>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($cand_name, $active_flag) = split /;/;
        $checked = ($active_flag eq "1") ? qq(checked="checked") : "";

        print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="text-align: right;" >
            <input type="checkbox" name="flag$i" value="1" $checked $disabled />
           </td>
           <td class="basic">
            <input type="text" name="cand$i" value="$cand_name" size="30" maxlength="40" $disabled />
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
        );
        $i++;
    }
    close(CULL);

    # Allow user to add a new candidate
    print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="text-align: right;" >
            New
           </td>
           <td class="basic">
            <input type="text" name="cand$i" value="" size="30" maxlength="40" $disabled />
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
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
            <input type="hidden" name="cull_count" value="$i" />
            <input type="submit" name="cull_candidates" value="Apply Changes" $disabled />
            <a href="${THIS_SCRIPT}?page=admin">admin</a>
           </td>
           <td class="basic">
            &nbsp;
           </td>
          </tr>
         </table>
        </form>
    );

    print_copyright();
    print_html_end();

    exit(0);
}


############################################################
#
# Admin: "Apply Changes" to cull candidates file
#
############################################################

sub process_cull_candidates
{
    my $fname = "${SHAREDROOT}/cull_candidates.dat";
    log_info("Applying changes to cull candidates file: $fname");
    my $candidate;
    my $flag;
    my $count = $cgi->param('cull_count');

    open(CULL, ">$fname");
    if (! CULL)
    {
        log_info("ERROR process_cull_candidates() cannot open file $fname");
        return;
    }

    for (my $i = 0; $i <= $count; $i++)
    {
        $candidate = $cgi->param("cand$i");
        if ($candidate =~ /\w+/)
        {
            $flag = $cgi->param("flag$i");
            print CULL qq(${candidate};${flag};\n);
        }
    }
    log_action("Edited cull candidates.");
}


############################################################


############################################################

1;
############################################################
# EOF