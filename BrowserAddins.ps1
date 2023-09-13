# Rozpocznij skrypt, wyświetl datę i czas rozpoczęcia
Get-Date -Format o

# Lokalizacja folderów użytkowników w Windows
$UserDirectory = "C:\Users"

# Lista ignorowanych folderów w C:\Users
$ExcludedUserFolders = @("defaultuser0", "Admin", "Public")

# Pobierz wszystkie nazwy folderów użytkowników w C:\Users 
$UserFolders = Get-ChildItem -Path $UserDirectory | 
    Where-Object {                                                  # Gdzie
        $_.PSIsContainer -and                                       # To jest folder
        $_.Name -notin $excludedUserFolders -and                    # Folder nie ma nazwy jak w liście wykluczonych
        -not ($_.Name -like "*.adm")                                # Folder nie jest od użytkownika administracyjnego *.adm
    }

# Przejdz przez każdy wykryty folder
foreach ($UserFolder in $UserFolders) {
    # Sprawdź czy istnieje folder AppData dla Firefoxa
    $UserMozillaPath = Join-Path -Path $UserFolder.FullName -ChildPath "AppData\Roaming\Mozilla\Firefox\Profiles"

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
                $Extensions = $MozillaExtensions.addons | Where-Object { $_.sourceURI -ne $Null } | ForEach-Object { 
                    [PSCustomObject]@{
                        'user' = $UserFolder.Name
                        'hostname' = [Environment]::MachineName
                        'name' = $_.defaultLocale.name
                        'description' = $_.defaultLocale.description
                        'active' = $_.active
                        'installDate' = (Get-Date (Get-Date "1970-01-01 00:00:00").AddMilliseconds($_.installDate)).ToUniversalTime().ToString("o")
                        'updateDate' = (Get-Date (Get-Date "1970-01-01 00:00:00").AddMilliseconds($_.updateDate)).ToUniversalTime().ToString("o")
                        'path' = $_.path
                        'sourceURI' = $_.sourceURI
                        'id' = $_.id
                    }
                }

                # Wyświetl wtyczki
                $Extensions | Format-Table
                
                # Zaznacz datę eksportu
                $ExportDate = Get-Date -Format "yyyy-MM-dd-HH.mm.ss"

                # Zdefiniuj nazwę pliku
                $CSVFileName = "BrowserAddins-$ExportDate.csv"

                # Wyeksportuj do pliku CSV
                $Extensions | Export-Csv -Path $CSVFileName -NoTypeInformation
            } 
        }
    } 
}
