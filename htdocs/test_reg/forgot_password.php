<?php # forgot_password.php
 // This page allows a user to reset his password, if forgotten.
 
// Include the configuration file for error management and such.
 require_once ('./includes/config.inc.php');
 
// Set the page title and include the HTML header.
 $page_title = 'Forgot Your Password';
 include ('./includes/header.html'); 

if (isset($_POST['submitted'])) { // Handle the form.
 
   require_once ('./includes/mysql_connect.php'); // Connect to the database.
 
   if (empty($_POST['email'])) { //Validate the email address.
       $uid = FALSE;
       echo '<p><font color="red" size="+1">You forgot to enter your email address!</font></p>';
    } else {
 
        // Check for the existence of that email address.
         $query = "SELECT user_id FROM users WHERE email='". escape_data($_POST['email']) . "'";
         $result = mysql_query ($query)or trigger_error("Query:$query\n<br />MySQL Error: " .mysql_error());
 
        if (mysql_num_rows($result)== 1) {
 
           // Retrieve the user ID.
            list($uid) = mysql_fetch_array ($result, MYSQL_NUM);
 
   } else {
         echo '<p><font color="red"size="+1">The submitted email address does not match those on file!</font></p>';
         $uid = FALSE;
    }
 }

   if ($uid) { // If everything's OK.
 
      // Create a new, random password.
       $p = substr ( md5(uniqid(rand(),1)), 3, 10);

      // Make the query.
       $query = "UPDATE users SET pass=SHA('$p') WHERE user_id=$uid";
       $result = mysql_query ($query) or trigger_error("Query: $query\n<br />MySQL Error: " .mysql_error());
       if (mysql_affected_rows() == 1) {
       // If it ran OK.
 
        // Send an email.
         $body = "Your password to log into SITENAME has been temporarily changed to '$p'. Please log in using this password and your username. At that time you may change your password to something more familiar.";
         mail ($_POST['email'], 'Your temporary password.', $body, 'From: admin@sitename.com');
         echo '<h3>Your password has been changed. You will receive the
         new, temporary password at the email address with which you registered. Once you have logged in with this password, you may change it by clicking on the "Change Password" link.</h3>';
         mysql_close(); // Close the database connection.
         include ('./includes/footer.html'); // Include the HTML footer.
         exit();
 
      } else { // If it did not run OK.
         echo '<p><font color="red"size="+1">Your password could not be changed due to a system error. We apologize for any inconvenience.</font></p>';
 
      }
 
   } else { // Failed the validation test.
       echo '<p><font color="red"size="+1">Please try again.</font></p>';
    }
 
   mysql_close(); // Close the database connection.
 
} // End of the main Submit conditional.
 
?>

<h1>Reset Your Password</h1>
 <p>Enter your email address below and your password will be reset.</p>
 <form action="forgot_password.php" method="post">
    <fieldset>
    <p><b>Email Address:</b> <input type="text"
    name="email" size="20" maxlength="40" value="<?php if (isset($_POST['email'])) echo $_POST['email']; ?>" /></p>
    </fieldset>    <div align="center"><input type="submit" name="submit" value="Reset My Password" /></div>
    <input type="hidden" name="submitted" value="TRUE" />
 </form>
 
<?php
 include ('./includes/footer.html');
 ?> 

