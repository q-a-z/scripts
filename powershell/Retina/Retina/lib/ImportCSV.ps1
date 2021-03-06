$homedir = "E:\Retina Metrics"

# MESSAGE BOX FOR FILE SELECTION
Function MsgBox {
$msg = new-object -comobject wscript.shell
$message = $msg.popup("Select the latest Retina CSV File",0,"Retain Reports Generation",1)
if ($message -gt 1) {exit} else {echo "Well...what are you waiting for???"}
}

Function Get-FileName($initialDirectory)
{
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$openFileDialog.filter = "All files (*.*)| *.*"
$OpenFileDialog.ShowDialog() | Out-Null
$OpenFileDialog.filename
} #end function get filename

if (!$Data) {MsgBox; $csv = Get-Filename -initialDirectory "$homedir\RetinaRAWData"}

if ($Data.Length -gt 500) {write-host "Imported" $csv} else {$Data=import-csv "$csv"}
$Data = $data | where-object {($_.IAV -like "*-A-*") -or ($_.IAV -eq 'N/A' -and $_.Name -notmatch "Zero-Day" -and $_.FixInformation -notmatch "patch" -and $_.FixInformation -notmatch "version")}

#Remove any Excluded or Waivered IAV
$Exclude = @(gc "$homedir\Scripts\lib\IAVExclusions.txt"); $Exclude = foreach ($i in $Exclude) {$i.split(" ")[0]}
$Data =  $Data | where-object {$Exclude -notcontains $_.IAV}
