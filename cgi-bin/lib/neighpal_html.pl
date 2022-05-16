############################################################
#
# neighpal_html.pl
#
# Functions which write HTML
#
############################################################

sub start_page
{
#    print qq(Content-type: text/html
#
#);
    print qq(
<html>
 <head>
  <title>$SCRIPT_TITLE</title>
  <meta http-equiv="Content-Type"
        content="text/html;charset=utf-8" />
  <meta name="description" content="Bet management system" />
  <meta name="keywords" content="$SCRIPT_TITLE, neigh, pal, horse, racing, bet, betting, win" />
    );

    print_css_list();
    print qq(
 </head>  
 <body class="basic" style="background-color: #f0ece0;" >
  <table class="basic_c" style="width: 1100px; text-align: center;" align="center" >
   <tr>
    <td style="text-align: center; width: 1100px">
    );
}

############################################################

sub end_html
{
    my $copyright = "copyright &copy; Neighpal 2007";
    $copyright .= "-$Year" if ($Year > 2007);
    print qq(
     <div class="basic_copyright">$copyright</div>
    </td>
   </tr>
  </table>
 </body>
</html>
    );
}

############################################################

sub display_banner
{
    my $username = username_and_priv();

    print qq(
  <table class="banner">
   <tr>
    <td class="banner">
     $SCRIPT_TITLE
    </td>
   </tr></tr>
    <td class="basic">
<!--
     <img src="${IMGROOT}/$BannerImgFile" width="100" /><br clear="all">
  &nbsp;
-->
      <a href="${CGI_SCRIPT}?">home</a>
    | <a href="${CGI_SCRIPT}?html=faq">faq</a>
    | <a href="${CGI_SCRIPT}?page=contactus">contact us</a>
    );

    if (is_logged_in())
    {
        if ($Privilege > 2)
        {
            print qq(
    | <a href="${CGI_SCRIPT}?page=admin">admin</a>
            );
        }
        print qq(
    | <a href="${CGI_SCRIPT}?page=account">my account</a>
    | <a href="${CGI_SCRIPT}?page=logout">logout</a> - $username
        );
    }
    else
    {
        print qq(
    | <a href="${CGI_SCRIPT}?page=login">login</a>
    | <a href="${CGI_SCRIPT}?page=signup">sign up</a>
        );
    }

    print qq(
    </td>
   </tr>
  </table>
    );
#    if (!($Labels->{site_title} =~ /^\s*$/))
#    {
#        print qq(
#            <div class="sitetitle">$Labels->{site_title}</div><br>
#        );
#    }
}

############################################################

sub display_page_title
{
    my ($pageTitle) = @_;
    print qq(
           <div class="pagetitle">$pageTitle</div>
    );
}

############################################################

sub display_race_title
{
    my ($attributes) = @_;

    ($yyyymmdd, $courseName, $hhmm, $raceName, $locked)
        = split /,/, $attributes;
    my $fname = make_filename($yyyymmdd, $courseName, $hhmm);
    my $raceDate = format_date($yyyymmdd);
    my $startTime = format_time($hhmm);
    print qq($raceDate <b>$courseName $startTime</b> <i>$raceName</i>);
}

############################################################

sub display_message
{
    my ($message) = @_;
    print qq(
           <table align="center"><tr>
            <td class="message">$message</td>
           </tr></table><br>
    );
}

############################################################

sub display_from_file
{
    my ($fname) = @_;
    $fname = "${REFROOT}/$fname";
    open (INP, "$fname") ||
        write_log("ERROR: Cannot open html file: $fname");
    print qq(
        <table class="basic" style="text-align: left; width: 500">
         <tr>
          <td><br>
    );

    while(<INP>)
    {
        print $_;
    }
    close (INP);

    print qq(
          </td>
         </tr>
        </table>
    );
}

############################################################
#
# display_welcome_page
#
# Entry page for non-logged in users
#
############################################################

sub display_welcome_page   # home page when not logged in
{
    my ($message) = @_;

    write_log("Generating Login page");
    display_page_title("Welcome");

    print qq(
        <br><br><br><div class="message">$message</div><br>
        <table align="center">
         <tr>

          <td>
           <a href="${CGI_SCRIPT}?page=login">
            <img src="${IMGROOT}/funny_horse1.jpg" border="0" width="120">
           </a>
           <br clear="all">
            Your friend of the furlongs
          </td>

          <td>
           
          </td>

         </tr>
        </table>
        <br><br><br><br>
    );
}

############################################################
#
# display_login_page
#
# Entry page for non-logged in users
# - deprecated - we now use the uber login functions
#
############################################################

sub display_login_page   # home page
{
    my ($message) = @_;

    write_log("Generating Login page");
    display_page_title("Welcome");

    print qq(
        <br><br><br><div class="message">$message</div><br>
        <table align="center">
         <tr>

          <td>
           <img src="${IMGROOT}/funny_horse1.jpg" width="120">
           <br clear="all">
          </td>

          <td>
           <form method="POST" 
                 action="$SERVER" 
                 enctype="application/x-www-form-urlencoded">
            <table >
             <tr>
              <td class="info" colspan="2">
               Existing members - please login<p>
              </td>
             </tr>
             <tr>
              <td >
               Username
              </td >
              <td >
               <input type="text" name="username" value="" size="20" maxlength="20" \>
              </td >
             </tr>
             <tr>
              <td >
               Password
              </td >
              <td >
               <input type="password" name="password" value="" size="20" maxlength="20" \><br>
               <input type="submit" name="reg" value="Login" \>
              </td>
             </tr>
            </table>
           </form>
          </td>

          <td>
           &nbsp;&nbsp;&nbsp;&nbsp;
          </td>

          <td>
           <form method="POST" 
                 action="$SERVER" 
                 enctype="application/x-www-form-urlencoded">
            <table >
             <tr>
              <td class="info" colspan="2">
               New users - sign up!<p>
              </td>
             </tr>
             <tr>
              <td >
               Username
              </td >
              <td >
               <input type="text" name="username" value="" size="20" maxlength="20" \>
              </td >
             </tr>
             <tr>
              <td >
               Password
              </td >
              <td >
               <input type="password" name="password" value="" size="20" maxlength="20" \><br>
              </td>
             </tr>
             <tr>
              <td >
               Password<br>(again)
              </td >
              <td >
               <input type="password" name="password2" value="" size="20" maxlength="20" \><br>
               <input type="submit" name="reg" value="Register" \>
              </td>
             </tr>
            </table>
           </form>
          </td>

         </tr>
        </table>
        <br><br><br><br>
    );
}

############################################################
#
# display_index_page
#
# Home page for logged in users.
# Displays menu of races, and forms for adding bookies and
# new races.
#
############################################################

sub display_index_page    # New home page
{
    write_log("Generating Index page");

    print qq(
      <table class="basic_c" style="text-align: center">
       <tr>
        <td class="basic">
<!--
SCRIPT_ID=$SCRIPT_ID<br>
DATAROOT=$DATAROOT<br>
REFROOT=$REFROOT<br>
USERROOT=$USERROOT<br>
USERDIR=$USERDIR<br>
IMGROOT=$IMGROOT<br>
LOGROOT=$LOGROOT<br>
RACESROOT=$RACESROOT<br>
STATICROOT=$STATICROOT<br>
Username=$Username<br>
Privilege=$Privilege
-->

        </td>
        <td class="basic">    <!-- Index of races starts here -->
    );

    if (is_logged_in())
    {
        print qq(
         <table class="basic">
          <tr>
           <td colspan="4"><br>
        );

        display_page_title($Labels->{index_of_races});

        print qq(<br>
           </td>
          </tr>);

        my $timenow = sprintf "%04d%02d%02d%02d%02d", $Year, $Mon, $Mday, $Hour, $Min;
        my $class = "";

        if (scalar(@RaceIndexList) > 0)
        {
            print qq(
              <tr>
               <th ></th>
               <th >Date</th>
               <th >$Labels->{racecourse}</th>
               <th >Start</th>
               <th >$Labels->{name}</th>
               <th ></th>
               <th ></th>
               <th ></th>
<!--
               <th >Filename</th>
-->
              </tr>
            );
            for $item (@RaceIndexList)
            {
                ($yyyymmdd, $courseName, $hhmm, $raceName, $locked)
                    = split /,/, $item;
                $locked = lc($locked);
                $fname = make_filename($yyyymmdd, $courseName, $hhmm);
                $raceDate = format_date($yyyymmdd);
                $raceTime = format_time($hhmm);
                $lockOrCopy = ($locked eq "locked") ? "copy" : "lock";
                $timestamp = "${yyyymmdd}$hhmm";
                $class = ($timenow > "${yyyymmdd}$hhmm") ? "odd" : "even";

                print qq(
              <tr>
               <td >$locked</td>
               <td class="$class">$raceDate</td>
               <td class="$class">$courseName</td>
               <td class="$class">$raceTime</td>
               <td class="$class">$raceName</td>
               <td class="$class">
                <a href="${CGI_SCRIPT}?race=open&fname=$fname">open</a>
               </td>
               <td class="$class">
                <!-- <a href="${CGI_SCRIPT}?race=delete&fname=$fname">delete</a> -->
               </td>
               <td class="$class">
                &nbsp;
               </td>
               <td class="faint"><!-- $fname --></td>
              </tr>
                );
            }
        }
        else
        {
            print qq(
              <tr>
               <td class="basic" colspan="4">You have no stored $Labels->{race}s.</td>
              </tr>
            );
        }

        print qq(
        </table>
        );
    }
    else # not logged in
    {
        print qq(
            Welcome to $SCRIPT_TITLE<br>
           <zzimg src="${IMGROOT}/funny_horse1.jpg" width="120">
           <img src="${IMGROOT}/rbs_logo.gif" width="120">
        );
    }

    print qq(
       </td>
      </tr>
     </table>

     <br clear="all">
    );

    return if (! is_logged_in());

    # Start new race form
    print qq(
        <hr>
        <table>
         <tr>
          <td>
           <form method="POST" 
                 action="$SERVER" 
                 enctype="application/x-www-form-urlencoded">
            <table>
             <tr>
              <th >$Labels->{bookie}s</th>
             </tr>
             <tr>
              <td>
               <table>
    );
    my $bookie = "";
    my $bookies = 0;
    open (INF, "${STATICROOT}/$BookiesFile");
    while (<INF>)
    {
        chop;
        next if (!/\w/);
        next if (/^#/);
        $bookie = $_;
        $bookies++;
        print qq(<tr>
                  <td>$bookie</td>
                  <td><a href="${CGI_SCRIPT}?bookie=delete&name=$bookie">delete</a></td>
                 </tr>);
    }
    close (INF);

    if ($bookies < 1)
    {
        print qq(You have no $Labels->{bookie}s.  You'll need to add<br>
                 some before you can add a $Labels->{race}.<p>
        );
    }
    print qq(
               </table>
              </td>
             </tr>
             <tr>
              <th>Add a $Labels->{bookie}</th> 
             </tr>
             <tr>
              <td>
               <input type="text" name="text:new_bookie" value="" size="24" maxlength="24" \>
               <input type="submit" name="submit:addbookie" value="$Labels->{new_bookie}" \>
               </nobr>
              </td>
             </tr>
            </table>
           </form>
          </td>
          <td>
           <form method="POST" 
                 action="$SERVER" 
                 enctype="application/x-www-form-urlencoded">

            <table>
             <tr>
              <th class="margin"></th>
              <th >Add a $Labels->{race}</th>
             </tr>
             <tr>
              <td >$Labels->{race} Date</td>
              <td >
               <select name="dd">
    );

    my $selected;
    for ($d = 1; $d < 32; $d++)
    {
        $selected = ($d == $Mday) ? "SELECTED" : ""; # select today's date
        print qq(
                 <option value="$d" $selected>$d</option>
        );
    }

    print qq(
               </select>
               <select name="mm">
    );

    for ($m = 1; $m <= 12; $m++)
    {
        $selected = ($m-1 == $Mon) ? "SELECTED" : ""; # select this month
        print qq(
                 <option value="$m" $selected>$MonthList[$m - 1]</option>
        );
    }

    print qq(
               </select>
               <select name="yyyy">
                 <option value="$Year" selected>$Year</option>
    );

    my $y;
    for ($y = $Year+1; $y < $Year+3; $y++)
    {
        print qq(
                 <option value="$y">$y</option>
        );
    }

    print qq(
               </select>
              </td>
             </tr>

             <tr>
              <td >$Labels->{racecourse}</td>
              <td >
               <input type="text" name="coursename" value="" size="29" maxlength="30" \>
              </td>
             </tr>

             <tr>
              <td >Start Time</td>
              <td >
               <select name="hr">
    );

    for $hr ("09", "10", "11", "12", "13", "14", "15", "16", "17", "18")
    {
        print qq(
                 <option value="$hr">$hr</option>
        );
    }

    print qq(
               </select>
               <select name="min">
    );

    for $min ("00", "05", "10", "15", "20", "25", "30", "35", "40", "45", "50", "55")
    {
        print qq(
                 <option value="$min">$min</option>
        );
    }

    print qq(
               </select>
              </td>
             </tr>

             <tr>
              <td >$Labels->{name}</td>
              <td >
               <input type="text" name="racename" value="" size="29" maxlength="30" \>
              </td>
             </tr>

             <tr>
              <td >$Labels->{num_runners}</td>
              <td >
               <select name="num_runners">
    );

    for ($i = 2; $i <=30; $i++)
    {
        $selected = ($i == 12) ? "SELECTED" : "";
        print qq(
                <option value="$i" $selected>$i</option>
        );
    }

    print qq(
               </select>
                &nbsp;&nbsp;&nbsp;<input type="submit" name="new_race" value="$Labels->{new_race}" \>
              </td>
             </tr>
            </table>
           </form>
          </td>
         </tr>
        </table>
    );
}

############################################################
#
# display_betting_page
#
# Betting Manager Page
#
#############################################################

sub display_betting_page
{
    my ($attributes, $fname) = @_;
    my $raceTitle = get_race_title($attributes);
    my $numBets = scalar(@BetList);
    my $prob;
    my $win;
    my $stake;
    my $totalStake = sprintf "%.2f", $Calcs->{totalStake};
    my $recommendedTotalStake = $Calcs->{recommendedTotalStake};
    my $nagWin;
    my $nagLose;
    my $nagGain;

    write_log("Generating Betting page.");
    display_page_title($Labels->{betting_manager});

    set_warnings();

    # Start form
    print qq(
           <form method="POST" 
                 action="$SERVER" 
                 enctype="application/x-www-form-urlencoded">

            <input type="hidden" name="fname" value="$fname" \>

            <table border="0">
             <tr>
              <td class="lastline"></td> 
              <td class="" colspan="2">
               <input type="submit" name="submit:calc" value="Calc" \>
              </td>
              <td class="lastline"></td>
              <td class="racetitle" colspan="6">$raceTitle</td>
              <td class="lastline"></td>
              <td class="lastline"></td>
              <td class="lastline"></td>
              <td class="lastline"></td>
              <td class="lastline"></td>
              <td class="lastline"></td>
              <td class="lastline"></td>
             </tr>

             <tr>
              <th class="margin"></th> 
              <th class="bet"></th> 
              <th class="bet">$Labels->{horse}</th> 
              <th class="bet">$Labels->{side}</th> 
              <th class="bet">$Labels->{bookie}</th> 
              <th class="bet">$Labels->{odds}</th> 
              <th class="bet">$Labels->{stake}</th> 
              <th class="bet">$Labels->{status}</th> 
              <th class="bet" colspan="3">$Labels->{change_status}</th> 
              <th class="bet">$Labels->{bet_win}</th> 
              <th class="bet">$Labels->{horse_win}</th> 
              <th class="bet">$Labels->{stake_loss}</th> 
              <th class="bet">$Labels->{net_gain}</th> 
              <th class="margin"></th> 
              <th class="copyright">Prob</th> 
<!--
              <th class="margin">iB</th> 
              <th class="margin">S</th> 
-->
             </tr>
    );

    my $betCount = 0;
    my $prevBet;
    my $tdclass;
    my $evenNag = true;
    my $nagCount = 0; # We will eventually store this with the name
    my $nagNum = "";
    my $nagName = "";
    my $nagWarning = 0;
    my $confirmedStake = 0;
    my $lastNagNum = -1;
    my $worstGain = 10000000;
    my $nagWarningCount = 0;

    for $bet (sort nagsort @BetList)
    {
        $lastNagNum = $bet->{nag_num};
        $newNag = (($betCount == 0) || ($bet->{nag_num} != $prevBet->{nag_num}));
        $evenNag = !$evenNag if ($newNag);
        $nagCount++ if ($newNag);
        $tdclass = $evenNag ? "even" : "odd";
        $nagNum = $newNag ? $bet->{nag_num} : "";
        $nagName = $newNag ? $bet->{nag_name} : "";
        $nagWarning = $newNag ? $bet->{nag_warning} : 0;
        $stake = (is_empty($bet->{stake})) ? "" : sprintf "%.2f", $bet->{stake};
        $prob  = (is_empty($bet->{prob}))  ? "" : sprintf "%.4f", $bet->{prob};
        $win   = (is_empty($bet->{win}))   ? "" : sprintf "&pound;%.2f", $bet->{win};
        $nagWin  = (is_empty($bet->{nag_win}) || !$newNag)   ? "" : sprintf "&pound;%.2f", $bet->{nag_win};
        $nagLose = (is_empty($bet->{nag_lose}) || !$newNag)  ? "" : sprintf "&pound;%.2f", $bet->{nag_lose};
        if (is_empty($bet->{nag_gain}) || !$newNag)
        {
            $nagGain = "";
        }
        elsif ($bet->{nag_gain} < 0.0) # display minus sign on left of pound sign
        {
            $nagGain = sprintf "-&pound;%.2f", 0 - $bet->{nag_gain};
            $worstGain = $bet->{nag_gain} if ($bet->{nag_gain} < $worstGain);
        }
        else
        {
            $nagGain = sprintf "&pound;%.2f", $bet->{nag_gain};
            $worstGain = $bet->{nag_gain} if ($bet->{nag_gain} < $worstGain);
        }


        # Display horse number and name
        print qq(
             <tr>
              <td class="margin" align="right"><nobr>
        );

        if ($bet->{is_best} == 1) # Put a star against the best bet for this horse
        {
            print qq(<img src="${IMGROOT}/star.jpg" width="16" alt="Best odds">
            );
        }

        if ($nagWarning) # Mark a warning against this horse
        {
            print qq(<img src="${IMGROOT}/nag_warning.gif" width="8" alt="Warning">
            );
            $nagWarningCount++;
        }

        print qq(
               </nobr></td> 
              <td class="$tdclass">
               <input type="hidden" name="bet:nag_num:$betCount" value="$bet->{nag_num}" \>
               $nagNum
              </td> 
              <td class="$tdclass">
               <input type="hidden" name="bet:nag_name:$betCount" value="$bet->{nag_name}" \>
               $nagName
              </td> 
        );

        # Mark bets that are inactive or have no odds set.
        if (($bet->{status} == 2) || ($bet->{status} == 3) || !($bet->{odds}))
        {
            $tdclass .= "_grey";
        }

        # Display side, bookie, odds and stake.
        if ($bet->{status} == 0) # Only allow active bets to change these fields
        {
            if ($bet->{side} eq "Sell")
            { 
                $sellSelected = "SELECTED"; $buySelected = "";
            }
            else
            {
                $buySelected = "SELECTED"; $sellSelected = "";
            }
            print qq(
              <td class="$tdclass">
               <select name="bet:side:$betCount">
                 <option value="Buy" $buySelected>Buy</option>
                 <option value="Sell" $sellSelected>Sell</option>
               </select>
             </td>
              <td class="$tdclass">
               <select name="bet:book:$betCount">
            );

            for $bookie (@BookieList)
            {
                $selected = ($bet->{book} eq $bookie) ? "SELECTED" : "";
                print qq(
                 <option value="$bookie" $selected>$bookie</option>
                );
            }

            print qq(
               </select>
              </td>
              <td class="$tdclass">
               <input type="text" name="bet:odds:$betCount" value="$bet->{odds}" size="6" maxlength="6" \>
              </td>
              <td class="$tdclass" align="right">
               &pound;<input type="text" name="bet:stake:$betCount" value="$stake" size="8" maxlength="8" align="right" \>
              </td>
            );
        }
        else # user cannot change these fields
        {
            # No form fields - can't edit
            $confirmedStake = sprintf "%.2f", $bet->{stake};
            print qq(
              <td class="$tdclass">
               <input type="hidden" name="bet:side:$betCount" value="$bet->{side}" \>
               $bet->{side}
              </td>
              <td class="$tdclass">
               <input type="hidden" name="bet:book:$betCount" value="$bet->{book}" \>
               $bet->{book}
              </td>
              <td class="$tdclass">
               <input type="hidden" name="bet:odds:$betCount" value="$bet->{odds}" \>
               $bet->{odds}
              </td>
              <td class="$tdclass" align="right">
               <input type="hidden" name="bet:stake:$betCount" value="$bet->{stake}" \>
               $confirmedStake
              </td>
            );
        }

        # Show status
        $statusLabel = $StatusList[$bet->{status}];
        if (($bet->{status} == 0) && !($bet->{odds}))
        {
            $statusLabel = "Incomplete"; # mark active bets which have no odds set
        }
        print qq(
              <td class="$tdclass">
               <input type="hidden" name="bet:status:$betCount:" value="$bet->{status}" \>
               $statusLabel
        );

        print qq(
              </td>
              <td class="$tdclass">
        );

        if ($bet->{status} == 2) # 'Delete' button is only available to inactive bets
        {
            print qq(
               <input type="image" src="${IMGROOT}/delete.gif" width="15" name="submit:delete:$betCount:" value="D" alt="Delete" \>  
            );
        }

        print qq(</td>
                 <td class="$tdclass">
        );

        # 'Active' and 'Inactive' buttons share a column
        if (($bet->{status} == 1) || ($bet->{status} == 2)) # 'Active' button is only available to inactive or confirmed bets
        {
            print qq(
               <input type="image" src="${IMGROOT}/active.gif" width="15" name="submit:active:$betCount:" value="A" alt="Make Active" \>  
            );
        }
        elsif ($bet->{status} == 0) # 'Inactive' button is only available to active bets
        {
            print qq(
               <input type="image" src="${IMGROOT}/inactive.gif" width="15" name="submit:inactive:$betCount:" value="I" alt="Make Inactive" \>  
            );
        }

        print qq(</td>
                 <td class="$tdclass">
        );

        # 'Confirm' button is only available to active bets with completed fields
        # and positive stake.
        if (($bet->{status} == 0) && (!is_empty($bet->{prob})) && (!is_empty($bet->{stake}))
         && ($bet->{stake} > 0.001))
        {
            print qq(
               <input type="image" src="${IMGROOT}/confirm.gif" width="15" name="submit:confirm:$betCount" value="C" alt="Commit" \>  
            );
        }

        # Display winnings, loss and net gain if this horse wins.
        print qq(
              </td>
              <td class="$tdclass" align="right"><nobr>$win</nobr></td>
              <td class="$tdclass" align="right"><nobr>$nagWin</nobr></td>
              <td class="$tdclass" align="right"><nobr>$nagLose</nobr></td>
              <td class="$tdclass" align="right"><nobr>$nagGain</nobr></td>

              <td >
        );

        # 'New Bet' button
        if ($newNag)
        {
            print qq(
               <input type="submit" name="submit:newbet:$betCount" value="$Labels->{new_bet}" \>
            );
        }

        print qq(
              </td>
              <td class="faint">$prob</td>
<!--
              <td >$bet->{is_best}</td>
              <td >$bet->{status}</td>
-->
             </tr>
        );
        $betCount++;
        $prevBet = $bet;
    } # /for each bet

    if ($worstGain < 0.0)
    {
        $worstGainf = sprintf("-&pound;%.2f", 0 - $worstGain);
    }
    else
    {
        $worstGainf = sprintf("&pound;%.2f", $worstGain);
    }

    my $disabledTag = $nagWarningCount ? "disabled=\"disabled\"" : "";

    print qq(
             <tr>
              <td class="lastline"></td> 
              <td class="" colspan="2">
               <input type="submit" name="submit:calc" value="Calc" \>
              </td>
              <td class="lastline"></td>

              <td class="keycell" colspan="2">$Labels->{total_stake}:</td>
              <td class="keycell">
               &pound;<input type="text" name="text:total_stake:-1" value="$totalStake" 
                             size="8" maxlength="8" align="right" \>
              </td>
              <td class="lastline" align="left" colspan="2">
               <input type="submit" name="submit:spread" value="Spread" $disabledTag \>
              </td>
              <td class="lastline"></td>
              <td class="lastline"></td>
              <td class="lastline"></td>
              <td class="keycell" colspan="2">$Labels->{worst_gain}:</td>
              <td class="keycell"><nobr>$worstGainf</nobr></td>
              <td class="lastline"></td>
             </tr>
    );

    if ($nagWarningCount > 0) # Display warning message
    {
        print qq(
             <tr>
              <td colspan="15" class="message">
               <img src="${IMGROOT}/nag_warning.gif" width="8" alt="Warning">
               These $Labels->{horse}s have no active bets or odds. ($nagWarningCount)
              </td> 
             </tr>
        );
    }

    if ($Calcs->{recommendedTotalStake} > 0.00001)
    {
        my $recommendedTotalStake = sprintf "%.2f", $Calcs->{recommendedTotalStake};
        print qq(
             <tr>
              <td colspan="15" class="message">
<!--
               <img src="${IMGROOT}/nag_warning.gif" width="8" alt="Attention">
-->
               <b>ATTENTION! You have a negative stake.</b><br>
               To make your stakes non-negative you need to increase your total stake to
               <b>&pound;$recommendedTotalStake</b> -
               Do this?
               <input type="image" src="${IMGROOT}/yes_button_red.gif" zwidth="40" 
                      name="submit:recommended:$recommendedTotalStake" value="R"
                      alt="Increase stake" \>  
              </td> 
             </tr>
        );
    }

    print qq(
             <tr>
              <td colspan="15">&nbsp;<hr></td> 
             </tr>
             <tr>
              <td ></td> 
              <td colspan="2">Add more $Labels->{horse}s</td> 
              <td >$Labels->{side}</td> 
              <td >$Labels->{bookie}</td> 
              <td >$Labels->{odds}</td> 
              <td >$Labels->{stake}</td> 
             </tr>
    );

    # Build list of nagnums that haven't yet been used.
    my @availableNagNumList = ();
    my $nagNumItr = 1;
    my $nagNumCount = 0;
    while ($nagNumCount < 20)
    {
        if (!nagnum_already_used($nagNumItr))
        {
            push @availableNagNumList, $nagNumItr;
            $nagNumCount++;
        }
        $nagNumItr++;
    }

    # Add rows for inputting more horses.
    my $row = 0;
    my $selectedNagNum = 0;
    my $numInpRows = 3; # number of input rows
    my $lastInpRow = $betCount + $numInpRows - 1;

    for ($row = $betCount; $row <= $lastInpRow; $row++)
    {
        $selectedNagNum = $lastNagNum + ($row - $betCount) + 1;
        print qq(
             <tr>
              <td class="margin"></td> 
        );

        # Input horse number
        print qq(
              <td colspan="2"><nobr>
               <select name="bet:nag_num:$row">
        );
        for $j (@availableNagNumList)
        {
            $selected = ($j eq $selectedNagNum) ? "SELECTED" : "";
            print qq(
                 <option value="$j" $selected>$j</option>
            );
        }
        print qq(
               </select>
        );

        # Input horse name
        print qq(
               <input type="text" name="bet:nag_name:$row" value="" size="24" maxlength="24" \>
              </nobr></td>
            );

        # Input bookie
        print qq(
              <td >
               <select name="bet:side:$row">
                 <option value="Buy" SELECTED>Buy</option>
                 <option value="Sell">Sell</option>
               </select>
              </td>
              <td >
               <select name="bet:book:$row">
        );
        for $bookie (@BookieList)
        {
            $selected = ($bet->{book} eq $bookie) ? "SELECTED" : "";
            print qq(
                 <option value="$bookie" $selected>$bookie</option>
            );
        }
        print qq(
               </select>
              </td>
        );

        # Input odds and stake
        print qq(
              <td >
               <input type="text" name="bet:odds:$row" value="" size="6" maxlength="6" \>
              </td>
              <td >
               <input type="text" name="bet:stake:$row" value="" size="8" maxlength="8" \>
              </td>
              <td colspan="2">
        );

        print qq(
                 <input type="submit" name="submit:addhorse" value="$Labels->{new_horse}" \>
        ) if ($row == $lastInpRow);

        print qq(
              </td>
             </tr>
        );
    }

    # Add another bookie
    print qq(
             <tr>
              <td ></td> 
              <td colspan="3">Add more $Labels->{bookie}s</td> 
             </tr>
             <tr>
              <td ></td> 
              <td colspan="3"><nobr>
               <input type="text" name="text:new_bookie" value="" size="24" maxlength="24" \>
               <input type="submit" name="submit:addbookie" value="$Labels->{new_bookie}" \>
               </nobr>
              </td>
             </tr>
            </table><br clear="all" \>
           </form>

        <div class="basic" style="text-align: left">
           <a href="${CGI_SCRIPT}?">home</a>
         | <a href="${CGI_SCRIPT}?p=delete&fname=">delete this race</a> (not yet available)
        </div>
    );
}

############################################################
#
# display_input_page
#
# Input page for entering details of horses in a new race.
#
#############################################################

sub display_input_page
{
    my ($attributes, $fname) = @_;

    my $numRunners = $cgi->param('num_runners');
    $numRunners = 10 if (!$numRunners || ($numRunners < 2));
    write_log("Generating Input page for $numRunners runners fname=$fname");

    display_page_title($Labels->{race_input});
    my $raceTitle = get_race_title($attributes);
    print qq(
           <div class="racetitle">$raceTitle</div>
    );

    # Start form
    print qq(
           <form method="POST" 
                 action="$SERVER" 
                 enctype="application/x-www-form-urlencoded">

            $Granted
            <input type="hidden" name="fname" value="$fname" \>

            <table border="0">
             <tr>
              <th class="margin"></th> 
              <th></th> 
              <th>$Labels->{horse}</th> 
              <th>$Labels->{bookie}</th> 
              <th>$Labels->{odds}</th> 
              <th>$Labels->{stake}</th> 
             </tr>
    );

    my $i = 0;
    my $horse = 0;
    for ($i = 0; $i < $numRunners; $i++)
    {
        $horse = $i + 1;
        print qq(
             <tr>
              <td class="margin">$horse</td> 
        );

        # Input horse number
        print qq(
              <td >
               <select name="bet:nag_num:$i">
        );
        for ($j = 1; $j <= $numRunners; $j++)
        {
            $selected = ($j eq $horse) ? "SELECTED" : "";
            print qq(
                 <option value="$j" $selected>$j</option>
            );
        }
        print qq(
               </select>
              </td>
        );

        # Input horse name
        print qq(
              <td >
               <input type="text" name="bet:nag_name:$i" value="" size="24" maxlength="24" \>
              </td>
            );

        # Input bookie
        print qq(
              <td >
               <select name="bet:book:$i">
        );
        for $bookie (@BookieList)
        {
            $selected = ($bet->{book} eq $bookie) ? "SELECTED" : "";
            print qq(
                 <option value="$bookie" $selected>$bookie</option>
            );
        }
        print qq(
               </select>
              </td>
        );

        # Input odds and stake
        print qq(
              <td >
               <input type="text" name="bet:odds:$i" value="" size="6" maxlength="6" \>
              </td>
              <td >
               <input type="text" name="bet:stake:$i" value="" size="8" maxlength="8" \>
              </td>
             </tr>
        );
    }

    # 'Enter' button
    print qq(
             <tr>
              <td class="margin"></td> 
              <td >
               <input type="submit" name="submit:enter" value="Enter" \>
              </td>
              <td >
              </td>
              <td >
              </td>
             </tr>
            </table>
           </form>
    );
}

############################################################

1;
