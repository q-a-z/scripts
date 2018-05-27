$files = @(ls c:\windows\system32 | where-object {$_.Name -like "*.exe"} | select -expand FullName); $files += @(ls c:\windows\syswow64 | where-object {$_.Name -like "*
.exe"} | select -expand FullName); $files += @(ls c:\windows | where-object {$_.Name -like "*.exe"} | select -expand FullName); get-filehash $files | select Hash, Path