function Test-PSVersion
{
    if ($PSVersionTable.PSVersion.Major -gt 5)
    {
        throw [System.NotSupportedException]::new('PowerShell Core is not supported yet.')
    }
}

function Get-GoogleImageSearchUrl
{
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path "$($_.FullName)" })]
        [System.IO.FileInfo]
        $ImagePath
    )

    # Extract the image file name, without Path.
    $fileName = Split-Path $imagePath -Leaf
    Write-Verbose -Message "The image name for search: $fileName"

    # The request body has some boilerplate before the raw image bytes (part1) and some after (part2)
    #   note that $filename is included in part1
    $part1 = @"
-----------------------------7dd2db3297c2202
Content-Disposition: form-data; name="encoded_image"; filename="$fileName"
Content-Type: image/jpeg


"@
    $part2 = @'
-----------------------------7dd2db3297c2202
Content-Disposition: form-data; name="image_content"


-----------------------------7dd2db3297c2202--

'@

    # grab the raw bytes composing the image file
    $imageBytes = [Io.File]::ReadAllBytes($imagePath.FullName)

    # the request body should sandwich the image bytes between the 2 boilerplate blocks
    $encoding = New-Object Text.ASCIIEncoding
    $data = $encoding.GetBytes($part1) + $imageBytes + $encoding.GetBytes($part2)

    # create the HTTP request, populate headers
    $request = [Net.HttpWebRequest] ([Net.HttpWebRequest]::Create('http://images.google.com/searchbyimage/upload'))
    $request.Method = 'POST'
    $request.ContentType = 'multipart/form-data; boundary=---------------------------7dd2db3297c2202'  # must match the delimiter in the body, above
    $request.ContentLength = $data.Length

    # don't automatically redirect to the results page, just take the response which points to it
    $request.AllowAutoredirect = $false

    # populate the request body
    $response = $request.GetResponse()
    if ($response.StatusCode -eq 302) {
        $redirectUrl = $response.Headers["Location"]
        Write-Information -Message "Redirection to: $redirectUrl"
        return $redirectUrl
    }
    throw [System.InvalidOperationException]::new('The Google image search engine has not provided a redirect URL for your image')
}

function Get-Image
{
    begin
    {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Write-Verbose
    }
    process
    {
        $file = $_
        [Drawing.Image]::FromFile($_.FullName) |
        ForEach-Object {
            $_ |
            Add-Member -NotePropertyMembers @{FullName = $file.FullName; Name = $file.Name } -PassThru
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
      Specifies a Path to a folder where the wallpapers should be dumped. The input can be a string or a valid instance of the System.IO.FileInfo class. A default value is 'C:\Temp'. The input directory is created if doesn't exist.

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
      - A dump Path is created if it doesn't exist.

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
    Where-Object { (Get-KnownFileHeader -Path $_.FullName) -eq 'jpg' }
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
      Specifies a Path to a image file. The input can be a string or a valid instance of the System.IO.FileInfo class.

      .EXAMPLE
      Search-Image -ImagePath C:\Pictures\SomeImageToSearch.jpg
      Reads the image SomeImageToSearch.jpg in C:\Pictures Path and use this image to query Google Image Search.

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
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path "$($_.FullName)" })]
        [System.IO.FileInfo]
        $ImagePath
    )
    process
    {
        Start-Process -FilePath (Get-GoogleImageSearchUrl -ImagePath $ImagePath.FullName)
    }
}

function Get-KnownFileHeader
{
    [OutputType([String])]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ })]
        [System.IO.FileInfo]
        $Path
    )
    Begin
    {
        # Hexadecimal signatures for expected files
        $known = @'
"Extension","Header"
"3gp","66 74 79 70 33 67"
"7z","37 7A BC AF 27 1C"
"8sv","38 53 56 58"
"8svx","46 4F 52 4D nn nn nn nn"
"acbm","46 4F 52 4D nn nn nn nn"
"aif","41 49 46 46"
"aiff","46 4F 52 4D nn nn nn nn"
"anbm","46 4F 52 4D nn nn nn nn"
"anim","46 4F 52 4D nn nn nn nn "
"asf","30 26 B2 75 8E 66 CF 11"
"avi","52 49 46 46 nn nn nn nn "
"bac","42 41 43 4B 4D 49 4B 45"
"bpg","42 50 47 FB"
"cab","4D 53 43 46"
"cin","80 2A 5F D7"
"class","CA FE BA BE"
"cmus","46 4F 52 4D nn nn nn nn"
"cr2","49 49 2A 00 10 00 00 00"
"crx","43 72 32 34"
"cwk","05 07 00 00 42 4F 42 4F"
"cwk","06 07 E1 00 42 4F 42 4F"
"dat","50 4D 4F 43 43 4D 4F 43"
"DBA","BE BA FE CA"
"DBA","00 01 42 44"
"dex","64 65 78 0A 30 33 35 00"
"djvu","41 54 26 54 46 4F 52 4D nn nn nn nn 44 4A 56"
"dmg","78 01 73 0D 62 62 60"
"doc","D0 CF 11 E0 A1 B1 1A E1"
"dpx","53 44 50 58"
"exr","76 2F 31 01"
"fax","46 41 58 58"
"faxx","46 4F 52 4D nn nn nn nn"
"fh8","41 47 44 33"
"fits","53 49 4D 50 4C 45 20 20"
"flac","66 4C 61 43"
"flif","46 4C 49 46"
"ftxt","46 4F 52 4D nn nn nn nn"
"gif","47 49 46 38 37 61"
"ico","00 00 01 00"
"idx","49 4E 44 58"
"iff","41 43 42 4D"
"iff","41 4E 42 4D"
"iff","41 4E 49 4D"
"iff","46 4F 52 4D nn nn nn nn"
"ilbm","46 4F 52 4D nn nn nn nn"
"iso","43 44 30 30 31"
"jpg","FF D8 FF DB"
"jpg","FF D8 FF E0"
"lbm","49 4C 42 4D"
"lz","4C 5A 49 50"
"lz4","04 22 4D 18"
"mid","4D 54 68 64"
"mkv","1A 45 DF A3"
"MLV","4D 4C 56 49"
"mus","43 4D 55 53"
"nes","4E 45 53 1A"
"ods","50 4B 05 06"
"ogg","4F 67 67 53"
"PDB","00 00 00 00 00 00 00 00"
"pdf","25 50 44 46"
"png","89 50 4E 47 0D 0A 1A 0A"
"ps","25 21 50 53"
"psd","38 42 50 53"
"rar","52 61 72 21 1A 07 00"
"rar","52 61 72 21 1A 07 01 00"
"smu","53 4D 55 53"
"smus","46 4F 52 4D nn nn nn nn"
"stg","4D 49 4C 20"
"tar","75 73 74 61 72 00 30 30"
"TDA","00 01 44 54"
"tif","49 49 2A 00"
"toast","45 52 02 00 00 00"
"tox","74 6F 78 33"
"txt","46 54 58 54"
"vsdx","50 4B 07 08"
"wav","52 49 46 46 nn nn nn nn"
"wma","A6 D9 00 AA 00 62 CE 6C"
"xar","78 61 72 21"
"yuv","59 55 56 4E"
"yuvn","46 4F 52 4D nn nn nn nn"
"zip","50 4B 03 04"
"epub","50 4B 03 04 0A 00 02 00"
'@ | ConvertFrom-Csv | Sort-Object { $_.header.Length } -Descending

        $known | ForEach-Object { $_.header = $_.header -replace '\s' }
    }
    Process
    {
        $HeaderAsHexString = New-Object System.Text.StringBuilder
        if ($PSVersionTable.PSVersion.Major -gt 5)
        {
            $bytes = [Byte[]](Get-Content -Path $Path.FullName -TotalCount 4 -AsByteStream -ErrorAction:Continue)
        }
        else
        {
            $bytes = [Byte[]](Get-Content -Path $Path.FullName -TotalCount 4 -Encoding:Byte -ErrorAction:Continue)
        }
        $bytes |
        ForEach-Object `
        {
            if (('{0:X}' -f $_).Length -eq 1)
            {
                $HeaderAsHexString.Append('0{0:X}' -f $_) | Write-Verbose
            }
            else
            {
                $HeaderAsHexString.Append('{0:X}' -f $_) | Write-Verbose
            }
        }

        $known | Where-Object { $_.Header.StartsWith($HeaderAsHexString.ToString()) } | Select-Object -First 1 | ForEach-Object { $_.Extension }
    }
}

Search-Image 'D:\Test 1 žřčš\IMG-20221228-WA0006.jpg' -Verbose -InformationAction:Continue