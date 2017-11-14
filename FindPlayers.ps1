
#Echo arena log scraper -- DAK 20171114

Add-Type -AssemblyName System.Windows.Forms
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
[void]$FolderBrowser.ShowDialog()
$LogDirectory = $FolderBrowser.SelectedPath

$LogDirectory = "$PSScriptRoot\LOGS";
$Logs = gci -Path $LogDirectory -Filter "*.log" | Select Name -ExpandProperty "Name";
$NameMatch = [Regex]::new("^\[(\d{1,2})-(\d{1,2})-(\d{4})\]\s\[(\d{1,2}):(\d{1,2}):(\d{1,2})\].*?\[NETGAME\]:\s{2}Name\s+?:\s(.+)$");


#Create Table object
$tableName = "Players"
$table = New-Object system.Data.DataTable “$tableName”

#Define Columns
$dateCol = New-Object system.Data.DataColumn DateConnected,([datetime])
$nameCol = New-Object system.Data.DataColumn PlayerName,([string])

#Add the Columns
$table.columns.add($dateCol)
$table.columns.add($nameCol)



Foreach ($log in $Logs)
{
    Write-Output "";
    Write-Output "Scanning $Log";
    $LogContents = get-content -LiteralPath "$LogDirectory\$log";

    $lineIndex = 0; #keep track of where we are numerically just in case we need to use this

    foreach ($line in $LogContents)
    {
        
        if ($NameMatch.IsMatch($line) -and $LogContents[$lineIndex-1] -notlike "*disconnected*")
        {
            
            $day = $line -replace $NameMatch,"`$1"
            $month = $line -replace $NameMatch,"`$2"
            $year = $line -replace $NameMatch,"`$3"
            $HH = $line -replace $NameMatch,"`$4"
            $MM = $line -replace $NameMatch,"`$5"
            $SS = $line -replace $NameMatch,"`$6"

            $date = [DateTime]"$day/$month/$year $HH`:$MM`:$SS"
            $name = $line -replace $NameMatch,"`$7"

            $row = $table.NewRow()
            $row.DateConnected = $date
            $row.PlayerName = $name
            $table.Rows.Add($row)
            

        }
        $lineIndex ++;
    }

}

if ($table.Rows.Count -gt 0) 
{
 
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.initialDirectory = $PSScriptRoot
    $SaveFileDialog.filter = "CSV files (*.csv)| *.csv"
    $SaveFileDialog.AddExtension = $true
    $SaveFileDialog.DefaultExt = "csv"
    $SaveFileDialog.filename = "PlayerNames.csv"
    $SaveFileDialog.ShowDialog() |  Out-Null
    
    $table | Export-Csv -Path $SaveFileDialog.filename -NoTypeInformation 
}