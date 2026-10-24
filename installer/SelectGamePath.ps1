param([string]$GameDir)
$ErrorActionPreference='Stop'
$installer=Join-Path $PSScriptRoot 'Install.ps1'
if($PSBoundParameters.ContainsKey('GameDir')){
 & $installer -GameDir $GameDir
 return
}
Add-Type -AssemblyName System.Windows.Forms
[Windows.Forms.Application]::EnableVisualStyles()
$dialog=New-Object Windows.Forms.FolderBrowserDialog
$dialog.Description='请选择包含 desperados.exe 的游戏文件夹，然后点击“确定”。'
$dialog.RootFolder=[Environment+SpecialFolder]::MyComputer
$dialog.ShowNewFolderButton=$false
$initial='E:\Program Files (x86)\Steam\steamapps\common\Desperados Wanted Dead or Alive'
$receiptPath=Join-Path $PSScriptRoot 'installation.json'
if(Test-Path -LiteralPath $receiptPath){
 try{$prior=Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8|ConvertFrom-Json;if(Test-Path -LiteralPath $prior.gameDir -PathType Container){$initial=$prior.gameDir}}catch{}
}
if(Test-Path -LiteralPath $initial -PathType Container){$dialog.SelectedPath=$initial}
try {
 while($true){
  if($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK){Write-Output 'Installation cancelled. No game files were changed.';return}
  $selected=$dialog.SelectedPath
  if(-not (Test-Path -LiteralPath (Join-Path $selected 'desperados.exe') -PathType Leaf)){
   [void][Windows.Forms.MessageBox]::Show('所选文件夹里没有 desperados.exe。请选择游戏根目录，而不是 Steam 目录或 data 子目录。','请选择游戏目录',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)
   continue
  }
  break
 }
 try {
  & $installer -GameDir $selected
  [void][Windows.Forms.MessageBox]::Show("主游戏和 Demo 汉化安装或校验已完成。`r`n`r`n游戏路径：$selected`r`n`r`n从 Steam 启动后，选择对应区域的英美旗帜即可。",'汉化完成',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information)
 } catch {
  [void][Windows.Forms.MessageBox]::Show("汉化安装未完成。`r`n`r`n$($_.Exception.Message)",'安装未完成',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error)
  throw
 }
} finally {$dialog.Dispose()}
