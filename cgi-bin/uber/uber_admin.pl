############################################################
#
# uber_admin.pl
#
# Provides the following administration functionality
#
# - reset a user's password
# - change a user's privilege
# - read log files
#
# Uberpages:
# admin        - top level admin page
# admin_users  - index of all users
# admin_logs   - index of logs
# admin_log    - contents of a log file
#
# The client is responsible for choosing what Privilege
# level permits access to the admin page.
#
############################################################



############################################################
#
# Handle various requests
#
############################################################

sub uber_admin
{
    my $message = "";
    my $page = $cgi->param('page');

    if ($cgi->param('admin') eq "Update")
    {
        process_admin();
    }
    elsif (lc($page) eq "admin") # so that the "Admin" button
    {                            # goes to this page
        print_admin_page();
    }
    elsif ($page eq "admin_users")
    {
        print_admin_users_page();
    }
    elsif ($page eq "admin_logs")
    {
        print_admin_log_index_page();
    }
    elsif ($page eq "admin_logfile")
    {
        print_admin_log_file_page();
    }
}


############################################################
#
# Handle administrator's request.
#
############################################################

sub process_admin
{
    return if ($UBERACC{'PRIVILEGE'} < 3);

    my $action = $cgi->param('action');
    my $username = $cgi->param('username');
    my $message = "";
    my %account;
    read_login_file(\%account, $username);

    if ($action eq "priv") # Change privilege
    {
        my $newpriv = $cgi->param('priv');
        my $oldpriv = $account{'PRIVILEGE'};
        $account{'PRIVILEGE'} = $newpriv;
        write_login_file(\%account, $zzuser, $zzpasswd, $zzname, $zzemail, $zzlocation, $zznewpriv);
        $message = qq(Changed privilege from $PRIVILEGE_LIST[$oldpriv] [$oldpriv]
                      to $PRIVILEGE_LIST[$newpriv] [$newpriv] for $username);
    }
    elsif ($action eq "passwd") # Reset password
    {
        my $seed = (3600 * $Hour) + (60 * $Min) + $Sec;
        srand($seed);
        my $newpasswd = "horse" . (int(rand(899)) + 100);

        $account{PASSWORD} = crypt($newpasswd, $username);
        write_login_file(\%account, $zzuser, crypt($newpasswd, $username),
            $zzname, $zzemail, $zzlocation, $zzpriv);
#        $message = qq(Password for $username reset to <b>$newpasswd</b>);

        $message = qq(Password for $username reset);

        my $email_to = $account{EMAIL};
        if ($email_to eq "")
        {
            $message .= qq(<br>User $username has no email address.);
        }
        else # Inform user by email
        {
            my $app_link = "${THIS_SCRIPT}/cgi-bin/${SCRIPT_NAME}?";
            my $email_from = $ADMIN_EMAIL;
            open(SENDMAIL, "|$SENDMAIL")
                or $message = qq(ERROR - Sorry, cannot send email to $email_to);
            print SENDMAIL qq(To: $email_to
From: $email_from
Reply-to: $email_from
Subject: $SCRIPT_NAME
Content-type: text/plain

Password for $username has been reset to $newpassword
Please login to $app_link and change your password.
);
            close(SENDMAIL);
            $message .= qq(<br>Sent email to $email_to from $email_from);
        }
    }
    elsif ($action eq "delete") # Delete account
    {
        makedir("${LOGINROOT}/deleted");
        move("${LOGINROOT}/$username", "${LOGINROOT}/deleted/$username");
        $message = qq(Deleted account: $username);
        write_action("ADMIN $message");
    }
    else
    {
        $message = qq(No change made.);
    }

    write_action("ADMIN $message");
    admin_user_page($username, $message);
}

############################################################
#
# Perform admin operations
#
############################################################

sub display_extra_login_commands
{
    my ($fname) = "${REFROOT}/extra_admin_commands.dat";
    open (INF, "$fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($name, $link, $others) = split /;/, $_;

        if ($link ne "")
        {
            print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}$link">$name</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr>
            );
        }
        else
        {
            print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic"><b>$name</b></td>
        <td class="basic">&nbsp;</td>
       </tr>
            );
        }
    }
}

sub print_admin_page
{
#write_action("FISH viewed the admin page");
    my ($message) = @_;
    my $whoami = username_and_priv();
    my $username = $cgi->param('user');
    if ($username ne "")
    {
        admin_user_page($username, $message);
        return;
    }
    # else... prompt for username

    my ($message) = @_;
    my $title = "$SCRIPT_TITLE manage";

    print_html_head();
    print qq(
     <br>
      <table class="basic_c" style="width: 400;">
       <tr>
        <td class="basic_title_c" colspan="4"><nobr>$title</nobr><p></td>
       </tr>
    );

    if ($message ne "")
    {
        print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic_warning" colspan="2">$message</td>
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
    );

    display_extra_login_commands();

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}?page=admin_logs&type=actions">actions log</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}?page=admin_logs&type=hits">hits log</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}?page=admin_logs&type=details">detail log</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}?page=admin_users">all users</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Select user:</td>
        <td class="basic">

         <form method="POST"
               action="$THIS_SCRIPT"
               enctype="application/x-www-form-urlencoded">
          <input type="text" name="user" value="" size="16" maxlength="16" />
          <input type="submit" name="page" value="Admin" />
         </form>

        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         &nbsp;
        </td>
        <td class="basic" style="vertical-align: bottom;"><a href="${THIS_SCRIPT}?">home</a></td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
       </tr>
      </table>
    );

    print_html_end();
    exit(0);
}


############################################################
#
# Perform admin operations on a specified user
#
############################################################

sub admin_user_page
{
    my ($username, $message) = @_;
    my $title = "$SCRIPT_TITLE manage";
    my $whoami = username_and_priv();
    %account = {};
    read_login_file(\%account, $username);

    my $user     = $account{'USERNAME'};
    my $name     = $account{'REALNAME'};
    my $email    = $account{'EMAIL'};
    my $location = $account{'LOCATION'};
    my $priv     = $account{'PRIVILEGE'};

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

    if ($message ne "")
    {
        print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic_warning" colspan="2">$message</td>
       </tr>
        );
    }

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Login:</td>
        <td class="basic">$whoami</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Username:</td>
        <td class="basic">$user</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Name:</td>
        <td class="basic">$name</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Email:</td>
        <td class="basic">$email</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Location:</td>
        <td class="basic">$location</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Privilege:</td>
        <td class="basic">
         <select name="priv" style="width: 200px">
    );

    my $selected = "";
    for (my $i = 1; $i <= $UBERACC{'PRIVILEGE'}; $i++) # cannot promote above your own rank
    {
        $selected = ($i == $priv) ? qq( selected="selected") : "";
        print qq(<option value="$i" $selected>$PRIVILEGE_LIST[$i]</option>
        );
    }
    my $disabled=qq(disabled="disabled") if ($UBERACC{'PRIVILEGE'} < 3);
    print qq(
         </select>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Action:</td>
        <td class="basic">
         <select name="action" style="width: 200px">
          <option value="none" selected="selected">None</option>
          <option value="priv">Change Privilege</option>
          <option value="passwd">Reset Password</option>
          <option value="delete">Delete</option>
         </select>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="hidden" name="username" value="$username" />
         <input type="submit" name="admin" value="Update" $disabled />&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?page=admin_users">all users</a>&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?page=admin">admin</a>
        </td>
        <td class="basic" style="vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?">home</a>
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

    if ($UBERACC{'PRIVILEGE'} < 3)
    {
        print qq(You need to be an administrator to use this page.);
    }
    print_html_end();
    exit(0);
}

############################################################
#
# Show all users for admin
#
############################################################

sub print_admin_users_page
{
    my ($message) = @_;
    my $title = "$SCRIPT_TITLE manage - all users";
    my $whoami = username_and_priv();

    print_html_head();
    print qq(
     <br>
     <form method="POST"
           action="$THIS_SCRIPT"
           enctype="application/x-www-form-urlencoded">
      <table class="basic_c">
       <tr>
        <td class="basic_title_c" colspan="4"><nobr>$title</nobr><p></td>
        <td class="basic">&nbsp;</td>
       </tr>
    );

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic_warning" colspan="3">$message</td>
        <td class="basic">&nbsp;</td>
       </tr>
    ) if ($message ne "");

    print qq(
       <tr>
        <td class="basic">Login:</td>
        <td class="basic" colspan="3">$whoami<p></td>
        <td class="basic">&nbsp;</td>
       </tr>
       <tr>
        <td class="basic" style="font-weight: bold;">Login</td>
        <td class="basic" style="font-weight: bold;">Name</td>
        <td class="basic" style="font-weight: bold;">Email</td>
        <td class="basic" style="font-weight: bold;">Location</td>
        <td class="basic" style="font-weight: bold;">Privilege</td>
       </tr>
    );

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
        $userlink = $account{'USERNAME'};
        $userlink = qq(<a href=${THIS_SCRIPT}?page=admin&user=$user_id>$user_id</a>)
            if ($UBERACC{'PRIVILEGE'} > $account{'PRIVILEGE'});

        print qq(
       <tr>
        <td class="basic">$userlink</td>
        <td class="basic">$account{'REALNAME'}</td>
        <td class="basic">$account{'EMAIL'}</td>
        <td class="basic">$account{'LOCATION'}</td>
        <td class="basic">$account{'PRIVILEGE'} $PRIVILEGE_LIST[$account{'PRIVILEGE'}]</td>
       </tr>
        ); # if ($user eq $user_id);
    }

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?page=admin">admin</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
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
# Index of log files
#
############################################################

sub print_admin_log_index_page
{
    my ($message) = @_;
    my $title = "$SCRIPT_TITLE manage - log files";
    my $whoami = username_and_priv();
    my $filetype = lc($cgi->param('type'));
    my $year = $cgi->param('year');
    $year = date_manip("-fYEAR") if ($year eq "");
    my $linktype;
    my $fileext;
    my $logdir;
    my $colour = "gray";

    # What type of files do we want to look at?
    if ($filetype eq "details")
    {
        $logdir = "${LOGROOT}/details";
        $fileext = ".log";
        $linktype = "actions";
        $linktype2 = "hits";
        $colour = "#c00000";
    }
    elsif ($filetype eq "actions")
    {
        $logdir = "${LOGROOT}/actions";
        $fileext = ".csv";
        $linktype = "hits";
        $linktype2 = "details";
        $colour = "#00c000";
    }
    else
    {
        $logdir = "${LOGROOT}/hits";
        $fileext = ".csv";
        $filetype = "hits";
        $linktype = "actions";
        $linktype2 = "details";
        $colour = "#c0a000";
    }
#    $title .= qq(: <span style="text-color: $colour;">$filetype</span>);
    $title .= qq(: <font color="$colour">$filetype</font>);

    # Get list of years of log files
    my @years = ();
    my $prev_f = "";
    for $fname (sort <${logdir}/*$fileext>)
    {
        $f = basename($fname);
        $f =~ s/$fileext$//;
        $f = substr($f, -8);
        $f = substr($f, 0, 4);
        push @years, $f if ($f != $prev_f);
        $prev_f = $f;
    }

    print_html_head();

    print qq(
     <br>
     <form method="POST"
           action="$THIS_SCRIPT"
           enctype="application/x-www-form-urlencoded">
      <table class="basic_c">
       <tr>
        <td class="basic_title_c" colspan="4"><nobr>$title</nobr><p></td>
        <td class="basic">&nbsp;</td>
       </tr>
    );

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic_warning" colspan="3">$message</td>
        <td class="basic">&nbsp;</td>
       </tr>
    ) if ($message ne "");

    print qq(
       <tr>
        <td class="basic" style="font-weight: bold;"></td>
        <td class="basic" style="font-weight: bold;" colspan="3">
         <table class="basic">
          <tr>
           <td class="basic">Login:</td>
           <td class="basic">$whoami</td>
          </tr><tr>
           <td class="basic">Directory:</td>
           <td class="basic">$logdir</td>
          </tr><tr>
           <td class="basic">Year:</td>
           <td class="basic">
    );

    for $y (sort rev_sort @years)
    {
        if ($y == $year)
        {
            print qq(<b>$year</b>&nbsp;&nbsp;);
        }
        else
        {
            print qq(<a href="$THIS_SCRIPT?page=admin_logs&type=$filetype&year=$y">$y</a>&nbsp;&nbsp;);
        }
    }

    print qq(
           </td>
          </tr>
         </table>
         <br clear="all" />
        </td>
       </tr>
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;Log $filetype:</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="text-align: right; vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?page=admin_logs&type=$linktype">$linktype</a>
       | <a href="${THIS_SCRIPT}?page=admin_logs&type=$linktype2">$linktype2</a>
       | <a href="${THIS_SCRIPT}?page=admin">admin</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic" style="font-weight: bold;"></td>
        <td class="basic" style="font-weight: bold;" colspan="3">
         <table class="basic">
          <tr>
           <td class="basic" style="text-align: left; font-weight: bold" colspan="4">Date</td>
           <td class="basic" style="text-align: left; font-weight: bold">Lines</td>
           <td class="basic" style="text-align: left; font-weight: bold">Errors</td>
           <td class="basic" style="text-align: left; font-weight: bold">Filename</td>
          </tr>
    );

    my $fname;
    my $dir;
    my $date;
    my ($user, $passwd, $name, $email, $location, $priv);
    my @logfiles = <${logdir}/*${year}[0-3][0-9][0-9][0-9]$fileext>;
    for $fname (sort rev_sort @logfiles)
    {
        $f = basename($fname);

        # get date from filename
        $date = $f;
        $date =~ s/$fileext$//;
        $date = substr($date, -8);
        $date = date_manip("-fDOW_DD_MON_YEAR $date");
        ($dow, $dd, $mon, $year) = split / /, $date;

        # count lines and errors
        $lines = 0;
        $errors = 0;
        open (INF, "$fname") or $lines = -1;
        while(<INF>)
        {
            $lines++;
            $errors++ if (/ERROR/);
        }
        close(INF);

        print qq(
          <tr>
           <td class="basic" style="text-align: left">$dow</td>
           <td class="basic" style="text-align: right">$dd</td>
           <td class="basic" style="text-align: left">$mon</td>
           <td class="basic" style="text-align: left">$year</td>
           <td class="basic" style="text-align: right">$lines</td>
           <td class="basic" style="text-align: right">$errors</td>
           <td class="basic" style="text-align: left">
            <a href="${THIS_SCRIPT}?page=admin_logfile&type=$filetype&f=$f">$f</a>
           </td>
          </tr>
        );
    }

    print qq(
         </table>
        </td>
        <td class="basic" style="font-weight: bold;"></td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="text-align: right; vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?page=admin_logfiles&type=$linktype">$linktype</a>
       | <a href="${THIS_SCRIPT}?page=admin_logfiles&type=$linktype2">$linktype2</a>
       | <a href="${THIS_SCRIPT}?page=admin">admin</a>
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
# Contents of a log file
#
############################################################

sub print_admin_log_file_page
{
    my ($message) = @_;
    my $title = "$SCRIPT_TITLE manage - log file";
    my $whoami = username_and_priv();
    my $filetype = lc($cgi->param('type'));
    my $year = $cgi->param('year');
    my $fname = $cgi->param('f');
    $year = date_manip("-fYEAR") if ($year eq "");
    my $linktype;
    my $fileext;
    my $logdir;

    # What type of file are we looking at?
    if ($filetype eq "details")
    {
        $logdir = "${LOGROOT}/details";
        $fileext = ".log";
        $linktype = "hits";
    }
    elsif ($filetype eq "actions")
    {
        $logdir = "${LOGROOT}/actions";
        $fileext = ".csv";
        $linktype = "actions";
    }
    else
    {
        $logdir = "${LOGROOT}/hits";
        $fileext = ".csv";
        $filetype = "hits";
        $linktype = "details";
    }

    # default log file should be today's
    if ($fname eq "")
    {
        $fname = "${SCRIPT_TITLE}_${YYYYMMDD}.csv";
    }

    $title .= ": $filetype";
    my $date = $fname;
    $date =~ s/$fileext//;
    $date = substr($date, -8);
    my $display_date = date_manip("-fDAYOFWEEK_DD_MONTH_YEAR $date");
    $fname = $logdir . "/" . $fname;

    print_html_head();

    print qq(
     <br>
     <form method="POST"
           action="$THIS_SCRIPT"
           enctype="application/x-www-form-urlencoded">
      <table class="basic_c">
       <tr>
        <td class="basic_title_c" colspan="4"><nobr>$title</nobr><p></td>
        <td class="basic">&nbsp;</td>
       </tr>
    );

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic_warning" colspan="3">$message</td>
        <td class="basic">&nbsp;</td>
       </tr>
    ) if ($message ne "");

    print qq(
       <tr>
        <td class="basic" style="font-weight: bold;"></td>
        <td class="basic" style="font-weight: bold;" colspan="3">
         <table class="basic">
          <tr>
           <td class="basic">Login:</td>
           <td class="basic">$whoami</td>
          </tr><tr>
           <td class="basic">Filename:</td>
           <td class="basic">$fname</td>
          </tr><tr>
           <td class="basic">Date:</td>
           <td class="basic" style="font-weight: bold;">$display_date</td>
          </tr>
         </table>
        </td>
       </tr>
    );

    log_file_links($filetype, $date, $fileext);

    print qq(
       <tr>
        <td class="basic" style="font-weight: bold;"></td>
        <td class="basic" style="font-weight: normal;" colspan="3">
    );

    if ($filetype eq "hits") # read a csv file of hits data
    {
        print qq(
         <table class="basic_fill">
          <tr>
           <td class="basic" style="font-weight: bold">Time</td>
           <td class="basic" style="font-weight: bold">Rem&nbsp;IP</td>
           <td class="basic" style="font-weight: bold">Rem&nbsp;Host</td>
           <td class="basic" style="font-weight: bold">User</td>
           <td class="basic" style="font-weight: bold">Priv</td>
           <td class="basic" style="font-weight: bold">Query</td>
           <td class="basic" style="font-weight: bold">Referer</td>
          </tr>
        );

        open (INF, "$fname");
        while(<INF>)
        {
            chop;
            ($timestamp, $remote_addr, $remote_host, $http_referer,
             $query_string, $user, $priv) = split /,/, $_;
            $http_referer =~ s/http:\/\/.*\/cgi-bin\/pooclub.cgi//;
#            $http_referer =~ s/pooclub/pieclub/;
            print qq(
          <tr>
           <td class="basic_fill">$timestamp</td>
           <td class="basic_fill">$remote_addr</td>
           <td class="basic_fill">$remote_host</td>
           <td class="basic_fill">$user</td>
           <td class="basic_fill">$priv</td>
           <td class="basic_fill">?$query_string</td>
           <td class="basic_fill">$http_referer</td>
          </tr>
            );
        }
        print qq(
         </table>
        );
    }
    elsif ($filetype eq "actions") # read a csv file of actions data
    {
        print qq(
         <table class="basic_fill">
          <tr>
           <td class="basic" style="font-weight: bold">Time</td>
           <td class="basic" style="font-weight: bold">Rem&nbsp;IP</td>
           <td class="basic" style="font-weight: bold">User</td>
           <td class="basic" style="font-weight: bold">Priv</td>
           <td class="basic" style="font-weight: bold">Action</td>
          </tr>
        );

        open (INF, "$fname");
        while(<INF>)
        {
            chop;
            ($timestamp, $remote_addr, $user, $priv, $action) = split /,/, $_;
            print qq(
          <tr>
           <td class="basic_fill">$timestamp</td>
           <td class="basic_fill">$remote_addr</td>
           <td class="basic_fill">$user</td>
           <td class="basic_fill">$priv</td>
           <td class="basic_fill">$action</td>
          </tr>
            );
        }
        print qq(
         </table>
        );
    }
    else # print it raw
    {
        print qq(
         <pre>
);
        open (INF, "$fname");
        while(<INF>) {print qq($_);}
        close(INF);

        print qq(
         </pre>
        );
    }

    print qq(
        </td>
        <td class="basic" style="font-weight: bold;"></td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
       </tr>
    );

    log_file_links($filetype, $date, $fileext);

    print qq(
      </table>
     </form>

    );

    print_html_end();

    exit(0);
}

############################################################

sub log_file_links
{
    my ($filetype, $date, $fileext) = @_;
    my $previous_date = date_manip("-d-1 $date");
    my $next_date = date_manip("-d1 $date");

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}?page=admin_logfile&type=${filetype}&f=${SCRIPT_TITLE}_${previous_date}${fileext}">previous date</a>
       | <a href="${THIS_SCRIPT}?page=admin_logfile&type=${filetype}&f=${SCRIPT_TITLE}_${next_date}${fileext}">next date</a>
        </td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="text-align: right; vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?page=admin_logs&type=$filetype">logs</a>
       | <a href="${THIS_SCRIPT}?page=admin">admin</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr>
    );
}


1;
############################################################
# EOF