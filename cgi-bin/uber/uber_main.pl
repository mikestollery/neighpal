############################################################
# uber_main.pl
#
# Sets environment specific globals,
# and calls other uber setup functionality
#
# Author: mike@stollery.co.uk
#
############################################################

require "uber/uber_date.pl";

use File::Basename;
use File::Copy;
use CGI qw(:standard);
    $CGI::POST_MAX = 1024 * 5000; # Can't get this to work
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
$SHAREDROOT;
$LOGINROOT;
%UBERENV;    # environment - read from the config file
%UBERACC;    # account details - read from user's login file

$DisplayName;
$LoginMsg;

############################################################

sub uber_main
{
    my @require_list = @_;

    $HTTP_HOST   = $ENV{HTTP_HOST};
    $SENDMAIL    = "/usr/sbin/sendmail -t";
    $ADMIN_EMAIL = $UBERENV{ADMIN_EMAIL} if ($ADMIN_EMAIL eq "");
    $ADMIN_EMAIL = $ENV{SERVER_ADMIN} if ($ADMIN_EMAIL eq "");

    if (scalar(@PRIVILEGE_LIST) == 0)
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
    $DATAROOT = "../htdocs/uber";
    $CSSROOT  = "/uber/css";
    $IMGROOT  = "/uber/images";

    read_login_cookie();

    # can't do any logging before this point

    set_globals($APP_ID);

    read_login_file(\%UBERACC) if (is_logged_in());
#    get_account_globals();
    log_hit();
    log_info("In session") if (is_logged_in());

    for my $require (@require_list)
    {
        require "uber/${require}.pl";
        $require->(); # call function which has same name as $require
    }
}

############################################################

sub set_globals
{
    # $app allows testserver to override its script name
    # so that it can look at the globals of other apps.
    # For all other scripts, $app should be ""

    my ($app) = @_; # used by testserver only
    $app = $SCRIPT_ID if ($app eq "");

    # Server specific globals
    if ($HTTP_HOST eq "localhost")
    {
        #$CSSROOT = "/Users/mike/Sites/stol.uk/neighpal/htdocs/uber/css";
        #$CSSROOT = "/uber/css";
        $CSSROOT = "../htdocs/uber/css";
        
        #$IMGROOT = "/Users/mike/Sites/stol.uk/neighpal/htdocs/uber/images/neighpal";
        #$IMGROOT = "/uber/images";
        $IMGROOT = "../htdocs/uber/images/neighpal";
                
        $DATAROOT = "../htdocs/uber";
        $SENDMAIL = "/usr/sbin/sendmail -t";
    }
    elsif (($HTTP_HOST =~ /ubervoid.com$/)
        || ($HTTP_HOST =~ /shite.org$/)
        || ($HTTP_HOST =~ /stol.uk$/))
    {
        $CSSROOT = "../htdocs/uber/css";
        $IMGROOT = "../htdocs/uber/images";
        $DATAROOT = "../htdocs/uber";
        $SENDMAIL = "/usr/sbin/sendmail -t";
    }
    elsif ($HTTP_HOST eq "stol.co.uk")
    {
        $CSSROOT = "../uber/css";
        $IMGROOT = "/uber/images";
        $DATAROOT = "../uber";
        $SENDMAIL = "/usr/sbin/sendmail -t";
    }
#    elsif ($HTTP_HOST eq "stol.uk")
#    {
#        $CSSROOT = "../htdocs/uber/css";
#        $IMGROOT = "../htdocs/uber/images";
#        $DATAROOT = "../htdocs/uber";
#        $SENDMAIL = "/usr/sbin/sendmail -t";
#    }

    # Input directories
    $REFROOT = "${DATAROOT}/ref";
    $REFROOT .= "/$app" if (-d "${REFROOT}/$app");
    $IMGROOT .= "/$app" if (-d "${DATAROOT}/images/$app");

    # Output directories
    $LOGROOT = "${DATAROOT}/logs";
    makedir("$LOGROOT");
    $LOGROOT .= "/$SCRIPT_ID";
    makedir("$LOGROOT");
    makedir("${LOGROOT}/details");
    makedir("${LOGROOT}/hits");
    makedir("${LOGROOT}/actions");
    $LOGFILE = "${LOGROOT}/details/${SCRIPT_ID}_${YYYYMMDD}.log";
    $HITSFILE = "${LOGROOT}/hits/${SCRIPT_ID}_${YYYYMMDD}.csv";
    $ACTIONSFILE = "${LOGROOT}/actions/${SCRIPT_ID}_${YYYYMMDD}.csv";

    # start of logging for this query
    log_info("* QUERY_STRING $ENV{QUERY_STRING}"); 

    $USERROOT = "${DATAROOT}/users";
    makedir("$USERROOT");
    $USERROOT .= "/$SCRIPT_ID";
    makedir("$USERROOT");
    makedir("${USERROOT}/$UBERACC{'USERNAME'}");
    $SHAREDROOT = "${DATAROOT}/shared";
    makedir("$SHAREDROOT");
    $SHAREDROOT .= "/$SCRIPT_ID";
    makedir("$SHAREDROOT");

    if ($SSO) # Single Sign On
    {
        $LOGINROOT = "${DATAROOT}/users/sso";
        makedir("$LOGINROOT");
        makedir("${LOGINROOT}/$UBERACC{'USERNAME'}");
    }
    else # use app specific login
    {
        $LOGINROOT = $USERROOT;
    }

    # Config data
    open (INF, "${REFROOT}/${SCRIPT_ID}.cfg");
    while(<INF>)
    {
        next if (/^#/);
        next if (/^\s*$/);
        ($name, $value, $comment) = split /;/, $_;
        $UBERENV{$name} = $value;
    }
    close(INF);
}

############################################################
#
#sub zz_write_hit
#{
#    my @items = @_;
#    reset_date_time();
#    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
#    open (HITS, ">>$HITSFILE");
#    if (HITS)
#    {
#        print HITS "$timestamp,$ENV{REMOTE_ADDR},$ENV{REMOTE_HOST},$ENV{HTTP_REFERER},$ENV{QUERY_STRING},$UBERACC{'USERNAME'},$UBERACC{'PRIVILEGE'}\n";
#    }
#    close(HITS);
#}

sub write_hit
{
    log_hit(@_);
}

############################################################
#
#sub zz_write_action
#{
#    my ($action) = @_;
#    reset_date_time();
#    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
#    open (ACTIONS, ">>$ACTIONSFILE");
#    if (ACTIONS)
#    {
#        print ACTIONS "$timestamp,$ENV{REMOTE_ADDR},$UBERACC{'USERNAME'},$UBERACC{'PRIVILEGE'},$action\n";
#    }
#    close(ACTIONS);
#
#    write_log($action); # actions is just a subset of the main log
#}

sub write_action
{
    log_action(@_);
}

############################################################

#sub zz_write_log
#{
#    my @items = @_;
#    reset_date_time();
#    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
#    open (LOG, ">>$LOGFILE");
#    if (LOG)
#    {
#        print LOG "$timestamp $ENV{REMOTE_ADDR} $UBERACC{'USERNAME'}";
#        for $item (@items)
#        {
#            print LOG " $item";
#        }
#        print LOG "\n";
#    }
#    close(LOG);
#}

sub write_log
{
    log_info(@_);
}



# new log writing functions...
############################################################

sub log_hit # record each page hit
{
    my @items = @_;
    reset_date_time();
    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
    open (HITS, ">>$HITSFILE");
    if (HITS)
    {
        print HITS "$timestamp,$ENV{REMOTE_ADDR},$ENV{REMOTE_HOST},$ENV{HTTP_REFERER},$ENV{QUERY_STRING},$UBERACC{'USERNAME'},$UBERACC{'PRIVILEGE'}\n";
    }
    close(HITS);
}

############################################################

sub log_action # record actions that change the data
{
    my ($action) = @_;
    reset_date_time();
    my $timestamp = sprintf ("%02d:%02d:%02d", $Hour, $Min, $Sec);
    open (ACTIONS, ">>$ACTIONSFILE");
    if (ACTIONS)
    {
        print ACTIONS "$timestamp,$ENV{REMOTE_ADDR},$UBERACC{'USERNAME'},$UBERACC{'PRIVILEGE'},$action\n";
    }
    close(ACTIONS);

    log_info($action); # actions is just a subset of the main log
}

############################################################

sub log_info # write to the main details log file
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

sub log_error # same as log_info but with ERROR in it
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
            print LOG " ERROR $item";
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
    log_info("write_login_file()");

    my ($acc_ref) = @_;
    my $message = "";
    if (! $$acc_ref{'USERNAME'})
    {
        $message = qq(ERROR No username - Cannot save login file.);
        return $message;
    }

    # Write user's account data to file
    my $loginfile = "${LOGINROOT}/$$acc_ref{'USERNAME'}/login.dat";
    my $value;
    open(OUTF, ">$loginfile") or $message = "Cannot save login file - $loginfile";
    if ($message eq "")
    {
        print OUTF qq(# Account details\n);
        for my $key (keys %$acc_ref)
        {
            $value = $$acc_ref{$key};
            print OUTF qq(${key};$value\n);
        }
        log_info("Saved login file: $loginfile");
    }
    else
    {
        log_error("write_login_file() Cannot save login file: $loginfile");
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
    my ($acc_ref, $username) = @_;
    log_info("read_login_file(username=$username)");

    $username = $UBERACC{'USERNAME'} if ($username eq "");
    my $loginfile = "${LOGINROOT}/${username}/login.dat";
    my $key;
    my $value;

    open(INF, "$loginfile") or
        log_info("WARNING read_login_file() Cannot read loginfile: $loginfile");
    while(<INF>)
    {
        chop;
        next if (! /;/);
        next if (/^#/);
        ($key, $value) = split /;/, $_;
        $$acc_ref{$key} = $value;
    }
    close(INF);
    $$acc_ref{'PRIVILEGE'} = 0 if ($$acc_ref{'PRIVILEGE'} eq "");
#log_info("read_login_file: USERNAME=$$acc_ref{'USERNAME'} REALNAME=$$acc_ref{'REALNAME'}");

    return;
}

############################################################
#
# Login cookie stores user's login status
#
############################################################

sub add_login_cookie
{
    my $login_cookie = $cgi->cookie(-name => "$COOKIE_LOGIN_NAME",
                                    -value => "USERNAME=$UBERACC{'USERNAME'}",
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
    $UBERACC{'USERNAME'} = $value if ($name eq "USERNAME");
#log_info("read_login_cookie() USERNAME=$UBERACC{'USERNAME'}");
}

############################################################
#
#sub zz_get_account_globals # to be deprecated
#{
#    if (is_logged_in())
#    {
#        my $name = $UBERACC{'REALNAME'};
#        my $user = $UBERACC{'USERNAME'};
#        $DisplayName = ($name) ? "$name [$user]" : $user;
#    }
#    $DisplayName = "Somebody" if (!$DisplayName);
#}
#
############################################################

sub display_name
{
    my $display_name = "";
    if (is_logged_in())
    {
        my $name = $UBERACC{'REALNAME'};
        my $user = $UBERACC{'USERNAME'};
        $display_name = ($name) ? "$name [$user]" : $user;
    }
    $display_name = "Somebody" if (!$display_name);
    return ($display_name);
}

############################################################

sub get_name_for_display
{
    my ($username) = @_;
    return "Someone" if (!$username);
    my $display_name;
    my %account = {};

    read_login_file(\%account, $username);
    my $name = $account{'REALNAME'};
    my $user = $account{'USERNAME'};
    $display_name = ($name) ? "$name [$user]" : $user;
    $display_name = "No one" if (!$display_name);
    return $display_name;
}

############################################################

sub is_logged_in
{
    return ($UBERACC{'USERNAME'} ne "") ? 1 : 0;
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
        log_info("ERROR Failed to create directory '$dir'. errno=$!");
    }
    else
    {
        log_info("Created directory '$dir'.");
    }
}

############################################################
# return the id of the last page visited

sub previous_page
{
    my $prev = $ENV{HTTP_REFERER};
    log_info("previous_page()");

    if  ($prev =~ /\?/)
    {
        $prev =~ s/^.*\?//;
        $prev =~ s/^.*page=//;
        $prev =~ s/&.*$//;
    }
    else
    {
        $prev="";
    }

    return $prev;
}

############################################################

sub username_and_priv
{
    my $priv = "";
    my $privilege = $UBERACC{'PRIVILEGE'};
    if ($privilege > 1)
    {
        $priv = $PRIVILEGE_LIST[$privilege];
        $priv = $privilege if ($priv eq "");
    }
    $priv = "[". $priv . "]" if ($priv ne "");

    return qq(<b>$UBERACC{'USERNAME'}</b>&nbsp;$priv);
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
    print $cgi->header(-cookie => [@COOKIE_LIST]);
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
         | <a href="${THIS_SCRIPT}?page=account">my account</a>
         | <a href="${THIS_SCRIPT}?page=contactus">contact us</a>
         | <a href="${THIS_SCRIPT}?page=logout">logout</a>);
    }
    else
    {
        print qq(
     <form method="POST"
           action="$THIS_SCRIPT"
           enctype="application/x-www-form-urlencoded">
       Login: <input type="text" name="username" value="$UBERACC{'USERNAME'}" size="16" maxlength="16" />
       Password: <input type="password" name="password" value="" size="16" maxlength="16" />
       <input type="hidden" name="login_type" value="inline" />
       <input type="submit" name="reg" value="Login" />
       &nbsp;&nbsp;&nbsp;<a href="${THIS_SCRIPT}?page=signup">sign&nbsp;up</a>
       $LoginMsg
     </form>);
    }
}


############################################################
#
#
#
############################################################

sub print_small_login_line
{
    my ($message) = @_;

    if (is_logged_in())
    {
        my $whoami = username_and_priv();
        print qq(
        <div class="basic_small" style="text-align: left">
         Login: $whoami $message</div>
        );
    }
    else
    {
        print qq(
        <div class="basic_small" style="text-align: left">
         <a href="${THIS_SCRIPT}?page=login">login</a> $message</div>
        );
    }
}


############################################################
#
# Print part of a form for entering a date as DD Month YYYY
# - occupies 3 td columns of a table
#
############################################################

sub date_input
{
    my ($ref, $allow_blanks, $dd, $mm, $yyyy) = @_;
    $ref = "_$ref" if ($ref);
    my $dd_ref   = "dd" . $ref;
    my $mm_ref   = "mm" . $ref;
    my $yyyy_ref = "yyyy" . $ref;
    my $today = date_manip();

    if (!$dd || !$mm)
    {
        $dd   = $cgi->param("$dd_ref");
        $mm   = $cgi->param("$mm_ref");
        $yyyy = $cgi->param("$yyyy_ref");

        # if allow_blanks is set, the default date is blank,
        # otherwise it is initialised as today's date.
        if (!$allow_blanks)
        {
            $dd   = substr($today, 6, 2) if (!$dd);
            $mm   = substr($today, 4, 2) if (!$mm);
            $yyyy = substr($today, 0, 4) if (!$yyyy);
        }
    }

    my $blank = "";
    my $selected = "";

    # Date of month
    $selected = ($dd eq "") ? qq( selected="selected") : "";
    $blank = ($allow_blanks) ? qq(<option value="" $selected></option>) : "";
    print qq(
           <td class="basic">
            <select name="$dd_ref">
             $blank
    );
    for (my $d = 1; $d <= 31; $d++) # Date of month
    {
        $selected = ($d == $dd) ? qq( selected="selected") : "";
        print qq(
             <option value="$d" $selected>$d</option>
        );
    }

    # Month
    $selected = ($mm eq "") ? qq( selected="selected") : "";
    $blank = ($allow_blanks) ? qq(<option value="" $selected></option>) : "";
    print qq(
            </select>
           </td>
           <td class="basic">
            <select name="$mm_ref">
             $blank
    );
    for (my $m = 1; $m <= 12; $m++) # month
    {
        $selected = ($m == $mm) ? qq( selected="selected") : "";
        print qq(
             <option value="$m" $selected>$MonthList[$m - 1]</option>
        );
    }

    # Year
    print qq(
            </select>
           </td>
           <td class="basic">
            <input type="text" name="$yyyy_ref" value="$yyyy" size="4" maxlength="4" />
           </td>
    );
}


############################################################

sub valid_email_address
{
    my ($email) = @_;
    return (($email =~ /@/) && ($email =~ /\./));
}

############################################################
#
# Get list of email addresses from login files where
# the given list_type is set (checked) and EMAIL is valid
#
# move this somewhere else - probably uber_main

sub get_email_list
{
    my ($list_type) = @_;
    my @list = ();
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
        $is_set = $account{$list_type};
        $email = $account{'EMAIL'};

#log_info("get_email_list() list_type=$list_type user_id=$user_id is_set=$is_set email=$email");
        if (($is_set eq "1") && (valid_email_address($email)))
        {
            push @list, $email;
        }
    }
    return @list;
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