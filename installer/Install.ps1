param([string]$GameDir='E:\Program Files (x86)\Steam\steamapps\common\Desperados Wanted Dead or Alive')
$ErrorActionPreference='Stop'
$packageRoot=$PSScriptRoot
$GameDir=[IO.Path]::GetFullPath($GameDir).TrimEnd('\')
$manifest=Get-Content -LiteralPath (Join-Path $packageRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$receiptPath=Join-Path $packageRoot 'installation.json'
function Hash([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Within([string]$Root,[string]$Relative){
 $prefix=[IO.Path]::GetFullPath($Root).TrimEnd('\')+'\'
 $resolved=[IO.Path]::GetFullPath((Join-Path $Root $Relative))
 if(-not $resolved.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'A resource path leaves its package directory.'}
 return $resolved
}
$gameExe=Join-Path $GameDir 'desperados.exe'
if((Hash $gameExe) -ne $manifest.executableSha256){throw 'This executable does not match the tested Steam build. No game files were changed.'}
$receipts=@()
foreach($candidateRoot in @($packageRoot)+@($manifest.legacyPackages | ForEach-Object {Within (Split-Path $packageRoot) $_})){
 $candidateReceipt=Join-Path $candidateRoot 'installation.json'
 if(Test-Path -LiteralPath $candidateReceipt){
  $candidate=Get-Content -LiteralPath $candidateReceipt -Raw -Encoding UTF8 | ConvertFrom-Json
  if([IO.Path]::GetFullPath($candidate.gameDir).TrimEnd('\') -eq $GameDir -and $candidate.state -in @('installed','installing','rolled-back','recovery-required')){
   $receipts+=@{root=$candidateRoot;receipt=$candidate}
  }
 }
}
$pending=@();$originals=@{}
foreach($entry in $manifest.files){
 $source=Within $packageRoot $entry.path
 $target=Within $GameDir $entry.path
 if((Hash $source) -ne $entry.patchedSha256){throw "Patch verification failed: $($entry.path)"}
 $current=Hash $target
 if($current -eq $entry.originalSha256){$originals[$entry.path]=$target;$pending+=$entry;continue}
 if($current -ne $entry.patchedSha256){throw "Unrecognized game resource. No game files were changed: $($entry.path)"}
 foreach($prior in $receipts){
  $record=@($prior.receipt.files | Where-Object {$_.path -eq $entry.path -and $_.originalSha256 -eq $entry.originalSha256 -and $_.patchedSha256 -eq $entry.patchedSha256})
  if($record.Count -eq 0){continue}
  $backupRoot=Within $prior.root $prior.receipt.backupRelative
  $backup=Within $backupRoot $entry.path
  if((Test-Path -LiteralPath $backup) -and (Hash $backup) -eq $entry.originalSha256){$originals[$entry.path]=$backup;break}
 }
 if(-not $originals.ContainsKey($entry.path)){throw "Original backup is needed for an already translated file: $($entry.path). Keep the earlier patch folders beside this combined package, or restore the earlier patch first."}
}
if($pending.Count -gt 0){foreach($proc in @(Get-Process -Name desperados -ErrorAction SilentlyContinue)){if($proc.Path -eq $gameExe){throw 'Please close the game before installing.'}}}
if($pending.Count -eq 0 -and (Test-Path -LiteralPath $receiptPath)){
 $existing=Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
 if($existing.state -eq 'installed' -and [IO.Path]::GetFullPath($existing.gameDir).TrimEnd('\') -eq $GameDir -and $existing.files.Count -eq $manifest.files.Count){
  $validBackup=$true
  foreach($entry in $manifest.files){$backup=Within (Within $packageRoot $existing.backupRelative) $entry.path;if(-not (Test-Path -LiteralPath $backup) -or (Hash $backup) -ne $entry.originalSha256){$validBackup=$false;break}}
  if($validBackup){Write-Output 'Main game and Demo are already installed; the combined original backup is verified.';return}
 }
}
$backupRelative='backups\'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')
$backupRoot=Within $packageRoot $backupRelative
foreach($entry in $manifest.files){
 $backup=Within $backupRoot $entry.path
 New-Item -ItemType Directory -Path (Split-Path $backup) -Force | Out-Null
 Copy-Item -LiteralPath $originals[$entry.path] -Destination $backup
 if((Hash $backup) -ne $entry.originalSha256){throw "Backup verification failed: $($entry.path)"}
}
$receipt=[ordered]@{gameDir=$GameDir;backupRelative=$backupRelative;state='installing';files=@($manifest.files);installedAt=(Get-Date -Format o);scope=@('main','demo')}
$receipt|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $receiptPath -Encoding UTF8
$attempted=@()
try {
 foreach($entry in $pending){
  $attempted+=$entry
  Copy-Item -LiteralPath (Within $packageRoot $entry.path) -Destination (Within $GameDir $entry.path) -Force
  if((Hash (Within $GameDir $entry.path)) -ne $entry.patchedSha256){throw "Installed resource failed verification: $($entry.path)"}
 }
 $receipt.state='installed'
 $receipt|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $receiptPath -Encoding UTF8
 Write-Output "Main game and Demo verified: $($manifest.files.Count) resources; $($pending.Count) files updated."
 Write-Output "Combined original backup: $backupRoot"
 Write-Output 'Select the English/US-UK flag: lower section for the main game, upper section for Demo Mission.'
} catch {
 $installError=$_;$rollbackErrors=@()
 foreach($entry in $attempted){try{$target=Within $GameDir $entry.path;if((Hash $target) -ne $entry.originalSha256){Copy-Item -LiteralPath (Within $backupRoot $entry.path) -Destination $target -Force};if((Hash $target) -ne $entry.originalSha256){throw 'Rollback verification failed'}}catch{$rollbackErrors+=$entry.path}}
 $receipt.state=if($rollbackErrors.Count){'recovery-required'}else{'rolled-back'}
 $receipt|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $receiptPath -Encoding UTF8
 if($rollbackErrors.Count){throw "Installation failed. Original backups are retained; recovery is needed for: $($rollbackErrors -join ', ')"}
 throw $installError
}
