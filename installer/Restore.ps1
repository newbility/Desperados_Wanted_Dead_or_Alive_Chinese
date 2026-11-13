param()
$ErrorActionPreference='Stop'
function Put([string]$Source,[string]$Target){
 $temp=$Target+'.cnfont-'+[Guid]::NewGuid().ToString('N')
 $previous=$temp+'.previous'
 try{
  [IO.File]::Copy($Source,$temp)
  [IO.File]::Replace($temp,$Target,$previous)
 }finally{
  if(Test-Path -LiteralPath $temp){[IO.File]::Delete($temp)}
  if(Test-Path -LiteralPath $previous){[IO.File]::Delete($previous)}
 }
}

$receiptPath=Join-Path $PSScriptRoot 'installation.json'
$receipt=Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8|ConvertFrom-Json
if($receipt.state -eq 'restored'){Write-Output 'Main game and Demo have already been restored.';return}
if($receipt.state -ne 'installed'){throw 'No completed combined installation is recorded.'}
$backupRoot=Join-Path $PSScriptRoot $receipt.backupRelative
$gameExe=Join-Path $receipt.gameDir 'desperados.exe'
foreach($proc in @(Get-Process -Name desperados -ErrorAction SilentlyContinue)){if($proc.Path -eq $gameExe){throw 'Please close the game before restoring.'}}
foreach($entry in $receipt.files){
 $backup=Join-Path $backupRoot $entry.path
 if((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -ne $entry.originalSha256){throw "Backup verification failed: $($entry.path)"}
 $current=(Get-FileHash -LiteralPath (Join-Path $receipt.gameDir $entry.path) -Algorithm SHA256).Hash
 if($current -ne $entry.patchedSha256 -and $current -ne $entry.originalSha256){throw "Resource was changed after installation. No files were restored: $($entry.path)"}
}
foreach($entry in $receipt.files){
 $target=Join-Path $receipt.gameDir $entry.path
 Put (Join-Path $backupRoot $entry.path) $target
 if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $entry.originalSha256){throw "Restored resource failed verification: $($entry.path)"}
}
$receipt.state='restored'
$receipt|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $receiptPath -Encoding UTF8
Write-Output 'Main game and Demo restored to original resources. The combined backup has been retained.'
