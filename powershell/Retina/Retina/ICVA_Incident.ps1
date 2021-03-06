$homedir = "E:\Retina Metrics"
cd $homedir

$lastcsv = ls -recurse -include IAVBreakout* | select LastWriteTime, FullName | sort LastWriteTime -descending | select -expand FullName | select -index 0
$prevcsv = ls -recurse -include IAVBreakout* | select LastWriteTime, FullName | sort LastWriteTime -descending | select -expand FullName | select -index 1
$lastcsvimport = import-csv $lastcsv
$prevcsvimport = import-csv $prevcsv
$wslastcsvunder = $lastcsvimport | select ICVA, @{name="percent"; expression={[INT]$_.'WS Percent'}} | where-object {$_.percent -lt 95} | select ICVA, percent
$wsprevcsvover = $prevcsvimport | select ICVA, @{name="percent"; expression={[INT]$_.'WS Percent'}} | where-object {$_.percent -ge 95} | select ICVA, percent
$srvlastcsvunder = $lastcsvimport | select ICVA, @{name="percent"; expression={[INT]$_.'SRV Percent'}} | where-object {$_.percent -lt 100} | select ICVA, percent
$srvprevcsvover = $prevcsvimport | select ICVA, @{name="percent"; expression={[INT]$_.'SRV Percent'}} | where-object {$_.percent -eq 100} | select ICVA, percent

#Generate WS Stats
$wslastcsvicva = $wslastcsvunder | select -expand ICVA

$wsICVAIncident = @(foreach ($wslastcsvicvas in $wslastcsvicva) {
    $wsprevcsvover | where-object {$_.ICVA -eq $wslastcsvicvas} | select -expand ICVA
        })

$wsICVAChange = @(foreach ($wsICVAIncidents in $wsICVAIncident) {
    $lastcsvimport | where-object {$_.ICVA -eq $wsICVAIncidents} | select -expand 'WS Percent'
    })
    
#Generate SRV Stats
$srvlastcsvicva = $srvlastcsvunder | select -expand ICVA

$srvICVAIncident = @(foreach ($srvlastcsvicvas in $srvlastcsvicva) {
    $srvprevcsvover | where-object {$_.ICVA -eq $srvlastcsvicvas} | select -expand ICVA
        })

$srvICVAChange = @(foreach ($srvICVAIncidents in $srvICVAIncident) {
    $lastcsvimport | where-object {$_.ICVA -eq $srvICVAIncidents} | select -expand 'SRV Percent'
    })
    
 #Top 10 WS ICVA Table Creation
$wstableName = "ICVA WS Droppage"

$wsICVAtable = new-object system.data.datatable $wstableName

$wscol1 = New-object system.data.datacolumn ICVA,([string])
$wscol2 = New-object system.data.datacolumn Percent,([string])

$wsICVAtable.columns.add($wscol1)
$wsICVAtable.columns.add($wscol2)

#Top 10 SRV ICVA Table Creation
$srvtableName = "ICVA WS Droppage"

$srvICVAtable = new-object system.data.datatable $srvtableName

$srvcol1 = New-object system.data.datacolumn ICVA,([string])
$srvcol2 = New-object system.data.datacolumn Percent,([string])

$srvICVAtable.columns.add($srvcol1)
$srvICVAtable.columns.add($srvcol2)

#Add WS ICVA Top 10 Info to table
$counter = 0
foreach ($wsICVAIncidents in $wsICVAIncident){
    $wsrow = $wsICVAtable.newrow()
    $wsrow.ICVA = $wsICVAIncident[$counter]
    $wsrow.Percent = $wsICVAChange[$counter]
    $wsICVAtable.rows.add($wsrow)
    $counter++
}

#Add SRV ICVA Top 10 Info to table
$counter = 0
foreach ($srvICVAIncidents in $srvICVAIncident){
    $srvrow = $srvICVAtable.newrow()
    $srvrow.ICVA = $srvICVAIncident[$counter]
    $srvrow.Percent = $srvICVAChange[$counter]
    $srvICVAtable.rows.add($srvrow)
    $counter++
}

echo "Below are Workstations that dropped below 95%" >> $homedir/MetricReports/ICVA_Incident.txt
$wsICVAtable | ft -autosize >> $homedir/MetricReports/ICVA_Incident.txt
echo "Below are Servers that dropped below 100%" >> $homedir/MetricReports/ICVA_Incident.txt
$srvICVAtable | ft -autosize >> $homedir/MetricReports/ICVA_Incident.txt
$emailattachment = 'E:\Retina Metrics\MetricReports\ICVA_Incident.txt'

function sendmail{
$smtpserver = "EURAMSCASC001J.USAFE.AF.EUCOM.IC.GOV"
$msg = new-object net.mail.mailmessage
$smtp = new-object net.mail.smtpclient($smtpserver)

$msg.from = "issc.security@ntmail.af.eucom.ic.gov"
$msg.replyto = "fezabsa@ntmail.af.eucom.ic.gov"
$msg.to.add("issc.security@ntmail.af.eucom.ic.gov")
$msg.subject = "ICVA Incidents"
$msg.body = 'View attachment to see ICVAs that dropped below 95% for WS or 100% for SRVs.  Open a Remedy incident if necessary.'
$attachment= New-Object System.Net.Mail.Attachment($emailattachment, 'text/plain')
$msg.attachments.add($attachment)
$smtp.send($msg)
}

sendmail
