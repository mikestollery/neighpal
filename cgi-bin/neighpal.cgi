#!/usr/bin/perl
#!/usr/local/bin/perl
############################################################
# neighpal.cgi
#
# Top level cgi script for 'neighpal'.
#
############################################################
# Initialisation

unshift @INC, ".";
#unshift @INC, "/Users/mike/web_home/stol.uk/neighpal/cgi-bin";
unshift @INC, "$ENV{DOCUMENT_ROOT}/neighpal/cgi-bin";

require "uber/uber_main.pl";

$SCRIPT_TITLE = "Neighpal";
$ADMIN_EMAIL  = "mike2sheds\@gmail.com"; 
#$SSO = 1;       # Single Sign On
@CSS_LIST = ("neighpal.css", "basic_stuff.css");

uber_main("uber_utils",
          "uber_login",
          "uber_admin",
          "uber_polls");


print $cgi->header(-cookie => [@COOKIE_LIST]);

############################################################

# Filenames
$BannerImgFile = "banner.jpg";       # .../images/neighpal
$LabelsFile    = "labels.dat";       # .../users/neighpal/<username>/static/
$BookiesFile   = "bookies.dat";      # .../users/neighpal/<username>/static/
$RaceIndexFile = "race_index.dat";   # .../users/neighpal/<username>/static/


    $BannerImgFile = "banner_for_rbs.gif";

$RACESROOT = "";
$STATICROOT = "";

# Other globals
@BetList = (); # array of hashes for storing bet records
$Calcs = {};
$Param = {};
$Labels = {};
@BookieList = ();
@RaceIndexList = ();
@StatusList = ("Active", "Confirmed", "Inactive", "Deleted");

require "lib/neighpal_funcs.pl";
require "lib/neighpal_html.pl";

main();

exit(0);

############################################################
#
# Neighpal directory structure
#
# htdocs                       $DATAROOT
#  |
#  |__ css                     $CSSROOT      neighpal.css
#  |    
#  |__ ref                        
#  |    |
#  |    |__ neighpal           $REFROOT      faq.html
#  |
#  |__ images
#  |    |
#  |    |__ neighpal           $IMGROOT
#  |  
#  |__ logs
#  |    |
#  |    |__ neighpal           $LOGROOT
#  |
#  |__ users
#       |
#       |__ neighpal           $USERROOT
#            |
#            |__ mike          $USERDIR       login files
#            |    |
#            |    |__ races                   race data files
#            |    |
#            |    |__ static                  static data files
#            |
#            |__ more users...
#            |
#            |__
#            |
#
#
#
############################################################
# EOF
