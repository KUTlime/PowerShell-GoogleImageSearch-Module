# PowerShell GoogleImageSearch Module
A PowerShell module to handle Google Image Search

# Introduction
This module enables users to search Windows lock screen wallpaper images or any another image in Google Search Image. This module works only in **Windows PowerShell**.

# Main feature
- User can search any image in Google Image Search from PowerShell.
- User can easily search Windows lockscreen images in Google Image Search from PowerShell.

# Installation 
Run PowerShell as administrator and type:
```powershell
Install-Module -Name GoogleImageSearch
```
and import module into workspace by typing:
```powershell
Import-Module -Name GoogleImageSearch
```

# Basic use

```powershell
Search-Image -ImagePath C:\Pictures\SomeImageToSearch.jpg
```
Reads the image SomeImageToSearch.jpg in C:\Pictures path and use this image to query Google Image Search.

```powershell
Get-ChildItem -Path 'C:\Pictures' -Filter '*.jpg' | Search-Image
```
Reads all images in C:\Pictures and pipes them into Search-Image where are used to query Google Image Search.
      
```powershell
Search-WindowsLockScreenWallpapers
```
Search of the five latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser.

```powershell
Search-WindowsLockScreenWallpapers -DumpFiles
```
Search of the five latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser. The wallpaper images will be dumped into C:\Temp directory.

```powershell
Search-WindowsLockScreenWallpapers -DumpFiles -DumpPath D:\Temp
```
Search of the five latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser. The wallpaper images will be dumped into custom D:\Temp directory. The input directory is created if doesn't exist.

```powershell
Search-WindowsLockScreenWallpapers -NumberOfImages 2 -DumpFiles -DumpPath D:\Temp
```
Search of the two latest downloaded wallpaper images in Google Image Search. It will open five or less tabs in the default web browser. The wallpaper images will be dumped into custom D:\Temp directory. The input directory is created if doesn't exist.

# Links
[GoogleSearchModule at PowerShell Gallery](https://www.powershellgallery.com/packages/GoogleImageSearch/1.0.0.0)<br>
[Script to use Google Image Search with local image as input](https://stackoverflow.com/questions/14634321/script-to-use-google-image-search-with-local-image-as-input)<br>
[Get list of image files with specific dimensions as file objects using PowerShell](https://stackoverflow.com/questions/13741668/get-list-of-image-files-with-specific-dimensions-as-file-objects-using-powershel)<br>
