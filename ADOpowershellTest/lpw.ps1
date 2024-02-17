# if("$(BUILD.TYPE)" -notlike "Build")
# {
#    Write-Host "請將CD Pipeline的成品設定中, Build(CI)設定為主要成品"
# }

# cd $(System.DefaultWorkingDirectory)\$(RELEASE.PRIMARYARTIFACTSOURCEALIAS)\$(PipelineName)

#此範例: 將\SQL(含)底下的所有檔案複製到\\10.11.148.4\d$\Changeversion\LineBcRobot

$Destination = '\\10.11.148.4\d$\Changeversion\LineBcRobot'
# \\10.11.6.54\Changeversion\LineBcRobot

Write-Host $Destination
if([string]::IsNullOrEmpty($Destination) -or ($Destination -like '$*' -and $Destination -like '*)') )
{
   Write-Host "佈署路徑參數異常!!"
   echo "##vso[task.complete result=Failed;]Done"
   exit
}

$singleLineInput = $Destination
$multiLine = $singleLineInput.Split(";")

ForEach ($Dest in $multiLine) {
   $Dest="$Dest".Trim()
   Write-Host $Dest
   if([string]::IsNullOrEmpty($Dest) -or (($Dest).Length -eq 0)){
      Write-Host "佈署路徑為空, 故略過"
      break
   }

   if(($Dest -notlike '*$') -and (-not (Test-Path $Dest))){
      Write-Host "正在建立佈署目的資料夾"
      Write-Host "New-Item -type directory -force $Dest"
      try{
         New-Item -type directory -force "$Dest" -ErrorAction Stop
      }
      catch{
         Write-Host  $Dest "資料夾建立失敗: " $_.Exception.Message
         echo "##vso[task.complete result=Failed;]Done"
         exit
      }

      $testPathResult = Test-Path $Dest
      Write-Host "Test Path: $testPathResult "

      if (!$testPathResult)
      {
         Write-Host "資料夾建立失敗!  請檢查網路或權限是否已開通"
         echo "##vso[task.complete result=Failed;]Done"
         exit
      }
   }

   
    # 20230627\SIN_20230626_1.sql
    # 20230627\SIN_20230626_2.sql

   ForEach ($item in (Get-Content uat-reconcile.txt -Encoding ASCII)) {
     $item="$item".Trim().Replace("[", "``[").Replace("]", "``]")
     Write-Host "item = "$item

     #SQL佈署
     if ((![string]::IsNullOrWhitespace($item)) -and ("$item" -like "SQL\*")) {

       $filename="$item".Split("\")[-1]
       $filenamePosition = "$item".LastIndexOf($filename)
       $folderpath = "$item".Substring(0, $filenamePosition)
       $folderlist="$folderpath".Split("\")
       $folderlen=$folderlist.GetUpperBound(0)
       
       if ($folderlen -eq 0) {
         Write-Host "Copy-Item -Path "$item" -Force -Destination ($Dest)"
         Copy-Item -Path "$item" -Force -Destination ($Dest)
       }
       elseif ($folderlen -ge 1){
         Write-Host "Copy-Item -Path "$item" -Recurse -Force -Filter "$filename" -Destination (New-Item -type directory -force "$Dest\$folderpath")"
         Copy-Item -Path "$item" -Recurse -Force -Filter "$filename" -Destination (New-Item -type directory -force "$Dest\$folderpath")
       }

     }
   }
}
