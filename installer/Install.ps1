param([string]$GameDir='E:\Program Files (x86)\Steam\steamapps\common\Desperados Wanted Dead or Alive')
$ErrorActionPreference='Stop'
$packageRoot=$PSScriptRoot
$GameDir=[IO.Path]::GetFullPath($GameDir).TrimEnd('\')
$manifest=Get-Content -LiteralPath (Join-Path $packageRoot 'manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
$receiptPath=Join-Path $packageRoot 'installation.json'
function Hash([string]$File){(Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash}
function Within([string]$Root,[string]$Relative){$prefix=[IO.Path]::GetFullPath($Root).TrimEnd('\')+'\';$full=[IO.Path]::GetFullPath((Join-Path $Root $Relative));if(-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'A resource path leaves its package directory.'};$full}
$gameExe=Join-Path $GameDir 'desperados.exe'
if((Hash $gameExe) -notin @($manifest.executableSha256,$manifest.patchedExecutableSha256)){throw 'This executable does not match the tested Steam build. No game files were changed.'}
function New-CompatExecutable([string]$Source,[string]$Output){
 $patchFile=Join-Path $PSScriptRoot 'renderer-patch.json'
 if((Hash $patchFile) -ne $manifest.rendererPatchSha256){throw 'Renderer patch hash mismatch'}
 $delta=Get-Content -LiteralPath $patchFile -Raw -Encoding UTF8|ConvertFrom-Json
 if((Hash $Source) -ne $delta.originalSha256){throw 'An exact original executable backup is required'}
 $sourceBytes=[IO.File]::ReadAllBytes($Source)
 if($sourceBytes.Length -ne $delta.originalBytes){throw 'Unexpected executable size'}
 $append=[Convert]::FromBase64String($delta.append)
 if($delta.patchedBytes -ne $sourceBytes.Length+$append.Length){throw 'Invalid renderer patch length'}
 $result=New-Object byte[] $delta.patchedBytes
 [Array]::Copy($sourceBytes,0,$result,0,$sourceBytes.Length)
 foreach($edit in $delta.edits){
  $before=[Convert]::FromBase64String($edit.before);$after=[Convert]::FromBase64String($edit.after)
  if($before.Length -ne $after.Length -or $edit.offset -lt 0 -or $edit.offset+$before.Length -gt $sourceBytes.Length){throw 'Invalid renderer patch offset'}
  for($i=0;$i -lt $before.Length;$i++){if($sourceBytes[$edit.offset+$i] -ne $before[$i]){throw 'Renderer patch original bytes mismatch'}}
  [Array]::Copy($after,0,$result,[int]$edit.offset,$after.Length)
 }
 [Array]::Copy($append,0,$result,$sourceBytes.Length,$append.Length)
 [IO.File]::WriteAllBytes($Output,$result)
 if((Hash $Output) -ne $delta.patchedSha256){throw 'Generated executable hash mismatch'}
}

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

$stagingFile=Join-Path $packageRoot ('.renderer-'+[Guid]::NewGuid().ToString('N')+'.tmp')
$payloads=@{}
try{
$receipts=@()
foreach($candidateRoot in @($packageRoot)+@($manifest.legacyPackages|ForEach-Object {Within (Split-Path $packageRoot) $_})){
 $record=Join-Path $candidateRoot 'installation.json'
 if(Test-Path -LiteralPath $record){$candidate=Get-Content -LiteralPath $record -Raw -Encoding UTF8|ConvertFrom-Json;if([IO.Path]::GetFullPath($candidate.gameDir).TrimEnd('\') -eq $GameDir -and $candidate.state -in @('installed','installing','rolled-back','recovery-required')){$receipts+=@{root=$candidateRoot;receipt=$candidate}}}
}
$pending=@();$originals=@{};$before=@{}
foreach($entry in $manifest.files){
 $payload=Within $packageRoot $entry.path;$target=Within $GameDir $entry.path
 if($entry.path -ne 'desperados.exe' -and (Hash $payload) -ne $entry.patchedSha256){throw "Patch verification failed: $($entry.path)"}
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
 if($entry.path -eq 'desperados.exe'){New-CompatExecutable -Source $originals[$entry.path] -Output $stagingFile;$payloads[$entry.path]=$stagingFile}else{$payloads[$entry.path]=$payload}
 if((Hash $payloads[$entry.path]) -ne $entry.patchedSha256){throw 'Payload verification failed'}
 if($current -ne $entry.patchedSha256){$pending+=$entry}
}
if($pending.Count){foreach($process in @(Get-Process -Name desperados -ErrorAction SilentlyContinue)){if($process.Path -eq $gameExe){throw 'Please close the game before installing.'}}}
if(-not $pending.Count -and (Test-Path -LiteralPath $receiptPath)){
 $existing=Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8|ConvertFrom-Json
 if($existing.state -eq 'installed' -and [IO.Path]::GetFullPath($existing.gameDir).TrimEnd('\') -eq $GameDir -and $existing.files.Count -eq $manifest.files.Count){Write-Output 'Font compatibility patch, main game and Demo are already installed; original backups verified.';return}
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
 foreach($entry in $pending){$attempted+=$entry;Put $payloads[$entry.path] (Within $GameDir $entry.path);if((Hash (Within $GameDir $entry.path)) -ne $entry.patchedSha256){throw 'Installed resource verification failed'}}
 $receipt.state='installed';$receipt|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $receiptPath -Encoding UTF8
 Write-Output "Font compatibility patch installed: $($manifest.files.Count) resources verified; $($pending.Count) updated."
 Write-Output 'Select the English/US-UK flag: lower section for the main game, upper section for Demo Mission.'
}catch{
 $failure=$_
 foreach($entry in $attempted){try{$target=Within $GameDir $entry.path;if((Hash $target) -ne $before[$entry.path]){Put (Within $rollbackRoot $entry.path) $target};if((Hash $target) -ne $before[$entry.path]){throw 'Rollback verification failed'}}catch{$rollbackErrors+=$entry.path}}
 $receipt.state=if($rollbackErrors.Count){'recovery-required'}else{'rolled-back'};$receipt|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $receiptPath -Encoding UTF8
 if($rollbackErrors.Count){throw "Installation failed; keep original backups and rollback-staging. Recovery required: $($rollbackErrors -join ', ')"}
 throw $failure
}finally{if(-not $rollbackErrors.Count -and (Test-Path -LiteralPath $rollbackRoot)){if(-not $rollbackRoot.StartsWith([IO.Path]::GetFullPath($packageRoot).TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe rollback staging path'};Remove-Item -LiteralPath $rollbackRoot -Recurse -Force}}

}finally{if(Test-Path -LiteralPath $stagingFile){[IO.File]::Delete($stagingFile)}}
