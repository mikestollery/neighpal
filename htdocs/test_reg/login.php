

<?php # login.php
 // This is the login page for the site.
 
// Include the configuration file for error management and such.
 require_once ('./includes/config.inc.php');
 
// Set the page title and include the HTML header.
 $page_title = 'Login';
 include ('./includes/header.html'); 

if (isset($_POST['submitted'])) { // Check if the form has been submitted.
 
   require_once ('./includes/mysql_connect.php');
    // Connect to the database.
 
   // Validate the email address.
    if (!empty($_POST['email'])) {
       $e = escape_data($_POST ['email']);
    } else {
       echo '<p><font color="red"size="+1"> You forgot to enter your email address!
       </font></p>';
       $e = FALSE;
    }
 
   // Validate the password.
    if (!empty($_POST['pass'])) {
       $p = escape_data($_POST ['pass']);
    } else {
       $p = FALSE;
       echo '<p><font color="red"size="+1"> You forgot to enter your password!
       </font></p>';
    } 

if ($e && $p) { // If everything's OK.
 
   // Query the database.
    $query = "SELECT user_id, first_name FROM users WHERE (email='$e' AND pass=SHA('$p')) AND active IS NULL";
    $result = mysql_query ($query) or trigger_error("Query: $query\n <br />MySQL Error: " . mysql_error()); 


   if (@mysql_num_rows($result) == 1) { // A match was made.
 
      // Register the values & redirect.
       $row = mysql_fetch_array ($result,MYSQL_NUM);
 
      mysql_free_result($result);
       mysql_close();
 
      $_SESSION['first_name'] = $row[1];
       $_SESSION['user_id'] = $row[0];
 
      // Start defining the URL.
       $url = 'http://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']);
       // Check for a trailing slash.
       if ((substr($url, -1) == '/') OR(substr($url, -1) == '\\') ) {
         $url = substr ($url, 0, -1); // Chop off the slash.
       }
       // Add the page.
       $url .= '/index.php';
 
      ob_end_clean(); // Delete the buffer.
       header("Location: $url");
       exit(); // Quit the script. 
       
      } else { // No match was made.
         echo '<p><font color="red"size="+1">Either the email address and password entered do not match those on file or you have not yet activated your account.</font></p>';
       }
 
   } else {
 
      echo '<p><font color="red"size="+1">Please try again.</font></p>';
    }
    mysql_close();
 
} // End of SUBMIT conditional.
 ?>

<h1>Login</h1>
 <p>Your browser must allow cookies in order to log in.</p>
 <form action="login.php"method="post">
    <fieldset>
    <p><b>Email Address:</b> <input type="text" name="email" size="20" maxlength="40" value="<?php if (isset($_POST['email'])) echo $_POST['email']; ?>" /></p>
    <p><b>Password:</b> <input type="password" name="pass" size="20" maxlength="20" /></p>
    <div align="center"><input type="submit" name="submit" value="Login" /></div>
    <input type="hidden" name="submitted" value="TRUE" />
    </fieldset>
 </form>

<?php
 include ('./includes/footer.html');
 ?>


 



