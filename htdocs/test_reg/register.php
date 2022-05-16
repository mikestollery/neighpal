





<?php # register.php
 // This is the registration page for the site.
// Include the configuration file for error management and such.
 require_once ('./includes/config.inc.php');
 
// Set the page title and include the HTML header.
 $page_title = 'Register';
 include ('./includes/header.html'); 

if (isset($_POST['submitted'])) {// Handle the form.
 
   require_once ('./includes/mysql_connect.php'); // Connect to the database. 

   // Check for a first name.
    if (preg_match ('/^[[:alpha:]\.\' \-]{2,15}$/', stripslashes(trim($_POST['first_name'])))) {
       $fn = escape_data($_POST ['first_name']);
    } else {
       $fn = FALSE;
       echo '<p><font color="red" size="+1">Please
       enter your first name!</font></p>';
    }
 
   // Check for a last name.
    if (preg_match ('/^[[:alpha:]\.\' \-]{2,30}$/', stripslashes(trim($_POST ['last_name'])))) {
       $ln = escape_data($_POST ['last_name']);
    } else {
       $ln = FALSE;
       echo '<p><font color="red" size="+1">Please
       enter your last name! </font></p>';
    }

   // Check for an email address.
    if (preg_match ('/^[[:alnum:]][a-z0-9_\.\-]*@[a-z0-9\.\-]+\.[a-z]{2,4}$/', stripslashes(trim($_POST ['email'])))) { 
      $e = escape_data($_POST['email']);   
   } else {   
      $e = FALSE;   
      echo '<p><font color="red"
       size="+1">Please enter a valid
       email address!</font></p>';
    } 

   // Check for a password and match against the confirmed password.
    if (preg_match ('/^[[:alnum:]]{4,20}$/', stripslashes(trim($_POST ['password1'])))) { 
      if ($_POST['password1'] == $_POST['password2']) {   
        $p = escape_data($_POST ['password1']);
       } else {   
        $p = FALSE;   
        echo '<p><font color="red" size="+1">
         Your password did not match the confirmed
         password! </font></p>';   
      }   
   } else {   
      $p = FALSE;
       echo '<p><font color="red" size="+1">P
       please enter a valid password!</font></p>';
    }

   if ($fn && $ln && $e && $p) { // If everything's OK.
 
      // Make sure the email address is available.
       $query = "SELECT user_id FROM users WHERE email='$e'";
       $result = mysql_query ($query) or trigger_error
       ("Query: $query\n<br />MySQL Error: " .mysql_error());

      if (mysql_num_rows($result) == 0) { // Available.
 
        // Create the activation code.
         $a = md5(uniqid(rand(), true));
 
        // Add the user.
         $query = "INSERT INTO users(email, pass, first_name,
         last_name, active, registration_date) VALUES
         ('$e', SHA('$p'),'$fn', '$ln', '$a', NOW() )";
         $result = mysql_query ($query) or trigger_error
         ("Query: $query\n<br />MySQL Error: " . mysql_error());

        if (mysql_affected_rows() == 1) {
         // If it ran OK.
 
           // Send the email.
            $body = "Thank you for registering at the
            User Registration site. To activate your account,
            please click on this link:\n\n";
// TODO: Reconfigure ubervoid.com not to require 'htdocs' in the url
            $body .= "http://www.ubervoid.com/htdocs/testreg/activate.php?x=" . mysql_insert_id() . "&y=$a";
            mail($_POST['email'],'Registration Confirmation',$body);
 
           //Finish the page.
            echo '<h3>Thank you for registering! A confirmation email has
            been sent to your address. Please click on the link in that
            email in order to activate your account.</h3>';
            include ('./includes/footer.html'); // Include the HTML footer.
            exit();
 
        } else { // If it did not run OK.
            echo '<p><font color="red" size="+1">You could not be
            registered due to a system error. We apologise for any
            inconvenience.</font></p>';
         }

      } else { // The email address is not available.
         echo '<p><font color="red" size="+1">That email
         address has already been registered. If you have
         forgotten your password, use the link to have your
         password sent to you.</font></p>';
       }
 
   } else { // If one of the data tests failed.
       echo '<p><font color="red" size="+1">Please try again.
       </font></p>';
    }
 
   mysql_close(); // Close the database connection.
 
} // End of the main Submit conditional.
 ?> 

<h1>Register</h1>
 <form action="register.php" method="post">
    <fieldset>
 
   <p><b>First Name:</b> <input type="text" name="first_name"
    size="15" maxlength="15" value="<?php
    if (isset($_POST['first_name'])) echo $_POST['first_name'];
    ?>" /></p>
 
   <p><b>Last Name:</b> <input type="text" name="last_name"
    size="30" maxlength="30" value="<?php
    if (isset($_POST['last_name'])) echo $_POST['last_name'];
    ?>" /></p> 
   <p><b>Email Address:</b> <input type="text" name="email"
    size="40" maxlength="40" value="<?php
    if (isset($_POST['email'])) echo $_POST['email'];
    ?>" /> </p>
 
   <p><b>Password: </b> <input type="password" name="password1"
    size="20" maxlength="20" />
    <small>Use only letters and numbers. Must be between 4 and
    20 characters long. </small></p>
 
   <p><b>Confirm Password: </b><input type="password"
    name="password2" size="20"maxlength="20" /></p>
    </fieldset>
 
   <div align="center" > <input type="submit" name="submit" value=
    "Register" /></div>
    <input type="hidden" name="submitted" value="TRUE" />
 
</form>

<?php
 include ('./includes/footer.html');
 ?> 
 
 