############################################################
#
# neighpal_funcs.pl
#
# Functions which don't write any HTML
#
############################################################

############################################################
#
#   status    meaning
#   ------    -------
# 0 Active    pending
# 1 Confirmed committed
# 2 Inactive  ignored
# 3 Deleted   gone
#
#
#   side    - not operational yet
#   ----
# 0 Buy   
# 1 Sell
#
############################################################

sub main()
{
    $RACESROOT = "${USERROOT}/${Username}/races";
    $STATICROOT = "${USERROOT}/${Username}/static";
    if (is_logged_in())
    {
        makedir("$RACESROOT");
        makedir("$STATICROOT");
    }

#    log_all_params();
    start_page();
    display_banner($username);

    if ($html = $cgi->param('html'))
    {
        display_from_file("${html}.html");
        return;
    }

    if (is_logged_in())
    {
        load_labels();
        load_race_index();
        load_bookies();
        process_params();
    }
    else
    {
        display_welcome_page($message);
    }

    end_html();
    write_log("Done.");
}

############################################################

sub nagsort
{
    if ($a->{nag_num} ne $b->{nag_num}) # group bets together by nag
    {
        return ($a->{nag_num} <=> $b->{nag_num});
    }
    elsif ($a->{prob} != $b->{prob}) # order by best odds to worst
    {
        # make sure unset probs are placed last
        $aprob = (is_empty($a->{prob}) ? 1 : $a->{prob});
        $bprob = (is_empty($b->{prob}) ? 1 : $b->{prob});
        return ($aprob <=> $bprob);
    }
    return ($b->{stake} <=> $a->{stake});
}

############################################################

sub rev_sort
{
    return ($b cmp $a);
}

############################################################

sub log_all_params
{
    write_log("log_all_params()");
    my $key;
    my $value;
    for $key ( $cgi->param() ) 
    {
        $value = $cgi->param($key);
        write_log("Param: key=$key value=$value");
    }
}

############################################################

sub is_empty
{
    my ($item) = @_;
    if ($item =~ /^\s*$/)
    {
        return 1;
    }
    return 0;
}

############################################################

sub is_empty_or_null
{
    my ($item) = @_;
    if (!$item || ($item =~ /^\s*$/))
    {
        return 1;
    }
    return 0;
}

############################################################

sub get_race_attributes
{
    # Scan the race index list for a race which matches the
    # given filename.

    my $fname = shift(@_);
    my $attributes = "";

    for $item (@RaceIndexList)
    {
        ($yyyymmdd, $courseName, $hhmm, $raceName, $locked)
            = split /,/, $item;
        $itemFname = make_filename($yyyymmdd, $courseName, $hhmm);
        if ($fname eq $itemFname)
        {
            $attributes = $item;
            last;
        }   
    }
    return $attributes;
}

############################################################

sub process_params
{
    write_log("Processing parameters...");
    my $fname = $cgi->param('fname');
    my $race;
    my $confirm = -1;
    my $delete = -1;
    my $count = 0;

    # Delete a bookie (Index page)
    if ($cgi->param('bookie') eq "delete")
    {
        my $bookie = $cgi->param('name');
        my @tmpBookieList = @BookieList;
        @BookieList = ();
        for $b (@tmpBookieList)
        {
            push (@BookieList, $b) if ($b ne $bookie);
        }
        save_bookies();
    }

    # Get betting form data from composite param keys
    for $key ( $cgi->param() ) 
    {
        $value = $cgi->param($key);
        $count++;

        ($inpType, $dataType, $num) = split /:/, $key;

        if ($inpType eq "submit")
        {
            $Param->{request} = $dataType;
            $Param->{num} = $num;
            $confirm = $num if ($dataType eq "confirm");
            $delete = $num if ($dataType eq "delete");
            $BetList[$num]->{status} = 0 if ($dataType eq "active"); # active button has been clicked
            $BetList[$num]->{status} = 2 if ($dataType eq "inactive"); # inactive button has been clicked
        }
        elsif ($inpType eq "bet")
        {
            $BetList[$num]->{$dataType} = $value;
        }
#        elsif ($inpType eq "text")
        else
        {
            $Param->{$dataType} = $value;
        }
    }
    write_log("Read $count parameters.");

    if ($confirm >= 0)
    {
        write_log("Clicked link: Confirm (on Betting page)");
        write_log("Confirming bet $confirm [$BetList[$confirm]->{nag_num}] $BetList[$confirm]->{nag_name}");
        $BetList[$confirm]->{status} = 1;
    }

    if ($delete >= 0)
    {
        write_log("Clicked link: Delete (on Betting page)");
        write_log("Deleting bet $delete num=[$BetList[$delete]->{nag_num}] name=$BetList[$delete]->{nag_name} bookie=$BetList[$delete]->{bookie} odds=$BetList[$delete]->{odds} stake=$BetList[$delete]->{stake}");
        display_message("Deleted bet $BetList[$delete]->{nag_num} $BetList[$delete]->{nag_name} $BetList[$delete]->{bookie} $BetList[$delete]->{odds} $BetList[$delete]->{stake}");
        $BetList[$delete]->{status} = 3;
        $BetList[$delete]->{nag_num} = -1; # causes remove_null_bets() to remove it
    } 

    remove_null_bets();

    # Process Input page form data
    if ($cgi->param('submit:enter'))
    {
        write_log("Clicked button: Enter (on Input page)");
#        save_race($fname); # save and load filters out empty bets
#        load_race($fname);
        # follow through for actual processing...
    }

#    set_warnings();

    # Process betting form data
    if ($cgi->param('submit:calc'))
    {
        write_log("Clicked button: Calc (on Betting page)");
        # follow through for calculations...
    }
    elsif ($Param->{request} eq "newbet")
    {
        write_log("Clicked button: Add Bet (on Betting page)");
        add_bet($BetList[$Param->{num}]->{nag_num},
                $BetList[$Param->{num}]->{nag_name});
    }
    elsif ($Param->{request} eq "addhorse")
    {
        write_log("Clicked button: Add Horse (on Betting page)");
        add_bet($Param->{new_nag_num}, $Param->{new_nag_name});
    }
    elsif ($Param->{request} eq "addbookie")
    {
        write_log("Clicked button: Add Bookie (on Betting page)");
        push @BookieList, $Param->{new_bookie};
        save_bookies();
    }
    elsif ($Param->{request} eq "spread")
    {
        write_log("Clicked button: Spread (on Betting page)");
        perform_calcs();
        spread_stake();
    }
    elsif ($Param->{request} eq "recommended")
    {
        write_log("Clicked button: Recommended Total Spread (on Betting page)");
        $Param->{total_stake} = $Param->{num};
        perform_calcs();
        spread_stake();
    }

    # Process new race form data (from Index page)
    if ($cgi->param('new_race')) # set up a new race
    {
        write_log("Clicked button: New Race (on Index page)");
        my $dd = $cgi->param('dd');
        my $mm = $cgi->param('mm');
        my $yyyy = $cgi->param('yyyy');
        my $courseName = $cgi->param('coursename');
        my $hr = $cgi->param('hr');
        my $min = $cgi->param('min');
        my $raceName = $cgi->param('racename');
        my $yyyymmdd = sprintf "%04d%02d%02d", $yyyy, $mm, $dd;
        my $hhmm = sprintf "%02d%02d", $hr, $min;
        my $attribute = "$yyyymmdd,$courseName,$hhmm,$raceName,";
        $fname = make_filename($yyyymmdd, $courseName, $hhmm);
        add_to_race_index_list($attribute);
        save_race_index();
    }

    # If a filename is specified we want to generate
    # a Betting page.
    if ($fname)
    {
        if ($race = $cgi->param('race'))
        {
            if ($race eq "open") # select an existing race
            {
                write_log("Clicked link: Open (on Index page)");
                load_race($fname);
            }
            elsif ($race eq "delete") # delete an existing race
            {
                write_log("Clicked link: Delete (on Index page)");
                delete_race($fname);
                display_index_page();
                return;
            }
            elsif ($race eq "close") # close an existing race
            {
                write_log("Clicked link: Close (on Index page)");
                load_race($fname);
            }
            elsif ($race eq "copy") # copy an existing race
            {
                write_log("Clicked link: Copy (on Index page)");
                load_race($fname);
            }
        }

        $attributes = get_race_attributes($fname);
        write_log("attributes=$attributes");
        my $numBets = scalar(@BetList);
        write_log("Number of bets: $numBets");

        if ($numBets < 1)
        {
            # It's a new race, so user needs to input details
            # of all runners.
            display_input_page($attributes, $fname);
        }
        else
        {
            perform_calcs();
            display_betting_page($attributes, $fname);
        }
        save_race($fname);
        return;
    }
    else # No filename so go to home page
    {
        display_index_page();
    }
}

############################################################

sub add_to_race_index_list
{
    my $newItem = shift(@_);
    my ($newYyyymmdd, $newCourseName, $newHhmm, $newOthers)
        = split /,/, $newItem;

    # Check if this item already exists in the list
    my $exists = 0;
    for $item (@RaceIndexList)
    {
        ($yyyymmdd, $courseName, $hhmm, $others)
            = split /,/, $item;
        if (($yyyymmdd eq $newYyyymmdd)
         && ($courseName eq $newCourseName)
         && ($hhmm eq $newHhmm))
        {
            $exists = 1;
        }
    }

    if (!$exists)
    {
        push @RaceIndexList, $newItem;
        write_log("Added new race to index: $newItem");
    }
    else
    {
        print qq(Race already exists!<br>);
        write_log("Race already exists: $newItem");
    }
}

############################################################

sub flag_best_bets
{
    # Find the best probs for each nag - only active bets apply!

    my $prevNagNum = -1;

    for $bet (sort nagsort @BetList)
    {
        if ((!is_empty($bet->{prob})) && ($bet->{status} == 0))
        {
            if ($bet->{nag_num} ne $prevNagNum)
            {
                $bet->{is_best} = 1; # flag the best bet for this nag
                $bestProb = $bet->{prob};
            }
            else
            {
                if ($bet->{prob} < $bestProb) # best prob is lowest prob
                {
                    $bet->{is_best} = 1;
                    $bestProb = $bet->{prob};
                }
                else
                {
                    $bet->{is_best} = 0;
                }
            }
            $prevNagNum = $bet->{nag_num};
        }
    }
}


############################################################

sub set_warnings
{
    # Indicate if a horse has no active best bet.

    flag_best_bets();
    my $warning;
    my %warningHash = {};
    my $nagNum;
    for $bet (sort nagsort @BetList)
    {
        $nagNum = $bet->{nag_num};
        $bet->{nag_warning} = 1; # assume each horse hasn't
        if (($bet->{status} == 0) && ($bet->{is_best} == 1))
        {
            $warningHash{$nagNum} = "good";
        }
    }

    # Second pass to set warning flag for each bet of a bad horse
    for $bet (sort nagsort @BetList)
    {
        $nagNum = $bet->{nag_num};
        if ($warningHash{$nagNum} eq "good")
        {
            $bet->{nag_warning} = 0;
        }
    }
}

############################################################
#
# Keep the total stake the same and re-spread it across
# all non-committed bets optimally.

sub spread_stake
{
    write_log("Performing stake spread");

    flag_best_bets();
#set_warnings();

    my $totalStake = $Param->{total_stake};
    my $totalCommittedStake = calc_committed_stake();
    my $totalAvailableStake = $Param->{total_stake} - $totalCommittedStake;

    my $KT = $totalStake;
    my $KC = $totalCommittedStake;
    my $KA = $totalAvailableStake;
    my $sigmaP = 0.0;
    my $sigmaCVP = 0.0;
#write_log("spread_stake: -----------------");
#write_log("spread_stake: totalStake          KT=$KT");
#write_log("spread_stake: totalCommittedStake KC=$KC");
#write_log("spread_stake: totalAvailableStake KA=$KA");

    # We're going to hold all the figures we need for the calculations
    # in a hash table of horses.
    my $horse;
    my %horseHash = {};
    my $nagNum;
    $horseHash{0}{c} = 0.0;
    $horseHash{0}{v} = 0.0;
    $horseHash{0}{p} = 0.0;
    for $bet (sort nagsort @BetList) # initialise
    {
        $nagNum = $bet->{nag_num};
        $horseHash{$nagNum}{c} = 0.0; # confirmed stake
        $horseHash{$nagNum}{v} = 0.0; # confirmed win
        $horseHash{$nagNum}{p} = 0.0; # prob of best bet
        $horseHash{$nagNum}{num} = $nagNum;
        $horseHash{$nagNum}{status} = -1;
#write_log("spread_stake: nag_num=$nagNum c=$horseHash{$nagNum}{c} v=$horseHash{$nagNum}{v} p=$horseHash{$nagNum}{p}");
    }

    # calculate c, v and p for each horse
    for $bet (sort nagsort @BetList) 
    {
        $nagNum = $bet->{nag_num};
#write_log("spread_stake: nag_num=$nagNum status=$bet->{status} is_best=$bet->{is_best}");

        if ($bet->{status} == 1) # a committed bet
        {
            $horseHash{$nagNum}{c} += $bet->{stake};
            $bet_win = $bet->{stake} * (1 - $bet->{prob})/$bet->{prob};
            $horseHash{$nagNum}{v} += $bet_win;
        }
        elsif (($bet->{status} == 0) && ($bet->{is_best} == 1)) # best active bet
        {
            $horseHash{$nagNum}{p} = $bet->{prob}; # prob of best bet
            $horseHash{$nagNum}{status} = 0;
            $horseHash{$nagNum}{stake} = $bet->{stake};
        }
#write_log("spread_stake: c=$horseHash{$nagNum}{c} v=$horseHash{$nagNum}{v} p=$horseHash{$nagNum}{p}");
    }

    # tot up the sigmas
    for $horse (keys %horseHash)
    {
        next if (!$horseHash{$horse}{num});
        $sigmaP += $horseHash{$horse}{p};
        $cvp = ($horseHash{$horse}{c} + $horseHash{$horse}{v}) * $horseHash{$horse}{p};
        $sigmaCVP += $cvp;
#write_log("spread_stake: horse=$horse name=$horseHash{$horse}{name} c=$horseHash{$horse}{c} v=$horseHash{$horse}{v} p=$horseHash{$horse}{p}");
    }
#write_log("spread_stake: sigmaP=$sigmaP sigmaCVP=$sigmaCVP");

    # calculate the equalised gain
    my $x = 0.0;
    my $lowestX = 10000000.0;
    my $lowestHorse = -1;
    my $y = ($KT + $sigmaCVP - ($KT * $sigmaP) - $KC) / $sigmaP;
#write_log("spread_stake: y=$y");

    # calculate stakes on active bets required to produce equalised gain
    for $horse (keys %horseHash)
    {
        next if (!$horseHash{$horse}{num});
        $x = ($y + $KT - $horseHash{$horse}{c} - $horseHash{$horse}{v}) * $horseHash{$horse}{p}; 
        if ($x < $lowestX)
        {
            $lowestX = $x;
            $lowestHorse = $horse;
        }
        $horseHash{$horse}{x} = $x;
#write_log("spread_stake: horse=$horse num=$horseHash{$horse}{num} status=$horseHash{$horse}{status} x=$x");
    }

    # apply new stakes to best active bets
    for $bet (sort nagsort @BetList) 
    {
        $nagNum = $bet->{nag_num};
        if ($bet->{status} == 0) # active bet
        {
            if ($bet->{is_best} == 1) # apply stake to best active bet
            {
                write_log("INFO: Changing stake of horse $nagNum from $bet->{stake} to $horseHash{$nagNum}{x}");
                $bet->{stake} = $horseHash{$nagNum}{x};
            }
            else # non-best active bets get no stake
            {
                write_log("INFO: Changing stake of horse $nagNum from $bet->{stake} to 0");
                $bet->{stake} = 0;
            }
        }
    }

    # No new stake should be negative.
    # If there is, we need to increase the total stake to push
    # the new stakes up.
    # The total stake should be such that the lowest new stake
    # is zero.
    # We need to calculate what total stake is required and
    # advise the user accordingly.

    write_log("lowestX=$lowestX lowestHorse=$lowestHorse");
    if ($lowestX < -0.0001)
    {
        $c = $horseHash{$lowestHorse}{c};
        $v = $horseHash{$lowestHorse}{v};
        $p = $horseHash{$lowestHorse}{p};
        $cvp = ($c + $v) * $p;
        $newKT = (($c + $v) * $sigmaP) - $sigmaCVP + $KC;
        write_log("  c=$c v=$v p=$p cvp=$cvp");
        write_log("  sigmaCVP=$sigmaCVP sigmaP=$sigmaP KC=$KC newKT=$newKT");
        $Calcs->{recommendedTotalStake} = $newKT;
    }
    else # Don't need to change the total stake
    {
        $Calcs->{recommendedTotalStake} = 0;
    }
}

############################################################
#
# Calculate how much stake has been committed (locked)

sub calc_committed_stake
{
    my $stake = 0;
    for $bet (sort nagsort @BetList)
    {
        $stake += $bet->{stake} if ($bet->{status} == 1);
#write_log("calc_committed_stake: num=$bet->{nag_num} name=$bet->{nag_name} odds=$bet->{odds} stake=$bet->{stake} status=$bet->{status} com_stake=$stake");
    }
    return $stake;
}

############################################################
#
# Calculate wins and losses for given probs and stakes.

sub perform_calcs
{
    my $numBets = scalar(@BetList);
    my $bet;
    my $nom;
    my $denom;
    $Calcs->{totalStake} = 0;
    write_log("Performing calculations on $numBets bets.");

#for $bet (@BetList)
#{
# write_log("FISH nag_num=$bet->{nag_num} nag_name=$bet->{nag_name}");
#}
#write_log("Before sort");
#my @sortedBetList = sort nagsort @BetList;
#write_log("After sort");

    for $bet (sort nagsort @BetList)
    {
#write_log("FISH odds=$bet->{odds}");
        ($nom, $denom) = split /\//, $bet->{odds};
        if ($denom =~ /^\s*$/)
        {
            $denom = 1;
            if (!($nom =~ /^\s*$/))
            {
                $bet->{odds} .= "/1";
            }
        }

        # Calculate probability from odds
        if (is_empty($bet->{odds}))
        {
            $bet->{prob} = "";
        }
        else
        {
            $bet->{prob} = $denom / ($nom + $denom);
        }

        # Calculate win from stake and probability
        if ((is_empty($bet->{stake})) || is_empty($bet->{prob}))
        {
            $bet->{win} = "";
        }
        else
        {
            if ($bet->{prob} < 0.0000001) # avoid div by zero
            {
                $bet->{win} = 0.0;
            }
            else
            {
                $bet->{win} = $bet->{stake} / $bet->{prob} - $bet->{stake};
            }

            if ($bet->{status} <= 1)
            {
                $Calcs->{totalStake} += $bet->{stake};
            }

        }
    }

    flag_best_bets();

    # Now calculate wins and losses for each nag.
    for $bet (sort nagsort @BetList)
    {
#        if ($bet->{status} <= 1) # only consider Active and Confirmed bets
#        {
            $bet->{nag_win} = 0; # sum all winning bets on this nag
            $bet->{nag_lose} = 0; # sum all losses if this nag wins

            for $b (@BetList)
            {
              if ($b->{status} <= 1)
              {
                if ($b->{nag_name} eq $bet->{nag_name})
                {
                    $bet->{nag_win} += $b->{win};
                }
                else
                {
                    $bet->{nag_lose} += $b->{stake};
                }
              }
            }

            $bet->{nag_gain} = $bet->{nag_win} - $bet->{nag_lose};
#        }
    }
write_log("Finished performing calculations on $numBets bets.");
}

############################################################

sub add_bet
{
    my ($nagNum, $nagName, $book, $odds, $stake, $status, $side) = @_;

    $status = 0 if (is_empty($status));

    my $bet = {
        'nag_num'  => $nagNum,
        'nag_name' => $nagName,
        'book'     => $book,
        'odds'     => $odds,
        'stake'    => $stake,
        'status'   => $status,
        'side'     => $side
    };

    if (bet_is_valid($bet))
    {
        write_log("Added new bet for [$nagNum] $nagName");
        push @BetList, $bet;
    }
    else
    {
        write_log("WARNING Not adding invalid bet [$nagNum] $nagName");
    }
}

############################################################

sub save_race_index
{
    my $fname = "${STATICROOT}/$RaceIndexFile";
    my $item;

    open (OUTF, ">$fname");
    if (!OUTF)
    {
        write_log ("Cannot save race to race index file: $fname");
        return;
    }

    printf OUTF "#################\n";
    printf OUTF "# Race Index File\n";
    printf OUTF "#################\n";

    my $count = 0;
    for $item (sort rev_sort @RaceIndexList)
    {
        printf OUTF "$item\n";
        $count++;
    }

    printf OUTF "# EOF\n";
    close(OUTF);

    write_log("Saved $count race indexes to race index file: $fname");
}

############################################################

sub load_race_index
{
    my $fname = "${STATICROOT}/$RaceIndexFile";
    open (INF, "$fname");
    if (!INF)
    {
        write_log ("WARNING: Cannot load race index from file: $fname");
        return;
    }

    @RaceIndexList = ();
    my $count = 0;

    while(<INF>)
    {
        chop;
        next if (/^\s*$/);
        next if (/^#/);
        push @RaceIndexList, $_;
        $count++;
    }

    close(INF);
    write_log("Loaded $count race indexes from race index file: $fname");
}

############################################################

sub save_race
{
    my ($fname) = @_;
    $fname = $RACESROOT . "/" . $fname;

    open (OUTF, ">$fname");
    if (!OUTF)
    {
        write_log("ERROR: Cannot save race to file: $fname");
        return;
    }

    my $numBets = scalar(@BetList);
    for ($i = 0; $i < $numBets; $i++)
    {
        $bet = $BetList[$i];
        printf OUTF "bet:%s,%s,%s,%s,%f,%s,%s\n",
                 $bet->{nag_num}, 
                 $bet->{nag_name}, 
                 $bet->{book}, 
                 $bet->{odds}, 
                 $bet->{stake},
                 $bet->{status},
                 $bet->{side};
    }

    close(OUTF);
    write_log("Saved $numBets bets to race file: $fname");
}

############################################################

sub load_race
{
    my ($fname) = @_;
    $fname = $RACESROOT . "/" . $fname;

    open (INF, "$fname");
    if (!INF)
    {
        write_log("ERROR: Cannot load race from file: $fname");
        return;
    }

    @BetList = ();
    my $count = 0;

    while(<INF>)
    {
        chop;
        next if (/^\s*$/);
        next if (/^#/);
        ($type, $line) = split /:/, $_;
        @data = split /,/, $line;
        add_bet(@data);
        $count++;  
    }

    close(INF);
    write_log("Loaded $count bets from race file: $fname");
}


############################################################

sub delete_race
{
    # Remove an element from the race index list.
    # Element is identified by the filename of the race file.

    my ($fname) = @_;
    my $i;
    for ($i = 0; $i < scalar(@RaceIndexList); $i++)
    {
        ($f, $n, $t, $rest) = split /,/, $RaceIndexList[$i];
        $filename = make_filename($f, $n, $t);
        if ($filename eq $fname)
        {
            # Don't actually delete it - just comment it out.
            $RaceIndexList[$i] = "#" . $RaceIndexList[$i];
        }
    }
    save_race_index();
    load_race_index();
}

############################################################

sub save_bookies
{
    my $fname = "${STATICROOT}/$BookiesFile";

    open (OUTF, ">$fname");
    if (!OUTF)
    {
        write_log("ERROR: Cannot save bookies to file: $fname");
        return;
    }

    my $count = 0;
    for $bookie (sort @BookieList)
    {
        printf OUTF "$bookie\n";
        $count++;
    }

    close(OUTF);
    write_log("Saved $count bookies to bookies file: $fname");
}

############################################################

sub load_bookies
{
    my $fname = "${STATICROOT}/$BookiesFile";

    open (INF, "$fname");
    if (!INF)
    {
        write_log("WARNING: Cannot load bookies from file: $fname");
        return;
    }

    @BookieList = ("");
    my $count = 0;

    while(<INF>)
    {
        chop;
        next if (/^\s*$/);
        next if (/^#/);
        push @BookieList, $_;
        $count++;
    }

    close(INF);
    write_log("Loaded $count bookies from bookies file: $fname");
}

############################################################

sub load_labels
{
    my $fname = "${STATICROOT}/$LabelsFile";

    open (INF, "$fname") 
        || write_log("WARNING: Cannot load labels file: $fname - using default labels");

    $Labels = {};
    my $count = 0;
    while(<INF>)
    {
        chop;
        next if (/^\s*$/);
        next if (/^#/);
        ($name, $value) = split /,/, $_;
        $Labels->{$name} = $value;
        $count++;
    }

    close(INF);
    write_log("Loaded $count labels from labels file: $fname");

    $Labels->{site_title} = "NeighPal" if (!$Labels->{site_title});
    $Labels->{horse} = "Horse" if (!$Labels->{horse});
    $Labels->{side} = "Side" if (!$Labels->{side});
    $Labels->{bookie} = "Bookie" if (!$Labels->{bookie});
    $Labels->{odds} = "Odds" if (!$Labels->{odds});
    $Labels->{stake} = "Stake" if (!$Labels->{stake});
    $Labels->{status} = "Status" if (!$Labels->{status});
    $Labels->{change_status} = "" if (!$Labels->{change_status});
    $Labels->{bet_win} = "Bet Win" if (!$Labels->{bet_win});
    $Labels->{horse_win} = "Horse Win" if (!$Labels->{horse_win});
    $Labels->{stake_loss} = "Stake Loss" if (!$Labels->{stake_loss});
    $Labels->{net_gain} = "Net Gain" if (!$Labels->{net_gain});
    $Labels->{worst_gain} = "Worst Gain" if (!$Labels->{worst_gain});
    $Labels->{total_stake} = "Total Stake" if (!$Labels->{total_stake});
    $Labels->{new_bet} = "New Bet" if (!$Labels->{new_bet});
    $Labels->{new_horse} = "New Horse" if (!$Labels->{new_horse});
    $Labels->{new_bookie} = "New Bookie" if (!$Labels->{new_bookie});
    $Labels->{spread} = "Spread" if (!$Labels->{spread});
    $Labels->{calc} = "Calc" if (!$Labels->{calc});
    $Labels->{name} = "Name" if (!$Labels->{name});
    $Labels->{racecourse} = "Racecourse" if (!$Labels->{racecourse});
    $Labels->{race} = "Race" if (!$Labels->{race});
    $Labels->{new_race} = "New Race" if (!$Labels->{new_race});
    $Labels->{num_runners} = "Number of<br>runners" if (!$Labels->{num_runners});
    $Labels->{betting_manager} = "Betting Manager" if (!$Labels->{betting_manager});
    $Labels->{index_of_races} = "Index Of Races" if (!$Labels->{index_of_races});
    $Labels->{race_input} = "Race Input" if (!$Labels->{race_input});
}

############################################################

sub make_filename
{
    my ($yyyymmdd, $courseName, $hhmm) = @_;
    $courseName =~ s/ /_/g;
    my $fname = $yyyymmdd . "_" . lc($courseName) . "_" . $hhmm . ".dat";
    return $fname;
}

############################################################

sub format_date
{
    my ($yyyymmdd) = @_;
    my $yyyy = substr($yyyymmdd, 0, 4);
    my $mm = substr($yyyymmdd, 4, 2);
    my $dd = substr($yyyymmdd, 6, 2);
    my $mon = substr($MonthList[$mm - 1], 0, 3);
    my $fdate = "$dd $mon $yyyy";
    return $fdate;
}

############################################################

sub format_time
{
    my ($hhmm) = @_;
    my $hr = substr($hhmm, 0, 2);
    my $mn = substr($hhmm, 2, 2);
    my $ftime = "${hr}:${mn}";
    return $ftime;
}

############################################################

sub get_race_title
{
    my ($attributes) = @_;

    ($yyyymmdd, $courseName, $hhmm, $raceName, $locked)
        = split /,/, $attributes;
    my $fname = make_filename($yyyymmdd, $courseName, $hhmm);
    my $raceDate = format_date($yyyymmdd);
    my $startTime = format_time($hhmm);
    my $raceTitle = qq($raceDate <b>$courseName $startTime</b> <i>$raceName</i>);
    return $raceTitle;
}


############################################################
#
# Clean up the bet list by removing bets with no (or invalid)
# nag_num or nag_name.

sub remove_null_bets
{
    my @tmpList = @BetList;
    @BetList = ();
    my $bet;
    for $bet (@tmpList)
    {
        if (bet_is_valid($bet))
        {
            push @BetList, $bet;
        }
    }
}

############################################################

sub bet_is_valid
{
    my ($bet) = @_;

    if (!($bet->{nag_num} =~ /^[0-9]+$/))
    {
        return 0;
    }
    if ($bet->{nag_num} <= 0)
    {
        return 0;
    }
    if (!($bet->{nag_name} =~ /\w+/))
    {
        return 0;
    }
    return 1;
}

############################################################

sub nagnum_already_used
{
    my ($nagNum) = @_;
    my $bet;
    my $isInList = 0;
    for $bet (@BetList)
    {
        if ($nagNum == $bet->{nag_num})
        {
            $isInList = 1;
            last;
        }
    }
    return $isInList;
}

############################################################
1;
