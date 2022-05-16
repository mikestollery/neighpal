############################################################
#
# uber_login.pl
#
# Provides user login/registration functionality
#
# Uberpages:
# login        - login an existing user
# logout       - (doesn't actually generate a page)
# signup       - register a new user
# account      - lets user amend personal details
# passwd       - lets user change password
#
############################################################



############################################################
#
# Handle various requests
#
############################################################

sub uber_login
{
    my $message = "";
    my $page = $cgi->param('page');
    my $reg = $cgi->param('reg');

    if ($reg eq "Login")
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

    # Note the difference between page=login and reg=Login
    if ($page eq "login")
    {
        login_form_page(); # Display login form page
    }
    elsif ($page eq "logout")
    {
        write_action("Logged out.");
        %UBERACC = {};
        add_login_cookie();
        set_globals();
    }
    elsif ($page eq "signup")
    {
        registration_form_page();
    }
    elsif ($page eq "account")
    {
        account_form_page();
    }
    elsif ($page eq "passwd")
    {
        password_form_page();
    }
}




############################################################
#
# Handle user's request to log in.
#
############################################################

sub process_login
{
    my $username = lc($cgi->param('username'));
    return if ($username eq "");

    read_login_file(\%UBERACC, $username);
    my $password = crypt($cgi->param('password'), $username);

    if (($username eq $UBERACC{'USERNAME'})
     && ($password eq $UBERACC{'PASSWORD'})) # login succeeded
    {
#        write_log("Logged in.");
        write_action("Logged in.");
#        my $back = $cgi->param('back');
#        $cgi->param(-name=>'page', -value=>"$back"); # TESTING
        set_globals();
    }
    else # login failed
    {
        %UBERACC = {};

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
    my $verify    = lc($cgi->param('verify'));
    $verify =~ s/ //g;

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

    # Verification
    if ($cgi->param('noverify') eq "noverify")
    {
        log_info("Registration verification is switched off.");
    }
    elsif ($verify ne "fatcock") # hardcoded for pooclub - must configure this
    {
        $message .= "Invalid verification<br>";
    }

    # Check if user is already registered
    my $key;
    my $value;
    my $loginfile  = "${LOGINROOT}/${username}/login.dat";
    open(INF, "$loginfile");
    while(<INF>)
    {
        chop;
        next if (! /;/);
        next if (/^#/);
        ($key, $value) = split /;/, $_;
        if (($key eq "USERNAME") && (lc($value) eq lc($username)))
        {
            $message .= "Username '$username' already exists.";
        }
    }
    close(INF);
write_log(qq(process_registration2 - message="$message"));

    if ($message ne "") # Invalid registration
    {
write_log(qq(process_registration - invalid registration));

        registration_form_page($message);
    }
    else # We can now register this user
    {
        makedir("${LOGINROOT}/$username");
        %UBERACC = (
            USERNAME  => $username,
            PASSWORD  => $password,
            REALNAME  => $name,
            EMAIL     => $email,
            LOCATION  => $location,
            PRIVILEGE => 1
        );
        read_extra_login_fields(\%UBERACC);
        $message = write_login_file(\%UBERACC);
write_log(qq(process_registration - message="$message"));

        if ($message ne "") # Failed to save file
        {
write_log("process_registration - calling registration_form_page");
            registration_form_page($message);
            %UBERACC = {};
        }
        else  # Registration successful
        {
            add_login_cookie();
            write_action("Registered new user: $UBERACC{'USERNAME'}");
            email_notify($UBERENV{OWNER_EMAIL},
                         $UBERENV{ADMIN_EMAIL},
                         "New user: $UBERACC{'USERNAME'}",
                         "Registered new user - $UBERACC{'USERNAME'} $name $location");
        }
    }
write_log("process_registration - end");
}

############################################################
#
# Handle user's request to change account details.
#
############################################################

sub process_account
{
    my $message = "";

    if (! $UBERACC{'USERNAME'})
    {
        $message = qq(Cannot read your login file.);
        write_log("ERROR process_account() Cannot read user file.");
    }
    else
    {
        $UBERACC{'REALNAME'} = $cgi->param('name');
        $UBERACC{'EMAIL'}    = $cgi->param('email');
        $UBERACC{'LOCATION'} = $cgi->param('location');
        read_extra_login_fields(\%UBERACC);
        $message = write_login_file(\%UBERACC);
    }

    if ($message ne "")
    {
        write_log("ERROR Failed to update account details.");
        account_form_page($message);
    }
    else
    {
        write_action("Updated account details.");
    }
}

############################################################
#
# Handle user's request to change password.
#
############################################################

sub process_password_change
{
    my $message = "";

    if (! $UBERACC{'USERNAME'})
    {
        $message = qq(Cannot read your login file.);
        write_log("ERROR process_password_change() Cannot read user file.");
    }
    else
    {
        my $password = crypt($cgi->param('password'), $UBERACC{'USERNAME'});
        my $password2 = crypt($cgi->param('password2'), $UBERACC{'USERNAME'});

        if ($password ne $password2)
        {
            $message = "Passwords do not match.";
        }
        else
        {
            $UBERACC{'PASSWORD'} = $password;
            $message = write_login_file(\%UBERACC);
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


#===========================================================
#
# HTML forms for user data entry
#
#===========================================================


############################################################
#
# Login an existing user
#
############################################################

sub login_form_page
{
    my ($message, $back) = @_;
    my $title = "Login to $SCRIPT_TITLE";
    %UBERACC = {};
    print_html_head();

    $back = previous_page() if (!$back);
    $back = "" if (($back eq "login") || ($back eq "logout"));

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
        <td class="basic">
         <input type="text" name="username" value="" size="16" maxlength="16" />
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Password:</td>
        <td class="basic">
         <input type="password" name="password" value="" size="16" maxlength="16" />
        </td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="hidden" name="page" value="$back" />
         <input type="submit" name="reg" value="Login" />
        </td>
        <td class="basic"><a href="${THIS_SCRIPT}?">home</a></td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
       </tr>
      </table>
     </form>
     <div align="center">
      Not got an account?  You can <a href="${THIS_SCRIPT}?page=signup">register here</a>.
     </div><br />
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
    %UBERACC = {};

    print_html_head();
    print qq(
     <br>
     <form method="POST"
           action="$THIS_SCRIPT"
           enctype="application/x-www-form-urlencoded">
      <table class="basic_c" style="width: 450;">
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
        <td class="basic">Password (again):</td>
        <td class="basic"><input type="password" name="password2" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr>
    );

    my $open = 1;
    open (VER, "${REFROOT}/reg_page_verify.txt") or $open = 0;
    if ($open)
    {
        print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <img src="${IMGROOT}/reg_verify.jpg" width="120" align="left">
         <scan class="basic_faint">
        );
        while(<VER>)
        {
            print $_;
        }
        print qq(
         </scan>
        </td>
        <td class="basic"></td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">Verification:</td>
        <td class="basic"><input type="text" name="verify" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr>
        );
    }
    else
    {
        print qq(
       <input type="hidden" name="noverify" value="noverify" >
        );
    }
    close(VER);

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic" style="font-weight: bold;"><br>Optional</td>
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
       </tr>
    );

    display_extra_login_fields();
    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic"><input type="submit" name="reg" value="Register" /></td>
        <td class="basic"><a href="${THIS_SCRIPT}?">no&nbsp;thanks</a></td>
       </tr>
    );

    $open = 1;
    open (MSG, "${REFROOT}/reg_page_message.txt") or $open = 0;
    if ($open)
    {
        print qq(
       <tr>
        <td class="basic" colspan="4"><br><br>
        );
        while(<MSG>)
        {
            print $_;
        }
        print qq(</td></tr>);
    }
    close(MSG);

    print qq(
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
    my $title = "Your $SCRIPT_TITLE account";

    if (! is_logged_in())
    {
#        $cgi->param(-name=>'page', -value=>"account"); # TESTING
        login_form_page("You need to log in before you can access your account.", "account");
    }

    my $user     = $UBERACC{'USERNAME'};
    my $name     = $UBERACC{'REALNAME'};
    my $email    = $UBERACC{'EMAIL'};
    my $location = $UBERACC{'LOCATION'};

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
       </tr>
    );

    display_extra_login_fields();
    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="submit" name="reg" value="Update" />&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?page=passwd">change password</a>
        </td>
        <td  class="basic" style="vertical-align: bottom;">
         <a href="${THIS_SCRIPT}?">no&nbsp;changes</a>
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
# Change password
#
############################################################

sub password_form_page
{
    my ($message) = @_;
    my $title = "Change Password";
    my $whoami = username_and_priv();

    if (! is_logged_in())
    {
        write_log("ERROR password_form() Username not set.");
        return;
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
        <td class="basic">New password:</td>
        <td class="basic"><input type="password" name="password" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">New password (again):</td>
        <td class="basic"><input type="password" name="password2" value="" size="16" maxlength="16" /></td>
        <td class="basic">&nbsp;</td>
       </tr><tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">&nbsp;</td>
        <td class="basic">
         <input type="submit" name="reg" value="Change" />&nbsp;&nbsp;&nbsp;
         <a href="${THIS_SCRIPT}?page=account">my account</a>
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

sub read_extra_login_fields
{
    my ($acc_ref) = @_;
    my $key;
    my $value;

    my ($fname) = "${REFROOT}/extra_login_fields.dat";
    open (INF, "$fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        ($input_type, $key, $label, $others) = split /;/, $_;
        $key = lc($key);
        if (lc($input_type) eq "date")
        {
            $$acc_ref{"DD_" . uc($key)} = $cgi->param("dd_$key");
            $$acc_ref{"MM_" . uc($key)} = $cgi->param("mm_$key");
            $$acc_ref{"YYYY_" . uc($key)} = $cgi->param("yyyy_$key");
        }
        else
        {
            if (lc($input_type) eq "checkbox") # param is a list
            {
                $value = join (',', $cgi->param("$key"));
            }
            else
            {
                $value = $cgi->param("$key");
            }
            $$acc_ref{uc($key)} = $value;
        }
    }
    close(INF);
}

############################################################

sub display_extra_login_fields
{
    my ($fname) = "${REFROOT}/extra_login_fields.dat";
    open (INF, "$fname");
    while(<INF>)
    {
        chop;
        next if (/^#/);
        next if (/^\s*$/);
        @fields = split /;/, $_;
        if ($fields[0] eq "text")
        {
            print_text_only_field(@fields);
        }
        elsif ($fields[0] eq "radio")
        {
            print_radio_button_field(@fields);
        }
        elsif ($fields[0] eq "checkbox")
        {
            print_checkbox_field(@fields);
        }
        elsif ($fields[0] eq "date")
        {
            print_date_field(@fields);
        }
    }
    close(INF);
}

############################################################

sub print_text_only_field
{
    my ($input_type, $text1, $text2, $others) = @_;

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">${text1}</td>
        <td class="basic">${text2}</td>
        <td class="basic">&nbsp;</td>
       </tr>
    );
}

############################################################

sub print_radio_button_field
{
    my ($input_type, $key, $label, $choices, $delim, $comment, $others) = @_;
    my @choice_list = split /,/, $choices;
    my $key = lc($key);
    my $disabled = "";
    my $checked = "";

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">${label}</td>
        <td class="basic">
    );

    for my $choice (@choice_list)
    {
        $value = $UBERACC{uc($key)};
        $checked = ($value eq $choice) ? qq(checked="checked") : "";
        print qq(
         <input type="radio" name="$key" value="$choice" $checked $disabled />$choice $delim
        );
    }
    print qq(
         <span class="basic_faint">$comment</span>
        </td>
        <td class="basic">&nbsp;</td>
       </tr>
    );
}

############################################################

sub print_checkbox_field
{
    my ($input_type, $key, $label, $choices, $delim, $comment, $others) = @_;
    my @choice_list = split /,/, $choices;
    my $key = lc($key);
    my $value;
    my @value_list;
    my $disabled = "";
    my $checked = "";

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">${label}</td>
        <td class="basic">
    );

    if (! $choices) # no values specified in extra_login_fields.dat
    {
        $checked = ($UBERACC{uc($key)} eq "1") ? qq(checked="checked") : "";
        print qq(
         <input type="checkbox" name="$key" value="1" $checked $disabled />$delim
        );
    }
    else
    {
        for my $choice (@choice_list)
        {
            @value_list = split /,/, $UBERACC{uc($key)};
            $checked = "";
            for $value (@value_list)
            {
                $checked = qq(checked="checked") if ($value eq $choice);
            }
            print qq(
         <input type="checkbox" name="$key" value="$choice" $checked $disabled />$choice $delim
            );
        }
    }
    print qq(
         <span class="basic_faint">$comment</span>
        </td>
        <td class="basic">&nbsp;</td>
       </tr>
    );
}

############################################################

sub print_date_field
{
    my ($input_type, $key, $label, $choices, $delim, $comment, $others) = @_;
    $key = uc($key);

    print qq(
       <tr>
        <td class="basic">&nbsp;</td>
        <td class="basic">${label}</td>
        <td class="basic">
         <table class="basic">
          <tr>
    );
    date_input(lc($key), 1, $UBERACC{"DD_$key"},
                            $UBERACC{"MM_$key"},
                            $UBERACC{"YYYY_$key"});
    print qq(
          </tr>
         </table>
         <span class="basic_faint">$comment</span>
        </td>
        <td class="basic">&nbsp;</td>
       </tr>
    );
}

1;
############################################################
# EOF