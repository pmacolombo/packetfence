<?php
$current_top="scan";
$current_sub="scan";

require_once('../common.php');


function print_time_options() {
  for ($i=0; $i<=23;$i++) {
    for ($ii=0; $ii<=50; $ii+=10) {
      printf ("                <option value=\"%d:%d\">%02d:%02d</option>\n", $i, $ii, $i, $ii); 
    }
  }
}

$my_table=new table("schedule view all");
$my_table->set_editable(true);

if (isset($page_num)) {
  $my_table->set_page_num($page_num);
}
if (isset($per_page)) {
  $my_table->set_per_page($per_page);
}

include_once('../header.php');

$scan_table=new table("trigger view all scan");

foreach($scan_table->rows as $row){
  $vulns_ar[]=array('tid' => $row['tid_start'], 'desc' => $row['description']);
}
$_SESSION['vulns']=serialize($vulns_ar);


if(isset($_REQUEST[action]) && $_REQUEST[action]=='add'){
  ## HOSTS ##
  if(isset($_POST[host])) {
    #if (preg_match("/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}([-\/]\d+)?$/", $host)) {
    if (preg_match("/^(?:\d{1,3}\.){3}\d{1,3}([-\/]\d+)?$/", $_POST[host])) {
      $valid_hosts = $_POST[host];
    } else {
      $invalid_hosts = $_POST[host];
    }
  } else {
    $no_hosts=true;
  }

  ## VULNS ##
  $all_on=true;
  foreach($vulns_ar as $vuln){   
    if($_POST['tid' . $vuln['tid']]=="on")
      $tids[]=$vuln['tid'];
    else
      $all_on=false;
  }

  $tids=join(";", $tids);

  ## TIME ##
  if($_POST[scan_freq]=="now") 
    $date="now";
  else{
    if($_POST[daily]){
      $time_ar=explode(":", $_POST[daily]);
      $date=$time_ar[1]." ".$time_ar[0]." * * *";
    } 
    if($_POST[weekly]){
      if($_POST[weekly_time])
        $time_ar=explode(":", $_POST[weekly_time]);
      else
        $time_ar[0]=$time_ar[1]=0;
      $date=$time_ar[1]." ".$time_ar[0]." * * ".$_POST[weekly];
    }
    if($_POST[monthly]){
      if($_POST[monthly_time])
        $time_ar=explode(":", $_POST[monthly_time]);
      else
        $time_ar[0]=$time_ar[1]=0;
      $date=$time_ar[1]." ".$time_ar[0]." ".$_POST[monthly]." * *";;
    }
  }

  if(!$tids)
    $errors[]="No vulnerabilities have been selected<br>";
  if(!$date)
    $errors[]="No scan time has been selected<br>";
  if(isset($no_hosts))
    $errors[]="You have not specified any hosts to scan<br>";
  if(isset($invalid_hosts))
    $errors[]="The following host(s) are not written in the correct format: $invalid_hosts";

  if($errors){
    print "<font color=\"red\">There are errors in your schedule:<br><blockquote>";
    foreach($errors as $error)
      print $error;
    print "</blockquote></font>";
  }
  else{
    if($date=="now") {
      PFCMD("schedule now $valid_hosts tid=$tids");
    } else {
      PFCMD("schedule add $valid_hosts date=\"$date\",tid=$tids");
    }
    $my_table->refresh();
  }
}
?>

<div id="history">
<table class="main">
<tr>
  <td>
<form name=schedule action='scan/scan.php?action=add' method=POST>
  <table>
    <tr>
      <td colspan=8>Add a Scan Schedule</td>
    </tr>
    <tr class=title>
      <td><br><b><u>Host/Range</u></b></td>
    </tr>
    <tr>
      <td></td><td><input type=text size=20 name=host></td> 
    </tr>
    <tr class=title>
      <td><br><b><u>Scan For</u></b></td>
    </tr>
    <tr>
      <td></td>
      <td>
        <table>
          <?
	    for($i=0; $i<count($vulns_ar); $i++){
	      if($i % 3 == 0) {
                if ($i!=0 ) {
                  print "</tr>";
                }
                print "<tr>";
              }
              echo "        <td><input type=\"checkbox\" name=\"tid{$vulns_ar[$i]['tid']}\" checked>";
              echo "{$vulns_ar[$i]['desc']} (";
              echo "<a href=\"http://www.nessus.org/plugins/index.php?view=single&id={$vulns_ar[$i]['tid']}\" target=\"_blank\">";
              echo "{$vulns_ar[$i]['tid']}</a>)</td>\n";
	    }
          ?>
        </table>
      </td>
    </tr>
    <tr class=title>
      <td><br><b><u>Schedule</u></b></td>
    </tr>
    <tr>
      <td></td>
      <td>
        <table>
	  <tr>
            <td><input type=radio name=scan_freq value=now checked></td>
	    <td colspan=2>Scan Now</td>
          </tr>
	  <tr>
            <td><input type=radio name=scan_freq value=schedule></td>
	    <td colspan=2>Repeating Schedule</td>
          </tr>
          <tr class=title>
            <td></td><td></td><td>Time</td>
          </tr>
          <tr>
  	    <td></td>
	    <td>Daily</td>
	    <td>
              <select name="daily" onclick="document.schedule.scan_freq[1].checked=true">
                <option value="">---------</option>
<?php print_time_options() ?>
              </select>
            </td>
 	  </tr>    
          <tr class=title>
            <td></td><td></td><td>Day</td><td>Time</td>
          </tr>
          <tr>
  	    <td></td>
	    <td>Weekly</td>
	    <td>
              <select name=weekly onclick="document.schedule.scan_freq[1].checked=true">
                <option value="">---------</option>   
		<option value=7>Sun.</option>
		<option value=1>Mon.</option>
		<option value=2>Tue.</option>
		<option value=3>Wed.</option>
		<option value=4>Thu.</option>
		<option value=5>Fri.</option>
		<option value=6>Sat.</option>
              </select>
	    </td>
	    <td>
              <select name="weekly_time" onclick="document.schedule.scan_freq[1].checked=true">
                <option value="">---------</option>
<?php print_time_options() ?>
              </select>
            </td>
 	  </tr>    
          <tr class=title>
            <td></td><td></td><td>Date</td><td>Time</td>
          </tr>
          <tr>
  	    <td></td>
	    <td>Monthly</td>
	    <td>
              <select name=monthly onclick="document.schedule.scan_freq[1].checked=true">
                <option value="">---------</option>       
<?php
for ($i=1; $i<=28; $i++) {
  echo "                <option value=\"$i\">$i</option>\n";
}
?>
              </select>
	    </td>
 	    <td>
              <select name="monthly_time" onclick="document.schedule.scan_freq[1].checked=true">
                <option value="">---------</option>
		  <?php print_time_options() ?>
              </select>
            </td>
 	  </tr>    
        </table>
      </td>
    </tr>
    <tr>
      <td colspan=8 align=right><input type=submit value="Add Schedule"></td>
    </tr>
  </table>
</form>
</td>
<td valign=top class=contents width=100%>
  <table width=100%>
    <tr>
      <td>Current Schedules</td>
    </tr>
    <tr>
      <td>
        <? 	  $my_table->tableprint(false); 	?>
      </td>
    </tr>
  </table>
</td></tr>
</table>
</div>
<?
include_once('../footer.php');
?>
