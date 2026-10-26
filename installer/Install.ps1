param([string]$GameDir='E:\Program Files (x86)\Steam\steamapps\common\Desperados Wanted Dead or Alive')
$ErrorActionPreference='Stop'
$packageRoot=$PSScriptRoot
$GameDir=[IO.Path]::GetFullPath($GameDir).TrimEnd('\')
$manifest=Get-Content -LiteralPath (Join-Path $packageRoot 'manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
$receiptPath=Join-Path $packageRoot 'installation.json'
function Hash([string]$File){(Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash}
function Within([string]$Root,[string]$Relative){$prefix=[IO.Path]::GetFullPath($Root).TrimEnd('\')+'\';$full=[IO.Path]::GetFullPath((Join-Path $Root $Relative));if(-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'A resource path leaves its package directory.'};$full}
$gameExe=Join-Path $GameDir 'desperados.exe'
if((Hash $gameExe) -ne $manifest.executableSha256){throw 'This executable does not match the tested Steam build. No game files were changed.'}
$receipts=@()
foreach($candidateRoot in @($packageRoot)+@($manifest.legacyPackages|ForEach-Object {Within (Split-Path $packageRoot) $_})){
 $record=Join-Path $candidateRoot 'installation.json'
 if(Test-Path -LiteralPath $record){$candidate=Get-Content -LiteralPath $record -Raw -Encoding UTF8|ConvertFrom-Json;if([IO.Path]::GetFullPath($candidate.gameDir).TrimEnd('\') -eq $GameDir -and $candidate.state -in @('installed','installing','rolled-back','recovery-required')){$receipts+=@{root=$candidateRoot;receipt=$candidate}}}
}
$pending=@();$originals=@{};$before=@{}
foreach($entry in $manifest.files){
 $payload=Within $packageRoot $entry.path;$target=Within $GameDir $entry.path
 if((Hash $payload) -ne $entry.patchedSha256){throw "Patch verification failed: $($entry.path)"}
 $current=Hash $target;$before[$entry.path]=$current
 if($current -eq $entry.originalSha256){$originals[$entry.path]=$target}
 elseif($current -eq $entry.patchedSha256 -or $current -in @($entry.upgradeSha256)){
  foreach($prior in $receipts){
   $records=@($prior.receipt.files|Where-Object {$_.path -eq $entry.path -and $_.originalSha256 -eq $entry.originalSha256})
   if(-not $records.Count){continue}
   $backup=Within (Within $prior.root $prior.receipt.backupRelative) $entry.path
   if((Test-Path -LiteralPath $backup) -and (Hash $backup) -eq $entry.originalSha256){$originals[$entry.path]=$backup;break}
  }
  if(-not $originals.ContainsKey($entry.path)){throw "Original backup is needed: $($entry.path). Keep the earlier patch folders beside this package, or restore the earlier patch first."}
 }else{throw "Unrecognized game resource. No game files were changed: $($entry.path)"}
 if($current -ne $entry.patchedSha256){$pending+=$entry}
}
if($pending.Count){foreach($process in @(Get-Process -Name desperados -ErrorAction SilentlyContinue)){if($process.Path -eq $gameExe){throw 'Please close the game before installing.'}}}
if(-not $pending.Count -and (Test-Path -LiteralPath $receiptPath)){
 $existing=Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8|ConvertFrom-Json
 if($existing.state -eq 'installed' -and [IO.Path]::GetFullPath($existing.gameDir).TrimEnd('\') -eq $GameDir -and $existing.files.Count -eq $manifest.files.Count){Write-Output 'Clear fonts, main game and Demo are already installed; original backups verified.';return}
}
$stamp=(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$backupRelative='backups\'+$stamp;$backupRoot=Within $packageRoot $backupRelative
foreach($entry in $manifest.files){$backup=Within $backupRoot $entry.path;New-Item -ItemType Directory -Path (Split-Path $backup) -Force|Out-Null;Copy-Item -LiteralPath $originals[$entry.path] -Destination $backup;if((Hash $backup) -ne $entry.originalSha256){throw 'Original backup verification failed'}}
$rollbackRelative='rollback-staging\'+$stamp;$rollbackRoot=Within $packageRoot $rollbackRelative
foreach($entry in $pending){$snapshot=Within $rollbackRoot $entry.path;New-Item -ItemType Directory -Path (Split-Path $snapshot) -Force|Out-Null;Copy-Item -LiteralPath (Within $GameDir $entry.path) -Destination $snapshot;if((Hash $snapshot) -ne $before[$entry.path]){throw 'Game resource changed during backup'}}
$receipt=[ordered]@{gameDir=$GameDir;backupRelative=$backupRelative;state='installing';files=@($manifest.files);installedAt=(Get-Date -Format o);scope=@('main','demo');packageVersion=$manifest.packageVersion;rollbackRelative=$rollbackRelative}
$receipt|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $receiptPath -Encoding UTF8
$attempted=@();$rollbackErrors=@()
try{
 foreach($entry in $pending){$attempted+=$entry;Copy-Item -LiteralPath (Within $packageRoot $entry.path) -Destination (Within $GameDir $entry.path) -Force;if((Hash (Within $GameDir $entry.path)) -ne $entry.patchedSha256){throw 'Installed resource verification failed'}}
 $receipt.state='installed';$receipt|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $receiptPath -Encoding UTF8
 Write-Output "Clear fonts installed: $($manifest.files.Count) resources verified; $($pending.Count) updated."
 Write-Output 'Select the English/US-UK flag: lower section for the main game, upper section for Demo Mission.'
}catch{
 $failure=$_
 foreach($entry in $attempted){try{$target=Within $GameDir $entry.path;if((Hash $target) -ne $before[$entry.path]){Copy-Item -LiteralPath (Within $rollbackRoot $entry.path) -Destination $target -Force};if((Hash $target) -ne $before[$entry.path]){throw 'Rollback verification failed'}}catch{$rollbackErrors+=$entry.path}}
 $receipt.state=if($rollbackErrors.Count){'recovery-required'}else{'rolled-back'};$receipt|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $receiptPath -Encoding UTF8
 if($rollbackErrors.Count){throw "Installation failed; keep original backups and rollback-staging. Recovery required: $($rollbackErrors -join ', ')"}
 throw $failure
}finally{if(-not $rollbackErrors.Count -and (Test-Path -LiteralPath $rollbackRoot)){if(-not $rollbackRoot.StartsWith([IO.Path]::GetFullPath($packageRoot).TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe rollback staging path'};Remove-Item -LiteralPath $rollbackRoot -Recurse -Force}}
