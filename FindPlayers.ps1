
#Echo arena log scraper -- DAK 20171114

#Adding the windows forms assembly so we can show the folder browser, and save menu
Add-Type -AssemblyName System.Windows.Forms

#Create a new folder browser instance
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
[void]$FolderBrowser.ShowDialog()
$LogDirectory = $FolderBrowser.SelectedPath

#get-childItem returns all files in a directory; we're only interested in the name of "*.log" files though
$Logs = Get-ChildItem -Path $LogDirectory -Filter "*.log" | Select Name -ExpandProperty "Name"; 


$NameMatch = [Regex]::new("^\[(\d{1,2})-(\d{1,2})-(\d{4})\]\s\[(\d{1,2}):(\d{1,2}):(\d{1,2})\].*?\[NETGAME\]:\s{2}Name\s+?:\s(.+)$");

<# essential regex pieces

^                                     = Beginning of a line 
\[(\d{1,2})-(\d{1,2})-(\d{4})\]       = looks for a date, enclosed in brackets, in MM-DD-YYYY format. Capture groups 1 - 3
\[(\d{1,2}):(\d{1,2}):(\d{1,2})\]     = looks for a time, enclosed in brackets, in HH:MM:SS format. Capture groups 4 - 6
\[NETGAME\]:\s{2}                     = looks for the string "[NETGAME]" followed by a colon ":" and two spaces "\s{2}"
Name\s+?:                             = looks for the string "Name" followed by any number of spaces \s+? then a colon ":"
\s(.+)                                = looks for one space "\s", then captures every character after "(.+)" (Capture group 7)
$                                     = End of the line

#>

#Create Table object
$tableName = "Players"
$table = New-Object system.Data.DataTable “$tableName”

#Define Columns
$dateCol = New-Object system.Data.DataColumn DateConnected,([datetime])
$nameCol = New-Object system.Data.DataColumn PlayerName,([string])

#Add the Columns
$table.columns.add($dateCol)
$table.columns.add($nameCol)


$logIndex = 1; #Let's keep track while enumerating through the list of logs

Foreach ($log in $Logs)
{
    #write what we're doing to the standard output
    Write-Output "";
    Write-Output "Scanning $Log";

    #log filenames have abnormal chars in them, so we're using -LiteralPath instead of Path
    $LogContents = get-content -LiteralPath "$LogDirectory\$log";

    #Also keep track of where we are within each log file
    $lineIndex = 0; 

    #Build Status and percentage for the progress bar
    $Status = "Scanning Log " + ($logIndex) + " of " + ($Logs.Count)
    $PercentComplete = ($logIndex / $Logs.count*100)

    #Show progress bar
    Write-Progress -Activity "Scanning Logs" -status $Status -percentComplete $PercentComplete

    foreach ($line in $LogContents)
    {
        
        if ($NameMatch.IsMatch($line) -and $LogContents[$lineIndex-1] -notlike "*disconnected*")
        {
            #Create a usable datetime object from our regex match groups 1-6
            $dateTimeString = $line -replace $NameMatch,"`$1/`$2/`$3 `$4:`$5:`$6"
            $date = [DateTime]$dateTimeString

            #Get our player name from regex match group 7
            $name = $line -replace $NameMatch,"`$7" 

            #Add that information into a new row, then add that row to our table
            $row = $table.NewRow()
            $row.DateConnected = $date
            $row.PlayerName = $name
            $table.Rows.Add($row)
            

        }
        $lineIndex ++;
    }
    $logIndex ++;
}

#If there are entries in our table, save them
if ($table.Rows.Count -gt 0) 
{
 
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.initialDirectory = $PSScriptRoot
    $SaveFileDialog.filter = "CSV files (*.csv)| *.csv"
    $SaveFileDialog.AddExtension = $true
    $SaveFileDialog.DefaultExt = "csv"
    $SaveFileDialog.filename = "PlayerNames.csv"
    if ($SaveFileDialog.ShowDialog() -ne "Cancel") 
    {
        Write-Output ("Saving output to : " + $SaveFileDialog.filename)
        $table | Export-Csv -Path $SaveFileDialog.filename -NoTypeInformation
        Write-Output "Save complete. Closing"
    }
    else 
    {
        Write-Output "Save cancelled. Closing"
    }
}