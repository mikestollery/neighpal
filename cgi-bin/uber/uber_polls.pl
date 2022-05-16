############################################################
#
# uber_polls.pl
#
# Provides client with poll handling pages
#
# setpoll   - set a new poll
# polls     - view polls
# poll      - vote in a poll (or close a poll)
# 
#
############################################################



############################################################
#
# Handle polling requests
#
############################################################

sub uber_polls
{
    my $message = "";
    my $page = $cgi->param('page');
    my $id = $cgi->param('id');
    my $setpoll = $cgi->param('setpoll');

#write_log("FISH uber_polls() page=$page setpoll=$setpoll");
    if ($setpoll ne "") 
    {
#write_log("FISH uber_polls() calling process_setnewpoll()");
        $message = process_setnewpoll();
#write_log("FISH uber_polls() message=$message");
        if ($message eq "Your poll has been set up.")
        {
#write_log("FISH uber_polls() print_polls_index_page()");
            print_polls_index_page("Open", "$message");
        }
        else
        {
#write_log("FISH uber_polls() calling print_setnewpoll_form_page()");
            print_setnewpoll_form_page($message);
        }
    }
    elsif ($page eq "setpoll")
    {
#write_log("FISH2 uber_polls() calling print_setnewpoll_form_page()");
        print_setnewpoll_form_page();
    }
#    if (($page eq "setpoll") || ($cgi->param('setpoll')))
#    {
#        print_setpoll_form_page();
#    }
    elsif ($page eq "polls")
    {
        print_polls_index_page($cgi->param('show'));
    }
    elsif ($page eq "poll")
    {
        if ($id)
        {
            print_voting_page($id);
        }
        else
        {
            print_polls_index_page($cgi->param('show'));
        }
    }
    elsif ($cgi->param('vote') eq "Vote")
    {
        process_vote($id);
    }
    elsif ($cgi->param('vote') eq "Close")
    {
        process_close($cgi->param('id'), $UBERACC{'USERNAME'});
        print_voting_page($id);
    }

    if ($cgi->param('poll') eq "checkpolls")
    {
        check_for_expired_polls();
    }
}

############################################################
#
# set a new poll (to replace first part of print_setpoll_form_page

sub process_setnewpoll 
{
    my $message = "";
    my @choice_list = ();

    my $dd   = $cgi->param('dd_poll');
    my $mm   = $cgi->param('mm_poll');
    my $yyyy = $cgi->param('yyyy_poll');
    my $yyyymmdd = sprintf ("%04d%02d%02d", $yyyy, $mm, $dd);
    my $validate = date_manip("-c $yyyymmdd");

    my $question = $cgi->param('question');
    my $choices = $cgi->param('choices');

    write_log("process_setnewpoll() dd=$dd");
    write_log("process_setnewpoll() mm=$mm");
    write_log("process_setnewpoll() yyyy=$yyyy");
    write_log("process_setnewpoll() question=$question");
    write_log("process_setnewpoll() choices=$choices");

    $choices += 5 if (!$choices || ($choices < 1)
                   || ($cgi->param('setpoll') eq "More Choices"));

    for (my $c = 0; $c < $choices; $c++)
    {
        $choice_list[$c] = $cgi->param("choice$c");
    }

    my $warning = "";
    if ($cgi->param('setpoll'))
    {
        $warning .= qq(<br>No question.) if (!$question);
        $warning .= qq(<br>Must have two or more choices.) if (!$choice_list[1]);
        if ($validate > 0)
        {
            $warning .= ($validate > 1000000)
                ? qq(<br>Invalid closing date.)
                : qq(<br>Closing date has already passed.) ;
        }
    }

    # Process user's request to set up a poll
    if (($cgi->param('setpoll') eq "Set Poll") && !$warning)
    {
        $message = "Your poll has been set up.";

        # Get next poll id
        my $poll_id = 0;
        my $poll_dir = "${SHAREDROOT}/polls";
        makedir("$poll_dir");
        for my $id (<${poll_dir}/*.dat>)
        {
            $id =~ s/^.*poll_//;
            $id =~ s/\.dat$//;
            $poll_id = $id if ($id > $poll_id);
        }
        $poll_id++;

        # Save poll to file
        my $poll_file = sprintf ("%s/poll_%04d.dat", $poll_dir, $poll_id);
        my $today = date_manip("-fDD/MM/YYYY");
        $today =~ s/\//;/g;
        $question =~ s/;/,/g;
        open (OUTF, ">$poll_file") or $message = qq(Cannot save poll in file: $poll_file);
        print OUTF "$UBERACC{'USERNAME'};${today};Open;${dd};${mm};${yyyy};;;\n";
        print OUTF "$question\n";
        my $choice_info = "";
        my $count = 0;
        for my $choice (@choice_list)
        {
            $choice =~ s/;/,/g;
            if ($choice ne "")
            {
                $count++;
                print OUTF "CHOICE;${count};${choice};\n";
                $choice_info .= "${count}: $choice\n";
            }
        }
        close(OUTF);

        # Inform other users that a new poll has been set up
#        get_account_globals();
        my $display_name = display_name();
        my $poll_page = "${HTTP_HOST}$ENV{SCRIPT_NAME}?page=poll&id=$poll_id";
        my $poll_index = "${HTTP_HOST}$ENV{SCRIPT_NAME}?page=polls";
        $mm--;

        my $info = qq(
$display_name has set up a new poll which closes on $dd $MonthList[$mm] $yyyy.

"$question"

$choice_info

Do not reply to this email.
To cast your vote go to: $poll_page

To see all polls go to: $poll_index
        );

        write_action(qq(New poll $poll_id set by $display_name "$question"));
#write_log ("# uber_polls.pl print_setpoll_form_page() GROUP_EMAIL=$UBERENV{GROUP_EMAIL} ADMIN_EMAIL=$UBERENV{ADMIN_EMAIL}");

        # Send email notification to all POLLS subscribers and GROUP_EMAIL
        my @email_list = get_email_list("POLLS");
        push @email_list, $UBERENV{GROUP_EMAIL} if ($UBERENV{GROUP_EMAIL} ne "");
        for $email (@email_list)
        {
            email_notify($email, $UBERENV{ADMIN_EMAIL}, "New poll",
                        "$info", $UBERENV{'APP_NAME'});
        }

#        print_polls_index_page("Open", "$message");
    }
    return $message;
}

############################################################
#
# Allow user to set a new poll.
#
############################################################

sub print_setnewpoll_form_page
{
    my ($message) = @_;
    my $title = "Set Poll";
    my @choice_list = ();

    my $dd   = $cgi->param('dd_poll');
    my $mm   = $cgi->param('mm_poll');
    my $yyyy = $cgi->param('yyyy_poll');
    my $yyyymmdd = sprintf ("%04d%02d%02d", $yyyy, $mm, $dd);
    my $validate = date_manip("-c $yyyymmdd");

    my $question = $cgi->param('question');
    my $choices = $cgi->param('choices');
    $choices += 5 if (!$choices || ($choices < 1)
                   || ($cgi->param('setpoll') eq "More Choices"));

    for (my $c = 0; $c < $choices; $c++)
    {
        $choice_list[$c] = $cgi->param("choice$c");
    }

    my $disabled = "";
    if ((!$question)
     || (!$choice_list[1])
     || ($validate > 0)
    )
    {
        $disabled = qq(disabled="1");
    }

    my $warning = "";
    if ($cgi->param('setpoll'))
    {
        $warning .= qq(<br>No question.) if (!$question);
        $warning .= qq(<br>Must have two or more choices.) if (!$choice_list[1]);
        if ($validate > 0)
        {
            $warning .= ($validate > 1000000)
                ? qq(<br>Invalid closing date.)
                : qq(<br>Closing date has already passed.) ;
        }
    }

    
    print_html_head();
    print_small_login_line();

    # Get user's request to set up a poll
    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$warning</div>
        <form method="POST" 
              action="$THIS_SCRIPT" 
              enctype="application/x-www-form-urlencoded">
         <table class="basic_c" style="width: 600;">
          <tr>
           <td class="basic">
            Closing Date
           </td>
           <td class="basic">
            <table class="basic">
             <tr>
    );

    date_input("poll", 0);

    print qq(
             </tr>
            </table>
           </td>
          </tr>
          <tr>
           <td class="basic">
            Question
           </td>
           <td class="basic">
            <textarea name="question" cols="60" rows="4">$question</textarea>
           </td>
          </tr>
    );

    for ($c = 0; $c < $choices; $c++)
    {
        $label = "Choice " . ($c + 1);
        print qq(
          <tr>
           <td class="basic">
            $label
           </td>
           <td class="basic">
            <input type="text" name="choice$c" value="$choice_list[$c]" size="79" maxlength="256" />
           </td>
          </tr>
        );
    }

    print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="text-align: left">
            <input type="hidden" name="choices" value="$choices" />
            <input type="submit" name="setpoll" value="Enter" />
            <input type="submit" name="setpoll" value="More Choices" />
            <input type="submit" name="setpoll" value="Set Poll" $disabled />
            <a href="${THIS_SCRIPT}?page=polls">polls</a>
            <a href="${THIS_SCRIPT}?">home</a>
           </td>
          </tr>
         </table>
        </form>
    );

    print_copyright();
    print_html_end();
    write_log(qq(print_setnewpoll_form_page() message="$message"));
    exit(0);
}

############################################################
#
# Allow user to set a poll.
#
############################################################

sub zz_print_setpoll_form_page
{
    my ($message) = @_;
    my $title = "Set Poll";
    my @choice_list = ();

    my $dd   = $cgi->param('dd_poll');
    my $mm   = $cgi->param('mm_poll');
    my $yyyy = $cgi->param('yyyy_poll');
    my $yyyymmdd = sprintf ("%04d%02d%02d", $yyyy, $mm, $dd);
    my $validate = date_manip("-c $yyyymmdd");

    my $question = $cgi->param('question');
    my $choices = $cgi->param('choices');
    $choices += 5 if (!$choices || ($choices < 1)
                   || ($cgi->param('setpoll') eq "More Choices"));

    for (my $c = 0; $c < $choices; $c++)
    {
        $choice_list[$c] = $cgi->param("choice$c");
    }

    my $disabled = "";
    if ((!$question)
     || (!$choice_list[1])
     || ($validate > 0)
    )
    {
        $disabled = qq(disabled="1");
    }

    my $warning = "";
    if ($cgi->param('setpoll'))
    {
        $warning .= qq(<br>No question.) if (!$question);
        $warning .= qq(<br>Must have two or more choices.) if (!$choice_list[1]);
        if ($validate > 0)
        {
            $warning .= ($validate > 1000000)
                ? qq(<br>Invalid closing date.)
                : qq(<br>Closing date has already passed.) ;
        }
    }

    # Process user's request to set up a poll
    if (($cgi->param('setpoll') eq "Set Poll") && !$warning)
    {
        my $message = "Your poll has been set up.";

        # Get next poll id
        my $poll_id = 0;
        my $poll_dir = "${SHAREDROOT}/polls";
        makedir("$poll_dir");
        for my $id (<${poll_dir}/*.dat>)
        {
            $id =~ s/^.*poll_//;
            $id =~ s/\.dat$//;
            $poll_id = $id if ($id > $poll_id);
        }
        $poll_id++;

        # Save poll to file
        my $poll_file = sprintf ("%s/poll_%04d.dat", $poll_dir, $poll_id);
        my $today = date_manip("-fDD/MM/YYYY");
        $today =~ s/\//;/g;
        $question =~ s/;/,/g;
        open (OUTF, ">$poll_file") or $message = qq(Cannot save poll in file: $poll_file);
        print OUTF "$UBERACC{'USERNAME'};${today};Open;${dd};${mm};${yyyy};;;\n";
        print OUTF "$question\n";
        my $choice_info = "";
        my $count = 0;
        for my $choice (@choice_list)
        {
            $choice =~ s/;/,/g;
            if ($choice ne "")
            {
                $count++;
                print OUTF "CHOICE;${count};${choice};\n";
                $choice_info .= "${count}: $choice\n";
            }
        }
        close(OUTF);

        # Inform other users that a new poll has been set up
#        get_account_globals();
        my $display_name = display_name();
        my $poll_page = "${HTTP_HOST}$ENV{SCRIPT_NAME}?page=poll&id=$poll_id";
        my $poll_index = "${HTTP_HOST}$ENV{SCRIPT_NAME}?page=polls";
        $mm--;

        my $info = qq(
$display_name has set up a new poll which closes on $dd $MonthList[$mm] $yyyy.

"$question"

$choice_info

Do not reply to this email.
To cast your vote go to: $poll_page

To see all polls go to: $poll_index
        );

        write_action(qq(New poll $poll_id set by $display_name "$question"));
#write_log ("# uber_polls.pl print_setpoll_form_page() GROUP_EMAIL=$UBERENV{GROUP_EMAIL} ADMIN_EMAIL=$UBERENV{ADMIN_EMAIL}");

        # Send email notification to all POLLS subscribers and GROUP_EMAIL
        my @email_list = get_email_list("POLLS");
        push @email_list, $UBERENV{GROUP_EMAIL} if ($UBERENV{GROUP_EMAIL} ne "");
        for $email (@email_list)
        {
            email_notify($email, $UBERENV{ADMIN_EMAIL}, "New poll",
                        "$info", $UBERENV{'APP_NAME'});
        }

        print_polls_index_page("Open", "$message");
    }
    
    print_html_head();
    print_small_login_line();

    # Get user's request to set up a poll
    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$warning</div>
        <form method="POST" 
              action="$THIS_SCRIPT" 
              enctype="application/x-www-form-urlencoded">
         <table class="basic_c" style="width: 600;">
          <tr>
           <td class="basic">
            Closing Date
           </td>
           <td class="basic">
            <table class="basic">
             <tr>
    );

    date_input("poll", 0);

    print qq(
             </tr>
            </table>
           </td>
          </tr>
          <tr>
           <td class="basic">
            Question
           </td>
           <td class="basic">
            <textarea name="question" cols="60" rows="4">$question</textarea>
           </td>
          </tr>
    );

    for ($c = 0; $c < $choices; $c++)
    {
        $label = "Choice " . ($c + 1);
        print qq(
          <tr>
           <td class="basic">
            $label
           </td>
           <td class="basic">
            <input type="text" name="choice$c" value="$choice_list[$c]" size="79" maxlength="256" />
           </td>
          </tr>
        );
    }

    print qq(
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="text-align: left">
            <input type="hidden" name="choices" value="$choices" />
            <input type="submit" name="setpoll" value="Enter" />
            <input type="submit" name="setpoll" value="More Choices" />
            <input type="submit" name="setpoll" value="Set Poll" $disabled />
            <a href="${THIS_SCRIPT}?page=polls">polls</a>
            <a href="${THIS_SCRIPT}?">home</a>
           </td>
          </tr>
         </table>
        </form>
    );

    print_copyright();
    print_html_end();
    write_log(qq(print_setpoll_form_page() message="$message"));
    exit(0);
}

############################################################
#
# Show menu of all polls
#
#
############################################################

sub print_polls_index_page
{
    my ($show_status, $message) = @_;
    my $title = "Polls";
    my $vote_link;
    my $show_link = "all";
    $show_link = "open" if (lc($show_status) eq "all");

#write_log("print_polls_index_page() 1");
    print_html_head();
    print_small_login_line();

    print qq(
        <div class="basic_title_c">$title</div>
        <div class="basic_warning" style="text-align: center">$message</div>
        <div class="basic" style="text-align: right">
         <a href="${THIS_SCRIPT}?page=polls&show=$show_link">show $show_link</a>
       | <a href="${THIS_SCRIPT}?page=setpoll">set a new poll</a>
       | <a href="${THIS_SCRIPT}?">home</a>
        </div>
        <table class="basic" style="width: 600">
         <tr>
          <td class="basic" style="font-weight: bold">&nbsp;</td>
          <td class="basic" style="font-weight: bold">Owner</td>
          <td class="basic" style="font-weight: bold" colspan="3">Start</td>
          <td class="basic" style="font-weight: bold">&nbsp;</td>
          <td class="basic" style="font-weight: bold" colspan="3">End</td>
          <td class="basic" style="font-weight: bold">Status</td>
          <td class="basic" style="font-weight: bold">Question</td>
          <td class="basic" style="font-weight: bold">&nbsp;</td>
         </tr>
    );

#write_log("print_polls_index_page() 2");
    for my $fname (sort rev_sort (<${SHAREDROOT}/polls/poll_*.dat>))
    {
        $id = $fname;
        $id =~ s/^.*poll_0*//;
        $id =~ s/\.dat$//;

        open (INF, "$fname");
        ($user, $dd_o, $mm_o, $yyyy_o, $status, $dd_c, $mm_c, $yyyy_c)
            = split /;/, <INF>;
        my $line;
        my $question = "";
        while(<INF>)
        {
            chop;
            last if (/^CHOICE/);
            $question .= $_;
        }
        close(INF);

#write_log("print_polls_index_page() 3");
        my $closing_date = sprintf ("%04d%02d%02d", $yyyy_c, $mm_c, $dd_c);
        my $today = date_manip("-fYYYYMMDD");
        $status = "Closed" if ($closing_date < $today);


        $vote_link = (lc($status) eq "open") ? "vote" : "view";
        $show_user = get_name_for_display($user);

#write_log("print_polls_index_page() 4");
        if ((lc($status) eq "open") || (lc($show_status) eq "all"))
        {
            $mon_o = substr($MonthList[$mm_o - 1], 0, 3);
            $mon_c = substr($MonthList[$mm_c - 1], 0, 3);
            print qq(
         <tr>
          <td class="basic" style="vertical-align: top">
           <a href="${THIS_SCRIPT}?page=poll&id=$id">$id</a>
          </td>
          <td class="basic" style="vertical-align: top">
           $show_user
          </td>
          <td class="basic" style="vertical-align: top; text-align: right">
           $dd_o
          </td>
          <td class="basic" style="vertical-align: top">
           $mon_o
          </td>
          <td class="basic" style="vertical-align: top">
           $yyyy_o
          </td>
          <td class="basic" style="vertical-align: top">
           -
          </td>
          <td class="basic" style="vertical-align: top; text-align: right">
           $dd_c
          </td>
          <td class="basic" style="vertical-align: top">
           $mon_c
          </td>
          <td class="basic" style="vertical-align: top">
           $yyyy_c
          </td>
          <td class="basic" style="vertical-align: top">
           $status
          </td>
          <td class="basic" style="vertical-align: top">
           $question
          </td>
          <td class="basic" style="vertical-align: top">
           <a href="${THIS_SCRIPT}?page=poll&id=$id">$vote_link</a>
          </td>
         </tr>
            );
        }
    }

    print qq(
        </table><p>
    );

#write_log("print_polls_index_page() 5");
    print_copyright();
    print_html_end();
#    write_log("$message");
    exit(0);
}

############################################################

sub print_voting_page
{
    my ($id) = @_;
    my $title = "Vote";
    my $warning = "";
    my $num;

    print_html_head();
    print_small_login_line("poll id: <b>$id</b>");

    # read poll details
    my @choice_list = ();
    my $poll_file = sprintf ("%s/polls/poll_%04d.dat", $SHAREDROOT, $id);
    open (POLL, "$poll_file") or $warning .= qq( Cannot read poll file: $poll_file);
    my ($owner, $dd_o, $mm_o, $yyyy_o, $status, $dd_c, $mm_c, $yyyy_c, $closed_by)
        = split /;/, <POLL>;
    my %owner_acc = {};
    read_login_file(\%owner_acc, $owner);
    my $display_owner = ($owner_acc{'REALNAME'}) ?
       "$owner_acc{'REALNAME'} ($owner_acc{'USERNAME'})" : $owner_acc{'USERNAME'};
    my $question = "";
    my $closing_date = sprintf ("%04d%02d%02d", $yyyy_c, $mm_c, $dd_c);
    my $today = date_manip("-fYYYYMMDD");
    $mm_o--;
    $mm_c--;
    while (<POLL>)
    {
        chop;
        next if (!/\w/);
        ($label, $num, $choice) = split /;/, $_;
        if ($label eq "CHOICE")
        {
            push (@choice_list, $choice);
        }
        else
        {
            $question .= "$_<p>";
        }
    }
    close(POLL);

    # Deal with status
    $question =~ s/<p>$//;
    my $disabled = "";
    $status = "Closed" if ($closing_date < $today);
    $warning .= " Expired" if (lc($status) ne "open");
    $warning = " Closed by $closed_by" if ($closed_by);
    $disabled = qq(disabled="disabled") if ((lc($status) ne "open")
                                         || !(is_logged_in)
                                         || ($closed_by));
    my $close = (lc($status) ne "open") ? "closed" : "closes";

    # Now read votes cast
    my %user_vote_hash = {}; # keyed on user
    my %user_comment_hash = {};
    my $mycomment;
    my $votes_file = sprintf ("%s/polls/votes_%04d.dat", $SHAREDROOT, $id);
    open (INF, "$votes_file"); # or $warning .= qq( Cannot read votes file: $votes_file);
    while (<INF>)
    {
        chop;
        next if (!/\w/);
        ($timestamp, $user, $num, $comment) = split /;/, $_;
        $user_vote_hash{$user} = $num;
        $user_comment_hash{$user} = $comment;
        $mycomment = $comment if ($UBERACC{'USERNAME'} eq $user);
    }
    close(INF);

    # analyse
    %choice_count_hash = {}; # keyed on choice num
    %choice_voters_hash = {};
    $num_comments = 0;
    for $user (keys %user_vote_hash)
    {
        $choice_count_hash{$user_vote_hash{$user}}++;
        $choice_voters_hash{$user_vote_hash{$user}} .= " ${user},";
        $num_comments++ if ($user_comment_hash{$user});
    }

    # Write a text based version of the poll to file
    # This can be used for emailing results and voting
    # progress to members.
    $question_txt = $question;
    $question_txt =~ s/<p>/\n  /g;
    my $report_file = sprintf ("%s/polls/report_%04d.txt", $SHAREDROOT, $id);
    open (REP, ">$report_file");
    print REP qq(
Poll set by $display_owner on $dd_o $MonthList[$mm_o] $yyyy_o - $warning

"$question_txt"
    );

    # Begin writing poll details to the browser
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
           <td class="basic">
            This poll was set by $display_owner on $dd_o $MonthList[$mm_o] $yyyy_o
            and $close on $dd_c $MonthList[$mm_c] ${yyyy_c}.
    );

    if (! is_logged_in())
    {
        print qq(
            <p>You need to be logged in to vote in a poll:
            <a href="${THIS_SCRIPT}?page=login">login</a> |
            <a href="${THIS_SCRIPT}?page=sign">signup</a>
        );
    }

    print qq(
           </td>
          </tr><tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="font-weight: bold">
            <br>"$question"<p>
           </td>
          </tr><tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic">
            <table class="basic">
    );

    for (my $c = 1; $c <= scalar(@choice_list); $c++) # display each choice
    {
        chop($choice_voters_hash{$c});
        $num_votes = $choice_count_hash{$c};
        $num_votes = 0 if (!$num_votes);
        $detail_line = "$num_votes vote";
        $detail_line .= "s" if ($num_votes != 1);
        $detail_line .= " - $choice_voters_hash{$c}" if ($num_votes > 0);

        $checked = ($user_vote_hash{$UBERACC{'USERNAME'}} == $c) ? qq(checked="checked") : "";
        print qq(
             <tr>
              <td class="basic">
               <input type="radio" name="choice" value="$c" $checked $disabled />
              </td>
              <td class="basic" style="font-weight: normal">
               $choice_list[$c - 1]<br>
               <div class="basic_faint">$detail_line</div>
              </td>
             </tr>
        );

        print REP qq(
 - $choice_list[$c - 1]
      $detail_line
);
    }

    # You can only close a poll if you're its owner or more senior than the owner
    my $close_disabled = ((($UBERACC{'USERNAME'} ne $owner)
                        && ($UBERACC{'PRIVILEGE'} <= $owner_acc{'PRIVILEGE'}))
                       || $disabled) ? 
        qq(disabled="disabled") : "";

    print qq(
            </table>
           </td>
          </tr>
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="font-weight: normal">
            <br><b>Optional:</b> Make a comment<br>
            <input type="text" name="comment" value="$mycomment" size="80" maxlength="200" />
           </td>
          </tr>
          <tr>
           <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="font-weight: normal">
            <input type="hidden" name="id" value="$id" />
            <input type="submit" name="vote" value="Vote" $disabled />
            <input type="submit" name="vote" value="Close" $close_disabled />
            <a href="${THIS_SCRIPT}?page=polls">polls</a>
            <a href="${THIS_SCRIPT}?">home</a>
           </td>
          </tr>
          <tr>
          <td class="basic">
            &nbsp;
           </td>
           <td class="basic" style="font-weight: normal">
    );

    if ($num_comments > 0) # display all comments
    {
        print qq(
            <table class="basic">
             <tr>
              <td class="basic" style="font-weight: bold" colspan="2"><br>Comments</td>
             </tr>
        );
        print REP qq(
Comments:
);
        for $user (keys %user_comment_hash)
        {
            $show_user = get_name_for_display($user);
            if ($user_comment_hash{$user})
            {
                print qq(
         <tr>
          <td class="basic">${show_user}:</td>
          <td class="basic">$user_comment_hash{$user}
         </tr>
                ); 

                print REP qq(
${user}: $user_comment_hash{$user});
            }
        }
        print qq(
            </table>
        );
    }

    print qq(
           </td>
          </tr>
         </table>
        </form>
    );

    print REP qq(

$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}?page=poll&id=$id
);
    close(REP);
    print_copyright();
    print_html_end();
    exit(0);
}

############################################################

sub process_vote
{
    my ($id) = @_;
    my $choice_num = $cgi->param('choice');
    my $comment = $cgi->param('comment');
    my $warning = "";

    my $votes_file = sprintf ("%s/polls/votes_%04d.dat", $SHAREDROOT, $id);
    open (OUTF, ">>$votes_file") or $warning .= qq( Cannot read votes file: $votes_file);
    print OUTF "${YYYYMMDD}_${HHMMSS};$UBERACC{'USERNAME'};${choice_num};${comment}\n";
    close(OUTF);

    write_action(qq(User $UBERACC{'USERNAME'} voted for $choice_num in poll $id "$comment"));
    print_voting_page($id);
}

############################################################

sub process_close
{
    my ($id, $closed_by) = @_;
    my $choice_num = $cgi->param('choice');
    my $warning = "";

    my $poll_file = sprintf ("%s/polls/poll_%04d.dat", $SHAREDROOT, $id);
    my $temp_file = sprintf ("%s/polls/temp_file.dat", $SHAREDROOT);

    use File::Copy;
    copy ($poll_file, $temp_file);
#    open (INF, "$poll_file");
#    open (OUTF, ">$temp_file");
#    while(<INF>) {print OUTF $_;}
#    close(OUTF);
#    close(INF);

    my ($yyyy_t, $mm_t, $dd_t) = split / /, date_manip("-fYYYY_MM_DD");

    open (INF, "$temp_file");
    open (OUTF, ">$poll_file");
    ($user, $dd_o, $mm_o, $yyyy_o, $status, $dd_c, $mm_c, $yyyy_c)
        = split /;/, <INF>;
    print OUTF "${user};${dd_o};${mm_o};${yyyy_o};Closed;${dd_t};${mm_t};${yyyy_t};${closed_by};;\n";
    while(<INF>) {print OUTF $_;}
    close(OUTF);
    close(INF);

    my $report_file = sprintf ("%s/polls/report_%04d.txt", $SHAREDROOT, $id);
    if ($closed_by)
    {
        open (REP, ">>$report_file");
        print REP qq(
This poll was closed manually by $closed_by
);
        close(REP);
    }

    my $display_name = display_name();
    write_action(qq(Poll $id closed by $display_name));
#write_log ("# uber_polls.pl process_close() GROUP_EMAIL=$UBERENV{GROUP_EMAIL} ADMIN_EMAIL=$UBERENV{ADMIN_EMAIL}");
#    email_notify_file($UBERENV{GROUP_EMAIL}, $UBERENV{ADMIN_EMAIL},
#                      "Poll results", "$report_file");


        # Send email notification to all POLLS subscribers and GROUP_EMAIL
        my @email_list = get_email_list("POLLS");
        push @email_list, $UBERENV{GROUP_EMAIL} if ($UBERENV{GROUP_EMAIL} ne "");
        for $email (@email_list)
        {
            email_notify_file($email, $UBERENV{ADMIN_EMAIL}, "Poll Results",
                             "$report_file", $UBERENV{'APP_NAME'});
        }
}

############################################################

sub check_for_expired_polls
{
    write_log("Checking for expired polls");
    my $closing_date;
    my $today = date_manip("-fYYYYMMDD");
    my ($user, $dd_o, $mm_o, $yyyy_o, $status, $dd_c, $mm_c, $yyyy_c);

    for my $fname (<${SHAREDROOT}/polls/poll_*.dat>)
    {
        $id = $fname;
        $id =~ s/^.*poll_0*//;
        $id =~ s/\.dat$//;

        open (INF, "$fname");
        ($user, $dd_o, $mm_o, $yyyy_o, $status, $dd_c, $mm_c, $yyyy_c)
            = split /;/, <INF>;
        $closing_date = sprintf ("%04d%02d%02d", $yyyy_c, $mm_c, $dd_c);
        if (lc($status) eq "closed")
        {
            write_log("poll $id: already closed. closing_date=$closing_date");
        }
        elsif($closing_date > $today)
        {
            write_log("poll $id: keep open. closing_date=$closing_date");
        }
        else
        {
            write_log("$poll id: closing now. closing_date=$closing_date");
            process_close($id);
        }
    }
}

1;
############################################################
# EOF