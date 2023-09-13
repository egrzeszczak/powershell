# Lokalizacja folderów użytkowników w Windows
$UsersDirectory = "C:\Users"

# Lista ignorowanych folderów w C:\Users
$ExcludedUserFolders = @(
    "defaultuser0", 
    "Admin", 
    "Public"
    )

# Pobierz wszystkie nazwy folderów użytkowników w C:\Users 
$UserFolders = Get-ChildItem -Path $UsersDirectory | 
Where-Object {                                                  # Gdzie
    $_.PSIsContainer -and                                       # To jest folder
    $_.Name -notin $excludedUserFolders -and                    # Folder nie ma nazwy jak w liście wykluczonych
    -not ($_.Name -like "*.adm")                                # Folder nie jest od użytkownika administracyjnego *.adm
}

# Zbierz infomacje o wtyczkach z wszystkich przeglądarek
$Extensions = $UserFolders | ForEach-Object {
    # Sprawdź czy istnieje folder AppData dla Firefoxa
    $User = $_

    # 
    # Mozilla
    # 
    $UserMozillaPath = Join-Path -Path $_.FullName -ChildPath "AppData\Roaming\Mozilla\Firefox\Profiles"

    # Jeśli istnieje folder AppData dla Firefoxa
    if(Test-Path $UserMozillaPath)
    {
        # Wylistuj wszystkie profile w AppData\Roaming\Mozilla\Firefox\Profiles
        $UserMozillaProfiles = Get-ChildItem $UserMozillaPath 

        # Dla każdego wykrytego profilu
        foreach($UserMozillaProfile in $UserMozillaProfiles) {
            # Utwórz zmienną ze ścieżką do konkretnego profilu
            $UserMozillaProfilePath = Join-Path -Path $UserMozillaPath -ChildPath $UserMozillaProfile

            # Utwórz zmienną ze ścieżką do pliku extensions.json danego profilu
            $UserMozillaProfilePathExtensionsJson = Join-Path -Path $UserMozillaProfilePath -ChildPath "extensions.json"
            
            # Jeśli plik extensions.json istnieje
            if(Test-Path $UserMozillaProfilePathExtensionsJson) {
                # Pobierz zawartość tego pliku
                $UserMozillaExtensions = Get-Content -Path $UserMozillaProfilePathExtensionsJson -Raw

                # Przeparsuj zawartość z JSON do obiektu PowerShell
                $MozillaExtensions = $UserMozillaExtensions | ConvertFrom-Json

                # Pobierz wartości bez wbudowanych Mozzilowych dodatków
                $MozillaExtensions.addons | Where-Object { $_.sourceURI -ne $Null } | ForEach-Object { 
                    [PSCustomObject]@{
                        'user' = $User.Name
                        'hostname' = [Environment]::MachineName
                        'browser' = "Mozilla Firefox"
                        'name' = $_.defaultLocale.name
                        'description' = $_.defaultLocale.description
                        'active' = $_.active
                        'installDate' = (Get-Date (Get-Date "1970-01-01 00:00:00").AddMilliseconds($_.installDate)).ToUniversalTime().ToString("o")
                        'updateDate' = (Get-Date (Get-Date "1970-01-01 00:00:00").AddMilliseconds($_.updateDate)).ToUniversalTime().ToString("o")
                        'path' = $_.path
                        'sourceURI' = $_.sourceURI
                        'id' = $_.id
                        'author' = ''
                    }
                }
            } 
        }
    } 

    #
    # Edge
    #
    $UserEdgePath = Join-Path -Path $_.FullName -ChildPath "AppData\Local\Microsoft\Edge\User Data\Default\Extensions"
    
    if(Test-Path $UserEdgePath) {
        Get-ChildItem -Path $UserEdgePath | ForEach-Object {
            $UserEdgeExtensionsFolderVersionFolders = Get-ChildItem $_.FullName
            foreach($UserEdgeExtensionsFolderVersionFolder in $UserEdgeExtensionsFolderVersionFolders) {
                $UserEdgeExtensionPath = Join-Path -Path $_.FullName -ChildPath $UserEdgeExtensionsFolderVersionFolder
                $UserEdgeExtensionPath = Join-Path -Path $UserEdgeExtensionPath -ChildPath "manifest.json"
                if(Test-Path $UserEdgeExtensionPath) {
                    $manifest = Get-Content -Raw $UserEdgeExtensionPath | ConvertFrom-Json
                    [PSCustomObject]@{
                        'user' = $User.Name
                        'hostname' = [Environment]::MachineName
                        'browser' = "Microsoft Edge"
                        'name' = $manifest.name
                        'description' = $manifest.description
                        'active' = "true"
                        'installDate' = (Get-Date (Get-Date "1970-01-01 00:00:00").AddMilliseconds(0)).ToUniversalTime().ToString("o")
                        'updateDate' = (Get-Date (Get-Date "1970-01-01 00:00:00").AddMilliseconds(0)).ToUniversalTime().ToString("o")
                        'path' = $UserEdgeExtensionsFolderVersionFolder.FullName
                        'sourceURI' = ""
                        'id' = $_.Name
                        'author' = $manifest.author
                    }
                }
            }
        }
    }
}

$Extensions
