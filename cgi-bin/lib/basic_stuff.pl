############################################################
# basic_stuff.pl
#
# Sets environment specific globals,
# handles logging,
# provides login/registration functionality.
#
# Author: mike@stollery.co.uk
#
############################################################

require "lib/date_manip.pl";

use File::Basename;
use File::Copy;
use CGI qw(:standard);

$cgi = new CGI;

# globals
$HTTP_HOST;
$SCRIPT_NAME       = basename($ENV{SCRIPT_NAME});
($SCRIPT_ID, $tmp) = split /\./, $SCRIPT_NAME;
$SCRIPT_TITLE      = $SCRIPT_ID if ($SCRIPT_TITLE eq "");
# Note: $THIS_SCRIPT is never set.  Somehow the server seems
# to work out what to do without it.

@PRIVILEGE_LIST;
@COOKIE_LIST;
$COOKIE_LOGIN_NAME;
$SENDMAIL;
$ADMIN_EMAIL;

$DATAROOT;
$REFROOT; 
$CSSROOT; 
$IMGROOT;
$LOGROOT;
$LOGFILE;
$USERROOT;
$LOGINROOT;

$Username;
$Privilege;
$LoginMsg;

############################################################

sub basic_stuff
{
    # $app allows testserver to override its script name
    # so that it can look at the globals of other apps.
    # For all other scripts, $app should be ""

    my ($app) = @_;

    $HTTP_HOST         = $ENV{HTTP_HOST};
#    $COOKIE_LOGIN_NAME = uc($SCRIPT_ID) . "_LOGIN";
    $SENDMAIL          = "/usr/sbin/sendmail -t";
    $ADMIN_EMAIL       = $ENV{SERVER_ADMIN} if ($ADMIN_EMAIL eq "");
    if (@PRIVILEGE_LIST == ())
    {
        @PRIVILEGE_LIST = ("Guest",         # 0 (Not logged in)
                           "Member",        # 1
                           "Manager",       # 2
                           "Administrator", # 3
                           "Owner");        # 4
    }

    if ($SSO)
    {
        $COOKIE_LOGIN_NAME = "SSO_LOGIN";
    }
    else
    {
        $COOKIE_LOGIN_NAME = uc($SCRIPT_ID) . "_LOGIN";
    }

    # Server specific directories - default values 
    $DATAROOT = "../htdocs"; 
    $CSSROOT  = "/css"; 
    $IMGROOT  = "/images";

    # Other globals
    $Username = "";
    $Privilege = 0;

    read_login_cookie();
    set_globals($app);
    get_account_globals();
    write_hit();
    write_log("In session") if (is_logged_in());
    process_reg_params();
}

############################################################

sub set_globals
{
    my ($app) = @_;
    $app = $SCRIPT_ID if ($app eq "");

    # Server specific globals
    if ($HTTP_HOST eq "localhost")
    {
        $CSSROOT = "/css";
        #$IMGROOT = "/images";
        $IMGROOT = "/images";
        $DATAROOT = "../htdocs";
        $SENDMAIL = "/usr/sbin/sendmail -t";
    }
    elsif (($HTTP_HOST eq "ubervoid.com")
        || ($HTTP_HOST eq "stol.uk")
        || ($HTTP_HOST eq "www.stol.uk"))
    {
        $CSSROOT = "../htdocs/css";
        $IMGROOT = "../htdocs/images";
        $DATAROOT = "../htdocs";
        $SENDMAIL = "/usr/sbin/sendmail -t";
    }
    elsif ($HTTP_HOST eq "stol.co.uk")
    {
        $CSSROOT = "../css";
        $IMGROOT = "/images";
        $DATAROOT = "..";
        $SENDMAIL = "/usr/sbin/sendmail -t";
    }

    # Input directories
    $REFROOT = "${DATAROOT}/ref";
    $REFROOT .= "/$app" if (-d "${REFROOT}/$app");
    $IMGROOT .= "/$app" if (-d "${DATAROOT}/${IMGROOT}/$app");

    # Output directories
    $LOGROOT = "${DATAROOT}/logs";
    makedir("$LOGROOT");
    $LOGROOT .= "/$SCRIPT_ID";
    makedir("$LOGROOT");
    makedir("${LOGROOT}/details");
    makedir("${LOGROOT}/hits");
    $LOGFILE = "${LOGROOT}/details/${SCRIPT_ID}_${YYYYMMDD}.log";
    $HITSFILE = "${LOGROOT}/hits/${SCRIPT_ID}_${YYYYMMDD}.csv";
    write_log("--> Start HTTP_HOST=$HTTP_HOST SCRIPT_NAME=$SCRIPT_NAME");

    $USERROOT = "${DATAROOT}/users";
    makedir("$USERROOT");
    $USERROOT .= "/$SCRIPT_ID";
    makedir("$USERROOT");
    makedir("${USERROOT}/$Username");

    if ($SSO) # Single Sign On
    {
        $LOGINROOT = "${DATAROOT}/users/sso";
        makedir("$LOGINROOT");
        makedir("${LOGINROOT}/$Username");
    }
    else # use app specific login
    {
        $LOGINROOT = $USERROOT;
    }
}

############################################################

sub process_reg_params
{
    # Note the difference between reg=login and reg=Login

    my $reg = $cgi->param('reg');
#write_log("process_reg_params() - reg=$reg Username=$Username Privilege=$Privilege");
    if ($reg eq "login")
    {
        login_form_page(); # Display login form page
    }
    elsif ($reg eq "logout")
    {
        write_log("Logged out.");
        $Username = "";
        $Privilege = 0;
        add_login_cookie();
        set_globals();
    }
    elsif ($reg eq "signup")
    {
        registration_form_page();
    }
    elsif ($reg eq "account")
    {
        account_form_page();
    }
    elsif ($reg eq "passwd")
    {
        password_form_page();
    }
    elsif ($reg eq "email")
    {
        sendmail_form_page();
    }
    elsif (lc($reg) eq "admin")
    {
        admin_page();
    }
    elsif ($reg eq "all_users")
    {
        admin_all_users_page();
    }
    elsif ($reg eq "logs")
    {
        admin_log_index_page();
    }
    elsif ($reg eq "log")
    {
        admin_log_file_page();
    }
    elsif ($reg eq "Login")
    {
        process_login(); # Handle user's login request
    }
    elsif ($reg eq "Register")
    {
        process_registration();
    }
    elsif ($reg eq "Update")
    {
        process_account();
    }
    elsif ($reg eq "Change")
    {
        process_password_change();
    }
    elsif ($reg eq "Send")
    {
        process_sendmail_page();
    }
    elsif ($cgi->param('admin') eq "Update")
    {
        process_admin();
    }
}

############################################################

sub write_hit
{
    my @items = @_;
    reset_date_time();
    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
    open (HITS, ">>$HITSFILE");
    if (HITS)
    {
        print HITS "$timestamp,$ENV{REMOTE_ADDR},$ENV{REMOTE_HOST},$ENV{HTTP_REFERER},$ENV{QUERY_STRING},$Username,$Privilege\n";
    }
    close(HITS);
}

############################################################

sub write_log
{
    my @items = @_;
    reset_date_time();
    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
    open (LOG, ">>$LOGFILE");
    if (LOG)
    {
        print LOG "$timestamp $ENV{REMOTE_ADDR} $Username";
        for $item (@items)
        {
            print LOG " $item";
        }
        print LOG "\n";
    }
    close(LOG);
}

############################################################
#
# Write account details to user's login file
#
############################################################

sub write_login_file
{
    my ($user, $passwd, $name, $email, $location, $priv) = @_;
    my $message = "";
    my $loginfile = "${LOGINROOT}/${user}/login.dat";
    my $loginrec = qq(${user};${passwd};${name};${email};${location};${priv};;;);

    open(OUTF, ">$loginfile") or $message = "Cannot save login file";
    if ($message eq "")
    {
        print OUTF "${loginrec}\n";
        write_log("write_login_file() - loginrec=$loginrec");
    }
    else
    {
        write_log("ERROR write_login_file() Cannot save login file: $loginfile");
    }
    close(OUTF);

    return $message;
}

############################################################
#
# Get account details from user's login file
#
############################################################

sub read_login_file
{
    my ($username) = @_;
    $username = $Username if ($username eq "");

    my $loginfile = "${LOGINROOT}/${username}/login.dat";
    my $user = "";
    my $passwd = "";
    my $name = "";
    my $email = "";
    my $location = "";
    my $priv = 0;

    open(INF, "$loginfile") or 
        write_log("WARNING read_login_file() Cannot read loginfile: $loginfile"); 
    while(<INF>)
    {
        chop;
        if (/${username};/)
        {
            ($user, $passwd, $name, $email, $location, $priv) = split /;/, $_;
            last;
        }
    }
    close(INF);
    $priv = 0 if ($priv eq "");

    return ($user, $passwd, $name, $email, $location, $priv);
}

############################################################
#
# Login cookie stores user's login status
#
############################################################

sub add_login_cookie
{
    my $login_cookie = $cgi->cookie(-name => "$COOKIE_LOGIN_NAME",
                                    -value => "USERNAME=$Username",
                                    -path => '/');
    push @COOKIE_LIST, $login_cookie;
}

############################################################
#
# Is user already logged in? Check the login cookie
#
############################################################

sub read_login_cookie
{
    my $cookie_name = uc($SCRIPT_ID) . "_LOGIN";
    my $login = $cgi->cookie("$COOKIE_LOGIN_NAME");
    my ($name, $value) = split /=/, $login;
    $Username = $value if ($name eq "USERNAME");
}

############################################################

sub get_account_globals
{
    my ($user, $passwd, $name, $email, $location);
    if (is_logged_in())
    {
        ($user, $passwd, $name, $email, $location, $Privilege)
            = read_login_file();
        $Privilege = 0 if ($Privilege eq "");
    }
}

############################################################

sub is_logged_in
{
    return ($Username ne "") ? 1 : 0;
}

############################################################

sub rev_sort
{
    return ($b cmp $a);
}

############################################################

sub makedir
{
    my ($dir) = @_;
    return if (-d $dir);

    if (mkdir($dir) < 1)
    {
        write_log("ERROR Failed to create directory '$dir'. errno=$!");
    }
    else
    {
        write_log("Created directory '$dir'.");
    }
}

############################################################

sub username_and_priv
{
    my $priv = "";
    if ($Privilege > 1)
    {
        $priv = $PRIVILEGE_LIST[$Privilege];
        $priv = $Privilege if ($priv eq "");
    }
    $priv = "[". $priv . "]" if ($priv ne "");

    return qq(<b>$Username</b>&nbsp;$priv);
}

############################################################

sub print_css_list
{
    for $css (@CSS_LIST)
    {
        print qq(  <link rel="stylesheet" href="${CSSROOT}/$css" type="text/css" />
);
    }
}

############################################################
#
# This function is used when we want to generate a whole
# new page, independent of the client's pages.
#
############################################################

sub print_html_head
{
    print $cgi->header();
    print qq(<html>
 <head>
  <meta http-equiv="Content-Type"
        content="text/html;charset=utf-8" />
  <title>$SCRIPT_TITLE</title>
);
    print_css_list();
    print qq(
 </head>
 <body class="basic">
  <br>
  <table class="basic_c">
   <tr>
    <td>
);
}

############################################################
#
# Always use this in conjunction with print_html_head
#
############################################################

sub print_html_end
{
    print qq(
    </td>
   </tr>
  </table>
 </body>
</html>
);
}

############################################################


#===========================================================
#
# Functions for processing user entered params
#
#===========================================================

############################################################
#
# Handle user's request to log in.
#
############################################################

sub process_login
{
    my $username = lc($cgi->param('username'));
    return if ($username eq "");

    my ($user, $passwd, $name, $email, $location, $priv)
        = read_login_file($username);
    my $password = crypt($cgi->param('password'), $username);

    if (($username eq $user ) && ($password eq $passwd))
    {
        $Username = $username;
        $Privilege = $priv;
        write_log("Logged in.");
        set_globals();
    }
    else
    {
        $Username = "";
        write_log("Invalid login for $username");
        $LoginMsg = qq(<div class="warning align="center">Invalid&nbsp;login for $username</div>);
        if ($cgi->param('login_type') eq "inline")
        {
            # fall through to client's page
        }
        else
        {
            login_form_page($LoginMsg);
        }
    }

    add_login_cookie();
}

############################################################
#
# Handle user's request to register
#
############################################################

sub process_registration
{
write_log("process_registration()");
    my $username  = lc($cgi->param('username'));
    my $password  = crypt($cgi->param('password'), $username);
    my $password2 = crypt($cgi->param('password2'), $username);
    my $name      = $cgi->param('name');
    my $email     = $cgi->param('email');
    my $location  = $cgi->param('location');
    my $message   = "";

# Need to add a check that usernames only
# comprise [A-Z][a-z][0-9]_

    # Validation
    if (length($username) < 4) 
    {
        $message .= "Username must be at least 4 characters.<br>";
    }
    if (length($password) < 4)
    {
        $message .= "Password must be at least 4 characters.<br>";
    }
    if ($password ne $password2)
    {
        $message .= "Passwords do not match.<br>";
    }

    # Check if user is already registered
    my $loginfile  = "${LOGINROOT}/${username}/login.dat";
    open(INF, "$loginfile"); 
    while(<INF>)
    {
        chop;
        ($user, $tmp) = split /;/, $_;
        if ($username eq lc($user))
        {
            $message .= "Username '$username' already exists.";
        }
    }
    close(INF);

    if ($message ne "") # Invalid registration
    {
        registration_form_page($message);
    }
    else # We can now register this user
    {
        makedir("${LOGINROOT}/$username");
        $message = write_login_file($username, $password, $name, 
                                   $email, $location, 1);

        if ($message ne "") # Failed to save file
        {
            registration_form_page($message);
        }
        else  # Registration successful
        {
            $Username = $username;
            $Privilege = 1;
            add_login_cookie();
        }
    }
}

############################################################
#
# Handle user's request to change account details.
#
############################################################

sub process_account
{
    my ($user, $passwd, $name, $email, $location, $priv) = 
        read_login_file();
    my $message = "";

    if ($user eq "")
    {
        $message = qq(Cannot read your login file.);
        write_log("ERROR process_account() Cannot read user file.");
    }
    else
    {
        $name = $cgi->param('name');
        $email = $cgi->param('email');
        $location = $cgi->param('location');
        $message = write_login_file($user, $passwd, $name, 
                                   $email, $location, $priv);
    }

    if ($message ne "")
    {
        write_log("ERROR Failed to update account details: name=$name email=$email location=$location");
        account_form_page($message);
    }
    else
    {
        write_log("Updated account details: name=$name email=$email location=$location");
    }
}

############################################################
#
# Handle user's request to change password.
#
############################################################

sub process_password_change
{
    my ($user, $passwd, $name, $email, $location, $priv) = 
        read_login_file();
    my $message = "";

    if ($user eq "")
    {
        $message = qq(Cannot read your login file.);
        write_log("ERROR process_password_change() Cannot read user file.");
    }
    else
    {
        $password = crypt($cgi->param('password'), $user);
        $password2 = crypt($cgi->param('password2'), $user);

        if ($password ne $password2)
        {
            $message = "Passwords do not match.";
        }
        else
        {
            $message = write_login_file($user, $password, $name, $email, $location, $priv);
        }
    }

    if ($message ne "")
    {
        write_log("ERROR Failed to change password.");
        password_form_page($message);
    }
    else
    {
        write_log("Changed password.");
    }
}

############################################################
#
# Handle user's request to send us an email.
#
############################################################

sub process_sendmail_page
{
    my $title = "Sent Email";
    my $name     = $cgi->param('name');
    my $mailfrom = $cgi->param('mailfrom');
    my $subject  = $cgi->param('subject');
    my $message  = $cgi->param('message');

    my $mailto = $ADMIN_EMAIL;
    $mailto = $ENV{SERVER_ADMIN} if ($mailto eq "");
    my $sendmail = "/usr/sbin/sendmail -t";
    my $from = $mailfrom;
    $from = qq(&lt;anon&gt;) if ($from eq "");
    my $comma_name = $name;
    $comma_name = qq(, $name) if ($comma_name ne "");
    my $thankyou = qq(Thanks for your email$comma_name.  );
    if ($mailfrom =~ /\@/)
    {
        $thankyou .= qq(We will reply to you as soon as possible.);
    }
    else
    {
        $thankyou .= qq(We're afraid we can't reply to you as you didn't give us a valid email address);
    }

    open(SENDMAIL, "|$sendmail") 
        or $thankyou = qq(<div class="warning">ERROR - Sorry, cannot send email.</div>);
    print SENDMAIL qq(To: $mailto
From: $mailfrom
Reply-to: $mailfrom
Subject: $subject
Content-type: text/plain

Message from: $name
Using app: $SCRIPT_TITLE
-----------------------
$message
);
    close(SENDMAIL);

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
        <td class="basic" colspan="2">$thankyou<p></td>
        <td class="basic">&nbsp;</td>
       </tr>
    );

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Login:</td>
        <td class="basic" style="font-weight: bold">$Username</td>
        <td class="basic">&nbsp;</td>
       </tr>
    ) if ($Username ne "");

    print qq(<tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">From:</td>
        <td class="basic">$from</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">To:</td>
        <td class="basic">$SCRIPT_TITLE admin</td>
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
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;&nbsp;&nbsp;</td>
        <td class="basic"><a href="${THIS_SCRIPT}?">return</a>&nbsp;&nbsp;&nbsp;</td>
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
    write_log("Sent mail from $from ($name) to $mailto subject: $subject");
    exit(0);
}

############################################################
#
# Handle administrator's request.
#
############################################################

sub process_admin
{
    my $action = $cgi->param('action');
    my $username = $cgi->param('username');
    my $message = "";
    my ($user, $passwd, $name, $email, $location, $priv) =
        read_login_file($username);

    if ($action eq "priv") # Change privilege
    {
        my $newpriv   = $cgi->param('priv');
        write_login_file($user, $passwd, $name, $email, $location, $newpriv);
        $message = qq(Changed privilege from $PRIVILEGE_LIST[$priv] [$priv]
                      to $PRIVILEGE_LIST[$newpriv] [$newpriv] for $username);
    }
    elsif ($action eq "passwd") # Reset password
    {
        my $seed = (3600 * $Hour) + (60 * $Min) + $Sec;
        srand($seed);
        my $newpasswd = "horse" . (int(rand(899)) + 100);
        write_login_file($user, crypt($newpasswd, $user),
            $name, $email, $location, $priv);
        $message = qq(Password for $username reset to <b>$newpasswd</b>);

        if ($email eq "")
        {
            $message .= qq(<br>User has no email address.);
        }
        else # Inform user by email
        {
            my $app_link = "${THIS_SCRIPT}/cgi-bin/$SCRIPT_NAME";
            my $email_from = $ADMIN_EMAIL;
            open(SENDMAIL, "|$SENDMAIL") 
                or $message = qq(ERROR - Sorry, cannot send email to $email);
            print SENDMAIL qq(To: $email
From: $email_from
Reply-to: $email_from
Subject: $SCRIPT_NAME
Content-type: text/plain

Password for $username has been reset to $newpassword
Please login to $app_link and change your password.
);
            close(SENDMAIL);
            $message .= qq(<br>Sent email to $email from $email_from);
        }
    }
    elsif ($action eq "delete") # Delete account
    {
        makedir("${LOGINROOT}/deleted");
        move("${LOGINROOT}/$username", "${LOGINROOT}/deleted/$username");
        $message = qq(Deleted account: $username);
        write_log("ADMIN $message");
        admin_page($message);
    }
    else
    {
        $message = qq(No change made.);
    }

    write_log("ADMIN $message");
    admin_user_page($username, $message);
}

############################################################


#===========================================================
#
# HTML forms for user data entry
#
#===========================================================

############################################################
#
# Login an existing user on an inline form
#
############################################################

sub inline_login_form
{
    if (is_logged_in())
    {
        my $whoami = username_and_priv();
        print qq(Login: $whoami 
         | <a href="${THIS_SCRIPT}?reg=account">my account</a>
         | <a href="${THIS_SCRIPT}?reg=email">contact us</a>
         | <a href="${THIS_SCRIPT}?reg=logout">logout</a>);
    }
    else
    {
        print qq(
     <form method="POST" 
           action="$THIS_SCRIPT" 
           enctype="application/x-www-form-urlencoded">
       Login: <input type="text" name="username" value="$Username" size="16" maxlength="16" />
       Password: <input type="password" name="password" value="" size="16" maxlength="16" />
       <input type="hidden" name="login_type" value="inline" />
       <input type="submit" name="reg" value="Login" />
       &nbsp;&nbsp;&nbsp;<a href="${THIS_SCRIPT}?reg=signup">sign&nbsp;up</a>
       $LoginMsg
     </form>);
    }
}

############################################################
#
# Login an existing user on a dedicated login page
#
############################################################

sub login_form_page
{
    my ($message) = @_;
    my $title = "Login to $SCRIPT_TITLE";
    $Username = "";

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
        <td class="basic"><input type="text" name="username" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Password:</td>
        <td class="basic"><input type="password" name="password" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic"><input type="submit" name="reg" value="Login" /></td>
        <td class="basic"><a href="${THIS_SCRIPT}?">Back</a></td>
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
# Register a new user
#
############################################################

sub registration_form_page
{
    my ($message) = @_;
    my $title = "Sign up for $SCRIPT_TITLE";
    $Username = "";

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
        <td class="int_warning" colspan="2">$message</td>
       </tr>
        );
    }

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Login:</td>
        <td class="basic"><input type="text" name="username" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Password:</td>
        <td class="basic"><input type="password" name="password" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Password (again):</td>
        <td class="basic"><input type="password" name="password2" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="font-weight: bold;">Optional</td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Name:</td>
        <td class="basic"><input type="text" name="name" value="" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Email:</td>
        <td class="basic"><input type="text" name="email" value="" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Location:</td>
        <td class="basic"><input type="text" name="location" value="" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic"><input type="submit" name="reg" value="Register" /></td>
        <td class="basic"><a href="${THIS_SCRIPT}?">No&nbsp;thanks</a></td>
       </tr><tr>
        <td class="basic" colspan="4"><br><br>
         What goes on in $SCRIPT_TITLE stays in ${SCRIPT_TITLE}.<p>
         We won't pass any of your valuable gen on to anyone else
         or flood you with spam or try to sell you stuff or steal
         money out of your bank account.
         Nor will we take a sneaky look at your password
         (it's encrypted on entry anyway) or laugh at your
         chosen username or poke fun at your home town
         (even if it's Grimsby).<p>
         In short - we're nice people here.
        </td>
       </tr>
      </table>
     </form>
    );

    print_html_end();
    exit(0);
}

############################################################
#
# Manage user's account
#
############################################################

sub account_form_page
{
    my ($message) = @_;
    my $whoami = username_and_priv();
    my $email;
    my $name;
    my $location;
    my $title = "Your $SCRIPT_TITLE account";

    if (! is_logged_in())
    {
        write_log("ERROR account_form() Username not set.");
        return;
    }

    my ($user, $passwd, $name, $email, $location, $priv)
        = read_login_file();
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
        <td class="basic">Name:</td>
        <td class="basic"><input type="text" name="name" value="$name" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Email:</td>
        <td class="basic"><input type="text" name="email" value="$email" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Location:</td>
        <td class="basic"><input type="text" name="location" value="$location" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="submit" name="reg" value="Update" />&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?reg=passwd">change password</a>
        </td>
        <td  class="basic" style="vertical-align: bottom;"><a href="${THIS_SCRIPT}?">no&nbsp;changes</a></td>
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
# Change password
#
############################################################

sub password_form_page
{
    my ($message) = @_;
    my $email;
    my $name;
    my $location;
    my $title = "Change Password";
    my $whoami = username_and_priv();

    if (! is_logged_in())
    {
        write_log("ERROR password_form() Username not set.");
        return;
    }

    my ($user, $passwd, $name, $email, $location, $priv)
        = read_login_file();

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
        <td class="basic">Password:</td>
        <td class="basic"><input type="password" name="password" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Password (again):</td>
        <td class="basic"><input type="password" name="password2" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="submit" name="reg" value="Change" />&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?reg=account">my account</a>
        </td>
        <td class="basic" style="vertical-align: bottom;"><a href="${THIS_SCRIPT}?">cancel</a></td>
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
# Email us
#
############################################################

sub sendmail_form_page
{
    my ($message) = @_;
    my $email;
    my $name;
    my $location;
    my $title = "Email us";
    my $whoami = username_and_priv();
    my ($user, $passwd, $name, $email, $location, $priv)
        = read_login_file();

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
       </tr>
    ) if (is_logged_in());

    print qq(<tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Your&nbsp;name:</td>
        <td class="basic"><input type="text" name="name" value="$name" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Your&nbsp;email:</td>
        <td class="basic"><input type="text" name="mailfrom" value="$email" size="30" maxlength="30" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Subject:</td>
        <td class="basic"><input type="text" name="subject" value="$SCRIPT_TITLE - " size="79" maxlength="79" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Message:</td>
        <td class="basic"><textarea name="message" cols="60" rows="30">$message</textarea></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="submit" name="reg" value="Send" />&nbsp;&nbsp;&nbsp;
        </td>
        <td class="basic" style="vertical-align: bottom;"><a href="${THIS_SCRIPT}?">back</a>&nbsp;&nbsp;&nbsp;</td>
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
# Perform admin operations
#
############################################################

sub admin_page
{
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
    my $title = "$SCRIPT_TITLE Admin";

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
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}?reg=logs&type=hits">hits log</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <a href="${THIS_SCRIPT}?reg=logs&type=details">detail log</a>
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
         <a href="${THIS_SCRIPT}?reg=all_users">all users</a>
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
          <input type="submit" name="reg" value="Admin" />
         </form>

        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         &nbsp;
        </td>
        <td class="basic" style="vertical-align: bottom;"><a href="${THIS_SCRIPT}?">exit</a></td>
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
    my $title = "$SCRIPT_TITLE Admin";
    my $whoami = username_and_priv();
    my ($user, $passwd, $name, $email, $location, $priv) = 
        read_login_file($username);

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
        <td class="basic">$username</td>
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
    for (my $i = 1; $i <= $Privilege; $i++) # cannot promote above your own rank
    {
        $selected = ($i == $priv) ? qq( selected="selected") : "";
        print qq(<option value="$i" $selected>$PRIVILEGE_LIST[$i]</option>
        );
    }
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
         <input type="submit" name="admin" value="Update" />&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?reg=all_users">all users</a>&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?reg=admin">admin</a>
        </td>
        <td class="basic" style="vertical-align: bottom;"><a href="${THIS_SCRIPT}?">exit</a></td>
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
# Show all users for admin
#
############################################################

sub admin_all_users_page
{
    my ($message) = @_;
    my $title = "$SCRIPT_TITLE Admin - All Users";
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
    my ($user, $passwd, $name, $email, $location, $priv);
    my @loginfiles = <${LOGINROOT}/*/login.dat>;
    for $fname (@loginfiles)
    {
        $dir = $fname;
        $dir =~ s/\/login.dat//;
        ($user_id, $tmp) = split /\./, basename($dir);
        ($user, $passwd, $name, $email, $location, $priv)
            = read_login_file($user_id);
        $userlink = $user;
        $userlink = qq(<a href=${THIS_SCRIPT}?reg=admin&user=$user>$user</a>)
            if ($Privilege > $priv);

        print qq(
       <tr>
        <td class="basic">$userlink</td>
        <td class="basic">$name</td>
        <td class="basic">$email</td>
        <td class="basic">$location</td>
        <td class="basic">$priv $PRIVILEGE_LIST[$priv]</td>
       </tr>
        ); # if ($user eq $user_id);
    }

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="vertical-align: bottom;"><a href="${THIS_SCRIPT}?reg=admin">admin</a></td>
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

sub admin_log_index_page
{
    my ($message) = @_;
    my $title = "$SCRIPT_TITLE Admin - Log files";
    my $whoami = username_and_priv();
    my $filetype = lc($cgi->param('type'));
    my $year = $cgi->param('year');
    $year = date_manip("-fYEAR") if ($year eq "");
    my $linktype;
    my $fileext;
    my $logdir;

    # What type of files do we want to look at?
    if ($filetype eq "details")
    {
        $logdir = "${LOGROOT}/details";
        $fileext = ".log";
        $linktype = "hits";
    }
    else
    {
        $logdir = "${LOGROOT}/hits";
        $fileext = ".csv";
        $filetype = "hits";
        $linktype = "details";
    }
    $title .= ": $filetype";

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
            print qq(<a href="$THIS_SCRIPT?reg=logs&type=$filetype&year=$y">$y</a>&nbsp;&nbsp;);
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
         <a href="${THIS_SCRIPT}?reg=logs&type=$linktype">$linktype</a>
       | <a href="${THIS_SCRIPT}?reg=admin">admin</a>
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
            <a href="${THIS_SCRIPT}?reg=log&type=$filetype&f=$f">$f</a>
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
         <a href="${THIS_SCRIPT}?reg=logs&type=$linktype">$linktype</a>
       | <a href="${THIS_SCRIPT}?reg=admin">admin</a>
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

sub admin_log_file_page
{
    my ($message) = @_;
    my $title = "$SCRIPT_TITLE Admin - Log file";
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
    else
    {
        $logdir = "${LOGROOT}/hits";
        $fileext = ".csv";
        $filetype = "hits";
        $linktype = "details";
    }
    $title .= ": $filetype";
    my $date = $fname;
    $date =~ s/$fileext//;
    $date = substr($date, -8);
    $date = date_manip("-fDAYOFWEEK_DD_MONTH_YEAR $date");
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
           <td class="basic" style="font-weight: bold;">$date</td>
          </tr>
         </table>
        </td>
       </tr>
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="text-align: right; vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?reg=logs&type=$filetype">back</a>
       | <a href="${THIS_SCRIPT}?reg=admin">admin</a>
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic" style="font-weight: bold;"></td>
        <td class="basic" style="font-weight: normal;" colspan="3">
    );

    if ($filetype eq "hits") # format a csv file
    {
        print qq(
         <table class="basic_fill">
          <tr>
           <td class="basic" style="font-weight: bold">Time</td>
           <td class="basic" style="font-weight: bold">Rem&nbsp;IP</td>
           <td class="basic" style="font-weight: bold">Rem&nbsp;Host</td>
           <td class="basic" style="font-weight: bold">Referer</td>
           <td class="basic" style="font-weight: bold">Query</td>
           <td class="basic" style="font-weight: bold">User</td>
           <td class="basic" style="font-weight: bold">Priv</td>
          </tr>
        );

        open (INF, "$fname");
        while(<INF>)
        {
            chop;
            ($timestamp, $remote_addr, $remote_host, $http_referer, 
             $query_string, $user, $priv) = split /,/, $_;
            print qq(
          <tr>
           <td class="basic_fill">$timestamp</td>
           <td class="basic_fill">$remote_addr</td>
           <td class="basic_fill">$remote_host</td>
           <td class="basic_fill">$http_referer</td>
           <td class="basic_fill">$query_string</td>
           <td class="basic_fill">$user</td>
           <td class="basic_fill">$priv</td>
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
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="text-align: right; vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?reg=logs&type=$filetype">back</a>
       | <a href="${THIS_SCRIPT}?reg=admin">admin</a>
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

sub print_copyright
{
    my ($year, $name) = @_;
    $year = $Year if ($year eq "");
    $name = $ENV{SERVER_NAME} if ($name eq "");
    my $copyright = "copyright &copy; $name $year";
    $copyright .= "-$Year" if ($Year > $year);
    print qq(
     <div class="basic_copyright">$copyright</div>
    );

}

############################################################
1;
