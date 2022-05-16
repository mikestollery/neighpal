############################################################
#
# uber_utils.pl
#
# Provides client with access to the following uberpages.
#
# upload    - upload a file to server side
# contactus - send email to webmaster
# sendmail  - send email to anyone
# 
#
############################################################



############################################################
#
# Handle various requests
#
############################################################

sub uber_utils
{
    my $message = "";
    my $page = $cgi->param('page');

    if ($cgi->param('page') eq "upload")
    {
        print_upload_form_page();
    }
    elsif ($cgi->param('upload'))   # "Upload"
    {
        $message = process_upload();
        print_upload_form_page($message);
    }
    elsif ($page eq "contactus")
    {
        print_contactus_form_page();
    }
    elsif ($cgi->param('contactus')) # eq "Send")
    {
        process_contactus_page();
    }
    elsif (($page eq "sendmail")
        || ($cgi->param('sendmail')))
    {
        print_sendmail_form_page();
    }
}

############################################################
#
# Allow user to upload a file.
#
############################################################

sub print_upload_form_page
{
    my ($message) = @_;
    my $title = "Upload File";
    my $uploadDir = $cgi->param('uploaddir');
    $uploadDir = "${USERROOT}/$UBERACC{'USERNAME'}/upload" if ($uploadDir eq "");

    print_html_head();
    print qq(
     <br>
     <form method="POST" 
           action="$THIS_SCRIPT" 
           enctype="application/x-www-form-urlencoded">
      <table class="basic_c" style="width: 400;">
       <tr>
        <td class="basic_title_c"><nobr>$title</nobr><p></td>
       </tr>
       <td class="basic_warning" style="text-align: center">$message</td>
      </tr><tr>
       <td class="basic" style="text-align: left">

        <form action="$THIS_SCRIPT"
              enctype="multipart/form-data"
              method="post">
         <table class="basic">
          <tr>
           <td class="basic" style="vertical-align: bottom">
              File:
           </td>
           <td class="basic">
              <input type="file" name="datafile" size="40">
           </td>
          </tr><tr>
           <td class="basic" style="vertical-align: bottom">
              To:
           </td>
           <td class="basic">
    );

    if ($UBERACC{'PRIVILEGE'} > 2) # administrators can choose the upload directory
    {
        print qq(
            <input type="text" name="uploaddir" value="$uploadDir" size="40">
        );
    }
    else
    {
        print qq($uploadDir
              <input type="hidden" name="uploaddir" value="$uploadDir">
        );
    }

    print qq(
              <input type="submit" name="upload" value="Upload">

           </td>
          </tr><tr>
           <td class="basic" style="vertical-align: bottom">
              &nbsp;
           </td>
           <td class="basic" style="text-align: right; vertical-align: bottom">
              <a href="${THIS_SCRIPT}?">home</a>
           </td>
          </tr>
         </table>
        </form>

       </td>
      </tr>
     </table>
    );

    print_html_end();
    write_log(qq(print_upload_form_page() message="$message")) if ($message);
    exit(0);
}

############################################################
#
# Handle user's request to upload a file.
#
# See:
# http://www.sitepoint.com/article/uploading-files-cgi-perl
#
############################################################

sub process_upload
{
    return "You must be logged in as $PRIVILEGE_LIST[2] or above."
        if ( (! is_logged_in()) || !($UBERACC{'PRIVILEGE'} > 1) );

    # restrict size of file
#    $CGI::POST_MAX = 1024 * 5000; # Can't get this to work

    my $filename  = $cgi->param('datafile');
    if (!$filename)
    {
        return qq(File too large. Limit is $CGI::POST_MAX);
    }

    # restrict filename characters
    my $safe_filename_characters = "a-zA-Z0-9_.-";
    my ($name, $path, $extension) = fileparse ($filename, '\..*'); 
    $fname = $name . $extension;
    $fname =~ tr/ /_/; 
    $fname =~ s/[^$safe_filename_characters]//g; 

    if ($fname =~ /^([$safe_filename_characters]+)$/) 
    { 
        $fname = $1; 
    } 
    else 
    { 
        return qq(Filename contains invalid characters); 
    } 

    $uploadDir = $cgi->param('uploaddir');
#write_log("uploadDir=$uploadDir");

    makedir("${USERROOT}/$UBERACC{'USERNAME'}");
    makedir("$uploadDir");

    my $upload_filehandle = $cgi->upload('datafile');

    open (UPLOADFILE, ">${uploadDir}/$fname")
        or return "$message - Failed to upload file: $fname"; 
    binmode UPLOADFILE; 

    while ( <$upload_filehandle> ) 
    { 
        print UPLOADFILE; 
    } 

    close UPLOADFILE;

    $message = qq(Uploaded file "$fname" to $uploadDir);
    write_action($message);
    return qq($message);
}

############################################################
#
# Allow user to send us an email
#
############################################################

sub print_contactus_form_page
{
    my ($message) = @_;
    my $title = "Email us";
    my $whoami = username_and_priv();
#    read_login_file(\%UBERACC);
    my $name = $UBERACC{'REALNAME'};
    my $email = $UBERACC{'EMAIL'};

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
         <input type="submit" name="contactus" value="Send" />&nbsp;&nbsp;&nbsp;
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
# Handle user's request to send us an email.
#
############################################################

sub process_contactus_page
{
    my $title = "Sent Email";
    my $name     = $cgi->param('name');
    my $mailfrom = $cgi->param('mailfrom');
    my $subject  = $cgi->param('subject');
    my $message  = $cgi->param('message');

    my $mailto = $ADMIN_EMAIL;
    $mailto = $ENV{SERVER_ADMIN} if ($mailto eq "");
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

    open(SENDMAIL, "|$SENDMAIL") 
        or $thankyou = qq(<div class="basic_warning">ERROR - Sorry, cannot send email.</div>);
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
        <td class="basic" style="font-weight: bold">$UBERACC{'USERNAME'}</td>
        <td class="basic">&nbsp;</td>
       </tr>
    ) if ($UBERACC{'USERNAME'} ne "");

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
    write_action("Contact Us: Sent mail from $from ($name) to $mailto subject: $subject");
    exit(0);
}


############################################################
#
# Allow user to send an email
#
############################################################

sub print_sendmail_form_page
{
    my ($message) = @_;
    my $title = "Sendmail";

    my $mail_from = $cgi->param('mail_from');
    my $mail_to   = $cgi->param('mail_to');
    my $reply_to  = $cgi->param('reply_to');
    my $subject   = $cgi->param('subject');
    my $content   = $cgi->param('content');
    my $content_preview = $content;
    $content_preview =~ s/\n/<br>/g;

    $mail_from = $reply_to if (!$mail_from);
    $reply_to  = $mail_from if (!$reply_to);

#    my $whoami = username_and_priv();
#    my ($user, $passwd, $name, $email, $location, $priv)
#        = read_login_file(\%UBERACC);
    $mail_from = $email if (!$mail_from);
    $reply_to  = $email if (!$reply_to);

    my $disabled = "";
    if (!($mail_to =~ /@/))
    {
        $disabled = qq(disabled="1");
    }

    print_html_head();
    print qq(
     <br>
        <div class="basic_title_c"><nobr>$title</nobr></div>
    );

    if ($cgi->param('sendmail') eq "Preview") # preview mail before sending
    {
        print qq(
        <form method="POST" 
              action="$SERVER" 
              enctype="application/x-www-form-urlencoded">
         <table class="basic" style="width: 600px">
          <tr>
           <td class="basic" style="vertical-align: top">Mail&nbsp;to:</td>
           <td class="basic" style="vertical-align: top">$mail_to</td>
          </tr><tr>
           <td class="basic" style="vertical-align: top">Mail&nbsp;from:</td>
           <td class="basic" style="vertical-align: top">$mail_from</td>
          </tr><tr>
           <td class="basic" style="vertical-align: top">Reply&nbsp;to:</td>
           <td class="basic" style="vertical-align: top">$reply_to</td>
          </tr><tr>
           <td class="basic" style="vertical-align: top">Subject:</td>
           <td class="basic" style="vertical-align: top">$subject</td>
          </tr><tr>
           <td class="basic" style="vertical-align: top">Message:</td>
           <td class="basic" style="vertical-align: top">$content_preview</td>
          </tr><tr>
           <td class="basic"></td>
           <td class="basic" style="vertical-align: top; text-align: right">
            <input type="hidden" name="mail_from"  value="$mail_from" />
            <input type="hidden" name="mail_to"  value="$mail_to" />
            <input type="hidden" name="reply_to" value="$reply_to" />
            <input type="hidden" name="subject"  value="$subject" />
            <input type="hidden" name="content"  value="$content" />
            <input type="hidden" name="reply_to" value="$reply_to" />
            <input type="submit" name="sendmail" value="Send" $disabled />
           </td>
          </tr>
         </table>
         <br clear="all" />
        </form>
        <hr>
        <div class="basic_title_c">Edit</div>
        );
    }
    elsif ($cgi->param('sendmail') eq "Send") # send the email
    {
        open(SENDMAIL, "|$SENDMAIL"); ### or die "Cannot open $sendmail: $!";
        if (SENDMAIL)
        {
            if(
                print SENDMAIL qq(To: $mail_to
From: $mail_from
Reply-to: $reply_to
Subject: $subject
Content-type: text/plain

$content
)
            )
            {
                print qq(<div class="basic" style="text-align: center">
                          Sent mail to $mail_to via $SENDMAIL<p>
                          Another? <a href="${THIS_SCRIPT}?">no thanks</a>
                         </div>);
            }
            else
            {
                print qq(<div class="basic_warning" style="text-align: center">
                          Cannot print to SENDMAIL /($SENDMAIL/)</div>);
            }
            close (SENDMAIL);
        }
        else
        {
            print qq(<div class="basic" style="text-align: center">Cannot open SENDMAIL</div>);
        }

        $mail_to = "";
        $subject = "";
        $content = "";
    }

    # Edit email details
    print qq(
        <br>
        <form method="POST" 
              action="$SERVER">
         <table class="basic">
          <tr>
           <td class="basic">Mail to:</td>
           <td class="basic">
            <input type="text" name="mail_to" value="$mail_to" size="32" maxlength="256" />
           </td>
          </tr><tr>
           <td class="basic">Mail from:</td>
           <td class="basic">
            <input type="text" name="mail_from" value="$mail_from" size="32" maxlength="256" />
           </td>
          </tr><tr>
           <td class="basic">Reply to:</td>
           <td class="basic">
            <input type="text" name="reply_to" value="$reply_to" size="32" maxlength="256" />
           </td>
          </tr><tr>
           <td class="basic">Subject:</td>
           <td class="basic">
            <input type="text" name="subject" value="$subject" size="32" maxlength="256" />
           </td>
          </tr><tr>
           <td class="basic">Message:</td>
           <td class="basic">
            <textarea name="content" cols="72" rows="40">$content</textarea>
           </td>
          </tr><tr>
           <td class="basic"></td>
           <td class="basic" style="text-align: right">
            <a href="${THIS_SCRIPT}?">home</a>
            <input type="submit" name="sendmail" value="Preview" />
           </td>
          </tr>
         </table>
        </form>
    );

    print_html_end();
    exit(0);
}

############################################################

sub email_notify
{
    my ($mail_to, $mail_from, $subject, $content, $name_from) = @_;

#write_log("email_notify 1");
#open (SENDMAIL, ">${SHAREDROOT}/email_notify.txt");
    open(SENDMAIL, "|$SENDMAIL"); ### or die "Cannot open $sendmail: $!";
    print SENDMAIL qq(To: $mail_to
From: "$name_from" <$mail_from>
Reply-to: $mail_from
Subject: $subject
Content-type: text/plain

$content
);
    write_log(qq(email_notify() Sent mail to $mail_to from $mail_from - subject "$subject"));
}

############################################################

sub email_notify_file
{
    my ($mail_to, $mail_from, $subject, $fname, $name_from) = @_;
#write_log ("email_notify_file() fname=$fname");
    my $content = "";
    open (EMAIL_FILE, "$fname") or write_log ("ERROR email_notify_file() Cannot read file: $fname");
    while(<EMAIL_FILE>) {$content .= $_;}
    close(EMAIL_FILE);

#open (SENDMAIL, ">${SHAREDROOT}/email_notify_file.txt");
    open(SENDMAIL, "|$SENDMAIL"); ### or die "Cannot open $sendmail: $!";
    print SENDMAIL qq(To: $mail_to
From: "$name_from" <$mail_from>
Reply-to: $mail_from
Subject: $subject
Content-type: text/plain

$content
);
    write_log(qq(email_notify_file() Sent mail to $mail_to from $mail_from using file $fname - subject "$subject"));
}

1;
############################################################
# EOF