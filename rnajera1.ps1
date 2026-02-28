Write-Host "Hello Roman, welcome back" -foregroundcolor DarkMagenta

Set-Alias -Name c -Value clear



function sftp {
    param([string]$Store)

    $target = "11299627@azroot@s${Store}.autozone.com@cyberark-ssh.autozone.com"

    & "C:\Windows\System32\OpenSSH\sftp.exe" $target
}

function sshkey {
    param([string]$Store)

    $target = "11299627@azroot@s${Store}.autozone.com@cyberark-ssh.autozone.com"

    & "C:\Windows\System32\OpenSSH\ssh.exe" $target
}

function kerrclean1 {
    #Exports textfile with store numbers we want to access.
    $Stores =  Get-Content "C:\Users\rnajera1\Downloads\storesoutput.txt"
    #Creates ssh connection to store in array order by inserting the 5 digit store number into the hostname.
    $Stores | ForEach-Object {

        $Target = "11299627@azroot@s$_.autozone.com@cyberark-ssh.autozone.com"
        & "C:\Windows\System32\OpenSSH\ssh.exe" $Target

    }

}


function kerrclean {
    $ssh = "C:\Windows\System32\OpenSSH\ssh.exe"
    $storeFile = "C:\Users\rnajera1\Downloads\storesoutput.txt"
    $stores = Get-Content $storeFile
    $logRoot = "C:\Temp\store-ssh-logs"
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
            # Put the commands you want to run on each store here:
    $remoteCmd = @(
        "e"
        "4"
        "rnajera"
        "service zbus status"
        "exit"
    ) -Join ";"


    foreach ($s in $stores) {
        $target = "11299627@azroot@s$s.autozone.com@cyberark-ssh.autozone.com"
        $log = Join-Path $logRoot "$s.log"

        Write-Host "`n=== Store $s ==="

        # -tt forces a TTY (helps when MFA/prompting systems expect an interactive terminal)
        # timeouts prevent hanging forever; logs capture everything for review
        & $ssh -tt `
            -o ConnectTimeout=15 `
            -o ServerAliveInterval=10 `
            -o ServerAliveCountMax=2 `
            -o StrictHostKeyChecking=accept-new `
            $target Start-Sleep -Seconds 3 $remoteCmd 2>&1 | Tee-Object -FilePath $log
    }
}

<#
This function extracts a specific row/record off of a .csv file (obtained from SMAX),
in this case "RequestedForPerson.Name" which corresponds to the store, sorts them, removes
any duplicate entries, and outputs a .txt file with the result#>


function lstpls {
    #Path to the file
    $FileName = Read-Host -Prompt "Please input the .csv filename (must exist within C:\Users\rnajera1\Downloads)"
    $Path = "C:\Users\rnajera1\Downloads\${FileName}.csv"
    #Imports the file, stablishes the delimiter and stores said information onto the $Rows variable
    $Rows = Import-Csv -Path $Path -Delimiter ","
    #If there's nothing in $Rows, it'll return the line which includes the issue and an error message.
        if (-not $Rows) { return @(Write-Host 'Cannot list an empty file') }

    # Confirms if the header exists inside the variable $Rows, if it doesn't it then lists the headers that do exist separated by "|"
    #It includes the index style for csv, and gathers the properties of the object that created off of the Import-Csv, specifically the name.
    $Headers = $Rows[0].PSObject.Properties.Name
        if ($Headers -notcontains 'RequestedForPerson.Name') {
        throw "Header 'RequestedForPerson.Name' was not found. Headers present: $($Headers -join '|')"
        }
    # Extracts the values off of the "RequestedForPerson.Name" header (If there's a dot in the header => we must quote it)
    # The $_ variable means "Current row"
    $Rows | ForEach-Object {
        $Value = $_.'RequestedForPerson.Name'
        if ($Value -and $Value.Length -ge 15) {
        $Value.Substring(10, 5)
        }
    } | Sort-Object -Unique | Set-Content -Path "C:\Users\rnajera1\Downloads\storesoutput.txt"

    Write-Host "File has been sorted and saved (C:\Users\rnajera1\Downloads\storesoutput.txt)"

}




