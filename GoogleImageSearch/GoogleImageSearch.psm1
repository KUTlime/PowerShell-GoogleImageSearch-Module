function Get-GoogleImageSearchUrl
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ })]
        [System.IO.FileInfo]
        $ImagePath
    )

    # Extract the image file name, without path.
    $fileName = Split-Path $imagePath -Leaf
    Write-Verbose -Message "The image name for search: $fileName"

    # The request body has some boilerplate before the raw image bytes (part1) and some after (part2)
    #   note that $filename is included in part1
    $part1 = @"
-----------------------------7dd2db3297c2202
Content-Disposition: form-data; name="encoded_image"; filename="$fileName"
Content-Type: image/jpeg


"@
    $part2 = @"
-----------------------------7dd2db3297c2202
Content-Disposition: form-data; name="image_content"


-----------------------------7dd2db3297c2202--

"@

    # grab the raw bytes composing the image file
    $imageBytes = [Io.File]::ReadAllBytes($imagePath.FullName)

    # the request body should sandwich the image bytes between the 2 boilerplate blocks
    $encoding = New-Object Text.ASCIIEncoding
    $data = $encoding.GetBytes($part1) + $imageBytes + $encoding.GetBytes($part2)

    # create the HTTP request, populate headers
    $request = [Net.HttpWebRequest] ([Net.HttpWebRequest]::Create('http://images.google.com/searchbyimage/upload'))
    $request.Method = "POST"
    $request.ContentType = 'multipart/form-data; boundary=---------------------------7dd2db3297c2202'  # must match the delimiter in the body, above
    $request.ContentLength = $data.Length

    # don't automatically redirect to the results page, just take the response which points to it
    $request.AllowAutoredirect = $false

    # populate the request body
    $stream = $request.GetRequestStream()
    $stream.Write($data, 0, $data.Length)
    $stream.Close()

    # get response stream, which should contain a 302 redirect to the results page
    $respStream = $request.GetResponse().GetResponseStream()

    # pluck out the results page link that you would otherwise be redirected to
    (New-Object Io.StreamReader $respStream).ReadToEnd() -match 'HREF\="([^"]+)"' | Write-Verbose
    $matches[1]
}

function Get-Image
{
    begin
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Write-Verbose
    }
    process
    {
        $file = $_
        [Drawing.Image]::FromFile($_.FullName) |
        ForEach-Object {
            $_ |
            Add-Member -PassThru NoteProperty FullName ('{0}' -f $file.FullName)
        }
    }
}

function Search-WindowsLockScreenWallpapers
{
    <#
      .SYNOPSIS
      Uses Windows lock screen wallpapers to query Google Image Search.

      .DESCRIPTION
      The Search-WindowsLockScreenWallpapers cmdlet reads the Windows lock screen wallpapers and uses them to query Google Image Search. This cmdlet can be piped to the Get-ChildItem cmdlet for a batch processing.

      .PARAMETER NumberOfImages
      Specifies a number of the latest wallpaper that will be search. The input must be a valid positive number. A default value is 5.

      .PARAMETER DumpFiles
      Specifies a switch if wallpaper images should be dumped or not. A default value is False.

      .PARAMETER DumpPath
      Specifies a path to a folder where the wallpapers should be dumped. The input can be a string or a valid instance of the System.IO.FileInfo class. A default value is 'C:\Temp'. The input directory is created if doesn't exist.

      .EXAMPLE
      Search-WindowsLockScreenWallpapers
      Search of the five latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser.

      .EXAMPLE
      Search-WindowsLockScreenWallpapers -DumpFiles
      Search of the five latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser. The wallpaper images will be dumped into C:\Temp directory.

      .EXAMPLE
      Search-WindowsLockScreenWallpapers -DumpFiles -DumpPath D:\Temp
      Search of the five latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser. The wallpaper images will be dumped into custom D:\Temp directory. The input directory is created if doesn't exist.

      .EXAMPLE
      Search-WindowsLockScreenWallpapers -NumberOfImages 2 -DumpFiles -DumpPath D:\Temp
      Search of the two latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser. The wallpaper images will be dumped into custom D:\Temp directory. The input directory is created if doesn't exist.

      .NOTES
      - This cmdlet uses non-standard way how to query Google Image Search. Do not use it for automatization.
      - A dump path is created if it doesn't exist.

      .LINK
      https://github.com/KUTlime/PowerShell-GoogleImageSearch-Module

      .INPUTS
      System.String
      System.IO.FileInfo

      .OUTPUTS
      A system query to the default web browser with the lock screen wallpaper image.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [UInt16]
        $NumberOfImages = 5,
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch]
        $DumpFiles = $false,
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ })]
        [IO.FileInfo]
        $DumpPath = 'C:\Temp'
    )
    ####################################################
    # Create a temp folder
    ####################################################
    if ((Test-Path $DumpPath) -eq $false -and $DumpFiles -ne $null)
    {
        New-Item -Path $DumpPath -ItemType Directory | Write-Verbose
    }
    ####################################################


    ####################################################
    # Select Images
    ####################################################
    $Images = Get-ChildItem -Path $env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets -ErrorAction Continue |
    Where-Object { $_.Length / 1KB -gt 200 }
    $Images = $Images | Get-Image | Where-Object { $_.Width -gt $_.Height } | Sort-Object { $_.CreationTimeUtc } -Descending | Select-Object -First $NumberOfImages
    ####################################################


    ####################################################
    # Do some action
    ####################################################
    if ($DumpFiles)
    {
        Write-Verbose -Message "Dumping $($Images.Length) into $DumpPath"
        $Images | ForEach-Object { Copy-Item $_.FullName -Destination ("$DumpPath\$($_.Name).jpg") -ErrorAction Continue }
    }
    $Images | ForEach-Object { Search-Image -ImagePath $_.FullName }
    ####################################################
}

function Search-Image
{
    <#
      .SYNOPSIS
      Uses an input image to query Google Image Search.

      .DESCRIPTION
      The Search-Image cmdlet reads the image and use this image to query Google Image Search. This cmdlet can be piped to the Get-ChildItem cmdlet for a batch processing.

      .PARAMETER ImagePath
      Specifies a path to a image file. The input can be a string or a valid instance of the System.IO.FileInfo class.

      .EXAMPLE
      Search-Image -ImagePath C:\Pictures\SomeImageToSearch.jpg
      Reads the image SomeImageToSearch.jpg in C:\Pictures path and use this image to query Google Image Search.

      .EXAMPLE
      Get-ChildItem -Path 'C:\Pictures' -Filter '*.jpg' | Search-Image
      Reads all images in C:\Pictures and pipes them into Search-Image where are used to query Google Image Search.

      .NOTES
      - This cmdlet uses non-standard way how to query Google Image Search. Do not use it for automatization.

      .LINK
      https://github.com/KUTlime/PowerShell-GoogleImageSearch-Module

      .INPUTS
      System.String
      System.IO.FileInfo

      .OUTPUTS
      A system query to the default web browser with the input image.
  #>
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ })]
        [System.IO.FileInfo]
        $ImagePath
    )
    Start-Process -FilePath (Get-GoogleImageSearchUrl -ImagePath $ImagePath.FullName)
}