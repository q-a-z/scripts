# $Data | where-object {$_.OS -notmatch '^Windows.*' -and $_.OS -notmatch '^Microsoft.*'}
$pmolist = @(gc 'E:\Retina Metrics\Scripts\lib\pmolist.txt')
$Data | where-object {$pmolist -notcontains $_.IP} | where-object {$_.OS -notmatch '^Windows.*' -and $_.OS -notmatch '^Microsoft.*'}