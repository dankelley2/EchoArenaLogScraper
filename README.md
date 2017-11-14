# Echo Arena Log Scraper
Short powershell script to scrape through logs and output a CSV file of player names and connection dates.


You can start the powershell script by double-clicking the FindPlayers.cmd file.
This file exists only to start a \**.ps1* file that with the same name.

After you navigate to your log folder and click "OK", the script will loop through all log files and pull in every time a player (or yourself) connected to a game or the lobby. I've left out disconnects to reduce duplicates. You may add them back in by removing the **"-and $LogContents\[\$lineIndex-1\] -notlike \"\*disconnected\*\"** condition in FindPlayers.ps1

After a short while you will be prompted to save the CSV with your playerdata in it.

Let me know if there are additional dimensions of the log file you'd like pulled into this.
