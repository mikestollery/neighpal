
<?php # activate.php
 // This page activates the user's account.
 
// Include the configuration file for error management and such.
 require_once('./includes/config.inc.php');
 
// Set the page title and include the HTML header.
 $page_title = 'Activate Your Account';
 include ('./includes/header.html');

// Validate $_GET['x'] and $_GET['y'].
 if (isset($_GET['x'])) {
    $x = (int) $_GET['x'];
 } else {
    $x = 0;
 }
 if (isset($_GET['y'])) {
    $y = $_GET['y'];
 } else {
    $y = 0;
 }
 
// If $x and $y aren't correct, redirect the user.
 if ( ($x > 0) && (strlen($y) == 32)) {
 
   require_once ('./includes/mysql_connect.php'); // Connect to the database.
    $query = "UPDATE users SET active= NULL WHERE (user_id=$x AND
    active='" . escape_data($y) . "')LIMIT 1";
    $result = mysql_query ($query) or trigger_error("Query: $query\n
    <br />MySQL Error: " . mysql_error());

   // Print a customized message.
    if (mysql_affected_rows() == 1) {
       echo "<h3>Your account is now active. You may now log in.</h3>";
    } else {
       echo '<p><font color="red"size="+1">Your account could not
       be activated. Please re-check the link or contact the system
       administrator.</font></p>';
    }

   mysql_close();
 
} else { // Redirect.
 
   // Start defining the URL.
    $url = 'http://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER
    ['PHP_SELF']);
    // Check for a trailing slash.
    if ((substr($url, -1) == '/') OR (substr($url, -1) == '\\') ) {
         $url = substr ($url, 0, -1); // Chop off the slash.
    }
    // Add the page.
    $url .= '/index.php';
 
   ob_end_clean(); // Delete the buffer.
    header("Location: $url");
    exit(); // Quit the script.
 
} // End of main IF-ELSE. 

include ('./includes/footer.html');
 ?> 
 
