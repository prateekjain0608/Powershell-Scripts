<#
   Was originally created to have uniform time differences for projects done over days.
   This was used for Photogrammetry.
   The photos can be inside multiple folders with names - M1, M2, M3,...
   Script will continuously rename the pictures, sorted by the name.
   The first image's time will be used as start time and thereafter an "offset" will be given.
   It only processes the images in JPG format.
#>

# ENTER these two parameters here only.
[TimeSpan]$Offset = New-TimeSpan -Seconds "5"
$ProjectPath = "<project path which contains the folders M1, M2 and so on>" 

<#
Use this commented part for simple numerical numbering of folders. If using M1, M2.... style then use the below part only.
#Get the Folders.
$MissionNames= (Get-ChildItem -Path $ProjectPath | where{$_.Attributes -eq "Directory"} | Sort-Object Name).Name
#>

# COMPLICATION STARTS HERE. MAKE FOLDERS ON BY THE NAME.. M1 M2 M3 M4.....
# Complication is there since powershell dows not sort out the folders by name properly.
# Get the Folders.
$tempMissionNames= (Get-ChildItem -Path $ProjectPath | where{$_.Attributes -eq "Directory"} | Sort-Object Name).Name

# Remove 'M' from the Folder Names.
$tempMissionString = $tempMissionNames | ForEach-Object {$_.Split("M")[1]}
[int]$temp=0

# Convert from object type to a number ARRAY.
foreach($temp in $tempMissionString)
{
    if($tempMissionNumbers.length -eq 0)
    {
        $tempMissionNumbers = @([int]$temp)
    }
    else
    {
        $tempMissionNumbers+=[int]$temp
    }
}
# Sort the NUMBER array and then ADD 'M' to each name.
$MissionNames = $tempMissionNumbers | Sort-Object| ForEach-Object {"M" + $_}
# Remove this ARRAY to avoid problem when running the script again in the same session.
Remove-Variable -Name tempMissionNumbers
# COMPLICATION ENDS HERE.

# Check how many folders are present in the given folder.
Write-Host "Total number of" $MissionNames.Length "Missions."  
$isFirstImage=$true
$totalImageCount=0

# Now we start editing the EXIF data of the images.
foreach($currentMissionName in $MissionNames)
{    
    $MissionPath = Join-Path -Path $ProjectPath -ChildPath $currentMissionName

    $ImageNameList = (Get-ChildItem -Path $MissionPath | Sort-Object Name | where{$_.Extension -eq ".JPG"}).Name
    $totalImageCount+= $ImageNameList.Length
    [int]$a=0
    Write-Host "Working on mission $currentMissionName."

    foreach($currentImage in $ImageNameList)
    {
        # Read the current file and extract the Exif DateTaken property

        $ImageFile= Join-Path -path $MissionPath -ChildPath $currentImage

        Try {
            $FileStream=New-Object System.IO.FileStream($ImageFile,
                                                        [System.IO.FileMode]::Open,
                                                        [System.IO.FileAccess]::Read,
                                                        [System.IO.FileShare]::Read,
                                                        1024,     # Buffer size
                                                        [System.IO.FileOptions]::SequentialScan
                                                        )
            $Img=[System.Drawing.Imaging.Metafile]::FromStream($FileStream)
            $ExifDT=$Img.GetPropertyItem('36867')
        }
        Catch{
            Write-Warning "Check $ImageFile is a valid image file ($_)"
            If ($Img) {$Img.Dispose()}
            If ($FileStream) {$FileStream0.Close()}
            Break
        }    
        $ExifDtString=[System.Text.Encoding]::ASCII.GetString($ExifDT.Value)

        # Check if this is the first image, if true then use that time.
        # Else add OFFSET to the old time.
        if( $isFirstImage -eq $true )
        {            
            $OldTime=[datetime]::ParseExact($ExifDtString,"yyyy:MM:dd HH:mm:ss`0",$Null)
            Write-host "Starting Image ($currentImage) time - $OldTime in Mission $currentMissionName"  -ForegroundColor Cyan
            $NewTime=$OldTime        
            $isFirstImage=$false   
        }  
        else
        {
            # Convert the time by adding the offset
            $NewTime=$OldTime.Add($Offset)
            $OldTime=$NewTime
        }

        # Convert to a string, changing slashes back to colons in the date.  Include trailing 0x00...
        $ExifTime=$NewTime.ToString("yyyy:MM:dd HH:mm:ss`0")        

        # Overwrite the EXIF DateTime property in the image and set
        $ExifDT.Value=[Byte[]][System.Text.Encoding]::ASCII.GetBytes($ExifTime)
        $Img.SetPropertyItem($ExifDT)

        # Create a memory stream to save the modified image...
        $MemoryStream=New-Object System.IO.MemoryStream

        Try {
            # Save to the memory stream then close the original objects
            # Save as type $Img.RawFormat  (Usually [System.Drawing.Imaging.ImageFormat]::JPEG)
            $Img.Save($MemoryStream, $Img.RawFormat)
        }
        Catch {
            Write-Warning "Problem modifying image $ImageFile ($_)"
            $MemoryStream.Close(); $MemoryStream.Dispose()
            Break
        }
        Finally {        
            $Img.Dispose()
            $FileStream.Close()
        }

        # Update the file (Open with Create mode will truncate the file)
        Try {
            $Writer = New-Object System.IO.FileStream($ImageFile, [System.IO.FileMode]::Create)
            $MemoryStream.WriteTo($Writer)
        }
        Catch {
            Write-Warning "Problem saving to $OutFile ($_)"
            Break
        }
        Finally {
            If ($Writer) {$Writer.Flush(); $Writer.Close()}
            $MemoryStream.Close(); $MemoryStream.Dispose()
        }
    } # End Foreach Path for images
    Write-Host "Total Number of" $ImageNameList.Length "Images in mission $currentMissionName successfully modified."    
    Write-Host " "
}

Write-host "Ending Image ($currentImage) time - $NewTime in Mission $currentMissionName" -ForegroundColor Cyan
Write-Host " "
Write-Host "In total $totalImageCount images modified." -ForegroundColor Yellow


