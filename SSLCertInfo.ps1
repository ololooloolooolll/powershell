# SSL Certificate Smoke Tester
# Gather information from https certificates

$fqdn=@()
$ip="IP_ADDRESS"

# Use a file that contains domains
$fqdn=Get-Content -Path "C:\Users\tmp\domains.txt"

$entries=@{}
foreach ($site in $sites){
$entries.add($site,$ip)
}

function setEntries([hashtable] $entries){
  $hostfile="C:\Users\tmp\hosts.txt"
  $newlines=@()
  
  
  $c=Get-Content -Path $hostfile
  foreach($line in $c){
    $bits=[regex]::Split($line, "\s+")
    if ($bits.count -eq 2){
      $match=$NULL
      foreach($entry in $entries.GetEnumarator()){
      if($bits[1] -eq $entry.Key){
      $newLines += ($entry.Value + '    ' + $entry.Key)
      $match=$entry.Key
      break
      }
    }
    if($match -eq $NULL){
      $newlines+=$line
    } else{
      $entries.Remove($match)
      }
  } else {
    $newlines+=$line
  }
}

foreach($entry in entries.GetEnumerator()){
$newlines+=$entry.Value + '    ' + $entry.Key
}

  Clear-Content $hostfile
  foreach($line in $newlines){
  $line | Out-File -encoding ASCII -append $hostfile
  }
}  

function gatherInfo{
  foreach($site in $sites){
  $port=443
  Write-Host "Connecting to $site"
  [Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
  $req=[Net.HTTPWebRequest]::Create("https://$site`:$port/")
  req.Timeout=3000
  try{$req.GetResponse()|Out-Null}catch{
  write-error "Could not connect to $site on $port"
  continue}
  if(!($req.ServicePoint.Certificate)){
  write-error "No certificate returned on $site"
  continue}
  $certinfo=req.ServicePoint.Certificate
  $hostobj=New-Object PSCustomObject -Property@{
    ComputerName=$site;
    #Port=$port;
    Subject=$certinfo.Subject;
    #Thumbprint=$certinfo.GetCertHashString();
    Issuer=$certinfo.Issuer;
    $SerialNumber=$certinfo.GetSerialNumberString();
    #Issued=[DateTime]$certinfo.GetEffectiveDateString();
    Expires=[DateTime]$certinfo.GetExpirationDateString();
  }
 # Output is not so great
 ($hostobj|ConvertTo-Csb -Delimiter ':' -NoTypeInformation)|Out-File -Append "C:\Users\tmp\output.csv"
 Write-Host "$site added to output" -foreground "cyan"
 }
}

# Console Output processing
Write-Host "Running certificate info checker" -foregroundcolor "green"
Write-Host "Creating host file from fqdn list" -foregroundcolor "green"
Copy-Item C:\Users\tmp\hosts.txt "C:\Users\tmp\hosts.txt.$(get-date -f yyyyMMdd)" -Force
setEntries($entries)
Write-Host "Host file generated" -foregroundcolor "green"
Write-Host "Retrieving certificate information. Please wait." -foregroundcolor "green"
gatherInfo
Write-Host "Buffering" -foregroundcolor "green"
start-Sleep -Seconds 5
Write-Host "Completed"  
