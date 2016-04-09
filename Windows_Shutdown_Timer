# A very simple timer for shutting down windows!
# Please run the script as administrator.

Write-Host "MAKE SURE YOU'VE SAVED ALL YOUR WORK!" -ForegroundColor Cyan

# Loop to make sure user enters a number.
do
{
    $time = (Read-Host -Prompt "Enter minute(s) to shutdown: " )    
}while(($time.Length -ile 0) -or !($time -as [int]))

Write-Host "Computer will shutdown in $time Minutes. Press ENTER to continue." -ForegroundColor Red
if((Read-Host).Length -ine 0)
{ break; }

# Loop iteration is 100, so we divide the milliseconds by 100. For the progress bar.
$timePerLoopInMS= [int]$time*60*1000/100

for ($i = 1; $i -le 100; $i++ )
{
    $TimeToShutdown = (([int]$time*60) - ($timePerLoopInMS*$i/1000))
    write-progress -activity "Shutdown Timer Running" -percentcomplete $i -SecondsRemaining $TimeToShutdown 
    Start-Sleep -Milliseconds $timePerLoopInMS
}

Write-Host "SHUTTING DOWN COMPUTER!" -ForegroundColor Red
Stop-Computer -Force
