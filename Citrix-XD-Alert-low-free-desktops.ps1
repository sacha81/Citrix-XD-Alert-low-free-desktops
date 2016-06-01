#==============================================================================================
# Created on: 03.2016            Version: 1.0
# Created by: Sacha Thomet
# File name: Citrix-XD-Alert-low-free-desktops.ps1
#
# Description: Check for Free Desktops in DeliveryGroups 
#
# Prerequisite: This script need to run on a Desktop Controller
#
# Call by : Scheduled Task (e.g. every 10 minutes)
#
# Changelog: 
#	V0.1 Initial Version, create report file from array FreeDesktopReport and attach this to the email.  
#	V0.2 Change from txt-file to formatted HTML-Mail 
#	V1.0 Minor corrections 
#
#==============================================================================================
if ((Get-PSSnapin "Citrix.Common.Commands" -EA silentlycontinue) -eq $null) {
try { Add-PSSnapin Citrix.* -ErrorAction Stop }
catch { write-error "Error Citrix.* Powershell snapin"; Return }
}
# Change the below variables to suit your environment
#==============================================================================================
 
# Variables  should be changed according your environment

$DeliveryGroups = @("Win7","Win10")
$minDesktops = 10
$directoraddress="http://citrixdirector.yourcompany.com"
$EnvironmentName="Production XD 7.8"

# E-mail report details
$emailFrom = "citrix@yourcompany.com"
$emailTo = "citrix@yourcompany.com"#,"sacha.thomet@yourcompany.com"
$smtpServer    = "smtp.yourcompany.com"

#=======DONT CHANGE BELOW HERE =======================================================================================

$mailbody = $mailbody + "<!DOCTYPE html>"
$mailbody = $mailbody + "<html>"

$mailbody = $mailbody + "<head>"
$mailbody = $mailbody + "<style>"
$mailbody = $mailbody + "BODY{background-color:#fbfbfb; font-family: Arial;}"
$mailbody = $mailbody + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; width:60%; }"
$mailbody = $mailbody + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black; text-align:left;}"
$mailbody = $mailbody + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;}"
$mailbody = $mailbody + "</style>"
$mailbody = $mailbody + "</head>"

$mailbody = $mailbody + "<body>"
$mailbody = $mailbody + "This is the Low-Desktop-Alert for $EnvironmentName, if you receive this mail the value of free desktops is below the configured threshold of $minDesktops desktops! <br><br>" 

$FreeDesktopReport = @() 
 
foreach($dg in $DeliveryGroups)
{
	$desktops = Get-BrokerDesktopGroup | where {$_.Name -eq $dg }
	$CurrentDeliveryGroup = "" | Select-Object Name, Alert, DesktopsAvailable
	
	# Write Array Values
	$CurrentDeliveryGroup.Name = $dg
		
	$CurrentDeliveryGroup.DesktopsAvailable = $desktops.DesktopsAvailable
	
	if ($desktops.DesktopsAvailable -lt $minDesktops ) 
	{
		Write-Host "Number of free desktops to low for DeliveryGroup $dg, sending email"
		# Add Line to Report 
		$CurrentDeliveryGroup.alert = "True"
	}
	
	$FreeDesktopReport += $CurrentDeliveryGroup
}

$mailbody += $FreeDesktopReport | ConvertTo-Html
$mailbody += "<br><br>Launch Citrix Studio or browse to <a href=$directoraddress>Citrix Director</a> see more information about the current Desktop usage<br>" 

$mailbody = $mailbody + "<body>"
$mailbody = $mailbody + "</html>"
 
# If any record raises an alert, send an email.
if (($FreeDesktopReport | where {$_.alert -eq "True"}) -ne $null) {Send-MailMessage -to $emailTo -from $emailFrom -subject "********* Low free Desktop Alert for $EnvironmentName *********" -Body $mailbody -BodyAsHtml -SmtpServer $smtpServer }
	
